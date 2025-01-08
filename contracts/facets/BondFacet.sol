// SPDX-License-Identifier: FSL-1.1-MIT
pragma solidity ^0.8.24;

import { ERC1155Facet } from "./ERC1155Facet.sol";
import "@prb/math/src/UD60x18.sol";
import { BokkyPooBahsDateTimeLibrary } from "../libraries/BokkyPooBahsDateTimeLibrary.sol";
import { BondInitParams } from "../libraries/StructBondInit.sol";
import { BondStorage } from "./BondStorage.sol";
import { OwnershipFacet } from "./OwnershipFacet.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondFacet is BondStorage, OwnershipFacet, IERC1155Receiver, ERC165 {
    address private __bond;
    address private __currencyAddress;

    // Events
    event BondInitializedPart1(
        uint256 bondId,
        uint256 coupure,
        uint256 interestNum,
        uint256 interestDen,
        uint256 withholdingTaxNum,
        uint256 withholdingTaxDen,
        address issuer
    );

    event BondInitializedPart2(
        uint256 bondId,
        uint256 periodicInterestRate,
        uint256 netReturn,
        uint256 periodicity,
        uint256 duration,
        uint256 methodOfRepayment,
        uint256 maxSupply,
        uint256 formOfFinancing
    );

    event MinAndMaxAmountSet(uint256 bondId, uint256 minAmount, uint256 maxAmount, uint256 maxAmountPerInvestor);

    event BondParametersEditedPart1(
        uint256 bondId,
        uint256 coupure,
        uint256 interestNum,
        uint256 interestDen,
        uint256 withholdingTaxNum,
        uint256 withholdingTaxDen,
        address issuer
    );

    event BondParametersEditedPart2(
        uint256 bondId,
        uint256 periodicInterestRate,
        uint256 netReturn,
        uint256 periodicity,
        uint256 duration,
        uint256 methodOfRepayment,
        uint256 maxSupply,
        uint256 formOfFinancing
    );

    event CampaignStartAndEndDateSet(uint256 bondId, uint256 startDate, uint256 endDate);
    event IssueDateSet(uint256 bondId, uint256 issueDate);

    event CouponsComputed(
        uint256 bondId,
        uint256[] couponDates,
        uint256[] remainingCapital,
        uint256[] capitalRepayments,
        uint256[] grossCouponRates,
        uint256[] netCouponRates
    );

    event BondIssued(uint256 bondId, uint256 timestamp, uint256 issuedAmount);
    event BondsWithdrawn(string bondPurchaseId, uint256 bondId, address holder, uint256 amount);
    event BalloonRateSet(uint256 bondId, uint256 balloonRateNum, uint256 balloonRateDen);
    event GracePeriodSet(uint256 bondId, uint256 gracePeriodDuration);
    event CapitalAmortizationFreePeriodSet(uint256 bondId, uint256 capitalAmortizationFreePeriodDuration);
    event InvestorsCountChanged(uint256 bondId, uint256 investorsCount);
    event RevocationsCountChanged(uint256 bondId, uint256 revocationsCount);

    event CampaignPaused(uint256 bondId);
    event CampaignUnpaused(uint256 bondId);

    event PeriodicInterestRateSet(uint256 bondId, uint256 periodicInterest);

    event BondTransferred(
        string bondTransferId, uint256 bondId, address oldAccount, address newAccount, uint256 amount
    );
    event ReservedAmountChanged(uint256 bondId, uint256 reservedAmount);

    event CapitalClaimAmountSet(uint256 bondId, string capitalClaimId, uint256 capitalAmount);

    // Errors
    error CampaignIsPaused();
    error CampaignNotPaused();
    error CampaignAlreadyPaused();
    error CampaignIsClosed();

    error BondAlreadyInitialized();
    error BondAlreadyIssued();
    error BondHasNotBeenIssued();
    error NoMoreBondsToBuy();

    error DurationIsNotAMultpleOfTwelve();
    error DurationIsNotAMultpleOfThree();

    error GracePeriodDurationIsNotAMultpleOfTwelve();
    error GracePeriodDurationIsNotAMultpleOfThree();

    error CapitalAmortizationFreePeriodDurationIsNotAMultpleOfTwelve();
    error CapitalAmortizationFreePeriodDurationIsNotAMultpleOfThree();

    error OldAccountDoesNotHaveEnoughBonds();

    error CannotReserveBeforeSignupDate();
    error CannotReserveAfterCampaignEnd();
    error ExceedingMaxAmountPerInvestor();
    error DivideByZero();

    modifier campaignNotPaused(uint256 _bondId) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__paused) {
            revert CampaignIsPaused();
        }
        _;
    }

    function setCurrencyAddress(address _currencyAddress) external {
        __currencyAddress = _currencyAddress;
    }

    function setCouponDatesFromIssueDate(uint256 _bondId, uint256 _issueTimeStamp) internal {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__issued == true) {
            revert BondAlreadyIssued();
        }
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(_issueTimeStamp);

        uint256 nbrOfPayments;
        if (_bondDetails.__periodicity == Periodicity.Annual) {
            nbrOfPayments = _bondDetails.__duration / 12;
        } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
            nbrOfPayments = _bondDetails.__duration / 3;
        } else {
            nbrOfPayments = _bondDetails.__duration;
        }

        uint256 couponMonth = 0;
        uint256 couponYear = year;
        uint256 couponDay = day;

        delete _bondDetails.__couponDates;
        delete _bondDetails.__couponStatus;

        for (uint256 i = 0; i < nbrOfPayments; ++i) {
            if (_bondDetails.__periodicity == Periodicity.Monthly) {
                if (i == 0) {
                    if (month % 12 == 0) {
                        couponYear = year + 1;
                    } else {
                        couponYear = year;
                    }
                    couponMonth = (month + 1) % 12;
                    if (couponMonth == 0) {
                        couponMonth = 12;
                    }
                } else {
                    if (couponMonth % 12 == 0) {
                        couponYear = couponYear + 1;
                    } else {
                        couponYear = couponYear;
                    }
                    couponMonth = (couponMonth + 1) % 12;
                    if (couponMonth == 0) {
                        couponMonth = 12;
                    }
                }
            } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
                if (i == 0) {
                    if (month >= 10) {
                        couponYear = year + 1;
                    } else {
                        couponYear = year;
                    }
                    couponMonth = (month + 3) % 12;
                    if (couponMonth == 0) {
                        couponMonth = 12;
                    }
                } else {
                    if (couponMonth >= 10) {
                        couponYear = couponYear + 1;
                    }
                    couponMonth = (couponMonth + 3) % 12;
                    if (couponMonth == 0) {
                        couponMonth = 12;
                    }
                }
            } else if (_bondDetails.__periodicity == Periodicity.Annual) {
                if (i == 0) {
                    couponYear = year + 1;
                    couponMonth = month;
                } else {
                    couponYear = couponYear + 1;
                }
            }
            _bondDetails.__couponDates.push(
                BokkyPooBahsDateTimeLibrary.timestampFromDate(couponYear, couponMonth, couponDay)
            );

            if (i == nbrOfPayments - 1) {
                _bondDetails.__maturityDate =
                    BokkyPooBahsDateTimeLibrary.timestampFromDate(couponYear, couponMonth, couponDay);
            }
            _bondDetails.__couponStatus.push(CouponStatus.Todo);
        }

        _bondDetails.__issueDate = _issueTimeStamp;
        emit IssueDateSet(_bondId, _issueTimeStamp);
    }

    function setCouponRates(uint256 _bondId) internal returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__issued == true) {
            revert BondAlreadyIssued();
        }

        uint256 nbrOfPayments;
        uint256 capitalRepayment = 0;
        uint256 remainingCapital = _bondDetails.__coupure;
        if (_bondDetails.__periodicity == Periodicity.Annual) {
            nbrOfPayments = _bondDetails.__duration / 12;
        } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
            nbrOfPayments = _bondDetails.__duration / 3;
        } else {
            nbrOfPayments = _bondDetails.__duration;
        }

        delete _bondDetails.__grossCouponRates;
        delete _bondDetails.__netCouponRates;
        delete _bondDetails.__capitalRepayment;
        delete _bondDetails.__remainingCapital;

        _bondDetails.__capitalRepayment.push(0);
        _bondDetails.__remainingCapital.push(_bondDetails.__coupure);
        _bondDetails.__grossCouponRates.push(0);
        _bondDetails.__netCouponRates.push(0);
        _bondDetails.__totalToBeRepaid = _bondDetails.__coupure;

        for (uint256 i = 0; i < nbrOfPayments; ++i) {
            if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Bullet) {
                capitalRepayment = 0;
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Degressive) {
                capitalRepayment = convert(div(ud60x18(_bondDetails.__coupure), ud60x18(nbrOfPayments)));
            } else if (
                _bondDetails.__methodOfRepayment == MethodOfRepayment.WithCapitalAmortizationFreePeriod
                    || _bondDetails.__methodOfRepayment == MethodOfRepayment.CapitalAmortizationAndGracePeriod
            ) {
                if (_bondDetails.__periodicity == Periodicity.Annual) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(nbrOfPayments - _bondDetails.__capitalAmortizationDuration / 12)
                        )
                    );
                } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(nbrOfPayments - _bondDetails.__capitalAmortizationDuration / 3)
                        )
                    );
                } else {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(nbrOfPayments - _bondDetails.__capitalAmortizationDuration)
                        )
                    );
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.GracePeriod) {
                if (_bondDetails.__periodicity == Periodicity.Annual) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(nbrOfPayments - _bondDetails.__gracePeriodDuration / 12)
                        )
                    );
                } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(nbrOfPayments - _bondDetails.__gracePeriodDuration / 3)
                        )
                    );
                } else {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure), ud60x18(nbrOfPayments - _bondDetails.__gracePeriodDuration)
                        )
                    );
                }
            }

            uint256 grossInterest =
                mul(ud60x18(_bondDetails.__periodicInterestRate), ud60x18(remainingCapital)).unwrap() * 1e18;

            uint256 taxMultiplier = 1 * 10 ** 18 - _bondDetails.__withholdingTax;

            UD60x18 taxableInterest = mul(ud60x18(grossInterest), ud60x18(taxMultiplier));

            uint256 netInterest = taxableInterest.unwrap();

            if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Bullet) {
                if (i < nbrOfPayments - 1) {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                } else {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(remainingCapital);
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Balloon) {
                if (i == 0) {
                    uint256 balloonRate = _bondDetails.__balloonRate;
                    uint256 temp = convert(mul(ud60x18(balloonRate), ud60x18(remainingCapital)));
                    remainingCapital = remainingCapital - temp;
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(temp);
                } else if (i == nbrOfPayments - 1) {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(remainingCapital);
                } else {
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(0);
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Degressive) {
                if (i < nbrOfPayments - 1) {
                    remainingCapital = remainingCapital - capitalRepayment;
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(capitalRepayment);
                } else {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(_bondDetails.__remainingCapital[i]);
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.WithCapitalAmortizationFreePeriod) {
                if (
                    (
                        _bondDetails.__periodicity == Periodicity.Annual
                            && i >= _bondDetails.__capitalAmortizationDuration / 12
                    )
                        || (
                            _bondDetails.__periodicity == Periodicity.Quarterly
                                && i >= _bondDetails.__capitalAmortizationDuration / 3
                        )
                        || (
                            _bondDetails.__periodicity == Periodicity.Monthly
                                && i >= _bondDetails.__capitalAmortizationDuration
                        )
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(_bondDetails.__remainingCapital[i]);
                    }
                } else {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.GracePeriod) {
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual && i >= _bondDetails.__gracePeriodDuration / 12)
                        || (
                            _bondDetails.__periodicity == Periodicity.Quarterly
                                && i >= _bondDetails.__gracePeriodDuration / 3
                        ) || (_bondDetails.__periodicity == Periodicity.Monthly && i >= _bondDetails.__gracePeriodDuration)
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(_bondDetails.__remainingCapital[i]);
                    }
                } else {
                    grossInterest = 0;
                    netInterest = 0;
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
            } else if (_bondDetails.__methodOfRepayment == MethodOfRepayment.CapitalAmortizationAndGracePeriod) {
                if (
                    (
                        _bondDetails.__periodicity == Periodicity.Annual
                            && i >= _bondDetails.__capitalAmortizationDuration / 12
                    )
                        || (
                            _bondDetails.__periodicity == Periodicity.Quarterly
                                && i >= _bondDetails.__capitalAmortizationDuration / 3
                        )
                        || (
                            _bondDetails.__periodicity == Periodicity.Monthly
                                && i >= _bondDetails.__capitalAmortizationDuration
                        )
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(_bondDetails.__remainingCapital[i]);
                    }
                } else {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual && i < _bondDetails.__gracePeriodDuration / 12)
                        || (
                            _bondDetails.__periodicity == Periodicity.Quarterly
                                && i < _bondDetails.__gracePeriodDuration / 3
                        ) || (_bondDetails.__periodicity == Periodicity.Monthly && i < _bondDetails.__gracePeriodDuration)
                ) {
                    grossInterest = 0;
                    netInterest = 0;
                }
            }
            _bondDetails.__grossCouponRates.push(grossInterest);

            _bondDetails.__netCouponRates.push(netInterest);
            _bondDetails.__totalToBeRepaid += netInterest;
        }

        emit PeriodicInterestRateSet(_bondId, _bondDetails.__periodicInterestRate);

        emit CouponsComputed(
            _bondId,
            _bondDetails.__couponDates,
            _bondDetails.__remainingCapital,
            _bondDetails.__capitalRepayment,
            _bondDetails.__grossCouponRates,
            _bondDetails.__netCouponRates
        );
        return (_bondDetails.__couponDates, _bondDetails.__grossCouponRates, _bondDetails.__netCouponRates);
    }

    function setParameters(BondInitParams.BondInit memory bi, bool replacementBond) internal {
        //BondDetails storage _bondDetails = __bondDetails[bi.__bondId];
        BondParams storage _bondDetails = bondStorage(bi.__bondId);
        _bondDetails.__issuer = bi.__issuer;
        _bondDetails.__coupure = bi.__coupure;
        if (bi.__interestDen == 0) {
            revert DivideByZero();
        }
        if (bi.__periodicity == uint256(Periodicity.Annual)) {
            if (bi.__duration % 12 != 0) {
                revert DurationIsNotAMultpleOfTwelve();
            }
        } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
            if (bi.__duration % 3 != 0) {
                revert DurationIsNotAMultpleOfThree();
            }
        }
        if (bi.__gracePeriodDuration != 0) {
            if (bi.__periodicity == uint256(Periodicity.Annual)) {
                if (bi.__gracePeriodDuration % 12 != 0) {
                    revert GracePeriodDurationIsNotAMultpleOfTwelve();
                } else {
                    this.setGracePeriodDuration(bi.__bondId, bi.__gracePeriodDuration);
                }
            } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
                if (bi.__gracePeriodDuration % 3 != 0) {
                    revert GracePeriodDurationIsNotAMultpleOfThree();
                } else {
                    this.setGracePeriodDuration(bi.__bondId, bi.__gracePeriodDuration);
                }
            }
        }
        if (bi.__capitalAmortizationDuration != 0) {
            if (bi.__periodicity == uint256(Periodicity.Annual)) {
                if (bi.__capitalAmortizationDuration % 12 != 0) {
                    revert CapitalAmortizationFreePeriodDurationIsNotAMultpleOfTwelve();
                } else {
                    this.setCapitalAmortizationFreeDuration(bi.__bondId, bi.__capitalAmortizationDuration);
                }
            } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
                if (bi.__capitalAmortizationDuration % 3 != 0) {
                    revert CapitalAmortizationFreePeriodDurationIsNotAMultpleOfThree();
                } else {
                    this.setCapitalAmortizationFreeDuration(bi.__bondId, bi.__capitalAmortizationDuration);
                }
            }
        }
        _bondDetails.__interestRate = div(ud60x18(bi.__interestNum), ud60x18(bi.__interestDen)).unwrap();
        _bondDetails.__withholdingTax = div(ud60x18(bi.__withholdingTaxNum), ud60x18(bi.__withholdingTaxDen)).unwrap();

        _bondDetails.__campaignMaxAmount = bi.__campaignMaxAmount;
        _bondDetails.__campaignMinAmount = bi.__campaignMinAmount;
        _bondDetails.__maxSupply = convert(div(ud60x18(bi.__campaignMaxAmount), ud60x18(bi.__coupure)));
        //_bondDetails.__maxAmountPerInvestor = ud60x18(bi.__maxAmountPerInvestor);
        _bondDetails.__maxAmountPerInvestor = bi.__maxAmountPerInvestor;
        _bondDetails.__duration = bi.__duration;

        _bondDetails.__campaignStartDate = bi.__campaignStartDate;
        _bondDetails.__campaignEndDate = BokkyPooBahsDateTimeLibrary.addDays(bi.__campaignStartDate, 60);

        if (bi.__periodicity == uint256(Periodicity.Annual)) {
            _bondDetails.__periodicity = Periodicity.Annual;
            _bondDetails.__periodicInterestRate = _bondDetails.__interestRate;
        } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
            _bondDetails.__periodicity = Periodicity.Quarterly;
            UD60x18 a = ud60x18(bi.__interestDen + bi.__interestNum);
            UD60x18 b = ud60x18(bi.__interestDen);
            UD60x18 c = ud60x18(1);
            UD60x18 d = ud60x18(4);
            _bondDetails.__periodicInterestRate = (pow(div(a, b), div(c, d)) - ud60x18(1)).unwrap();
        } else if (bi.__periodicity == uint256(Periodicity.Monthly)) {
            _bondDetails.__periodicity = Periodicity.Monthly;
            UD60x18 a = ud60x18(bi.__interestDen + bi.__interestNum);
            UD60x18 b = ud60x18(bi.__interestDen);
            UD60x18 c = ud60x18(1);
            UD60x18 d = ud60x18(12);
            _bondDetails.__periodicInterestRate = (pow(div(a, b), div(c, d)) - ud60x18(1)).unwrap();
        }

        if (bi.__methodOfRepayment == uint256(MethodOfRepayment.Degressive)) {
            if (bi.__capitalAmortizationDuration != 0) {
                _bondDetails.__methodOfRepayment = MethodOfRepayment.WithCapitalAmortizationFreePeriod;
            } else if (bi.__gracePeriodDuration != 0) {
                _bondDetails.__methodOfRepayment = MethodOfRepayment.GracePeriod;
            } else {
                _bondDetails.__methodOfRepayment = MethodOfRepayment.Degressive;
            }
        } else if (bi.__methodOfRepayment == uint256(MethodOfRepayment.Bullet)) {
            _bondDetails.__methodOfRepayment = MethodOfRepayment.Bullet;
        } else if (bi.__methodOfRepayment == uint256(MethodOfRepayment.Balloon)) {
            _bondDetails.__methodOfRepayment = MethodOfRepayment.Balloon;
        }
        _bondDetails.__capitalAmortizationDuration = bi.__capitalAmortizationDuration;
        _bondDetails.__gracePeriodDuration = bi.__gracePeriodDuration;
        if (bi.__balloonRateNum != 0 && bi.__balloonRateDen != 0) {
            _bondDetails.__balloonRate = div(ud60x18(bi.__balloonRateNum), ud60x18(bi.__balloonRateDen)).unwrap();
            this.setBalloonRate(bi.__bondId, bi.__balloonRateNum, bi.__balloonRateDen);
        }

        _bondDetails.__isSub = replacementBond;

        _bondDetails.__netReturn = _bondDetails.__interestRate
            - mul(
                ud60x18(_bondDetails.__interestRate), div(ud60x18(bi.__withholdingTaxNum), ud60x18(bi.__withholdingTaxDen))
            ).unwrap();

        emit GracePeriodSet(bi.__bondId, bi.__gracePeriodDuration);
        emit BalloonRateSet(bi.__bondId, bi.__balloonRateNum, bi.__balloonRateDen);
        emit CapitalAmortizationFreePeriodSet(bi.__bondId, bi.__capitalAmortizationDuration);
        emit MinAndMaxAmountSet(
            bi.__bondId,
            _bondDetails.__campaignMinAmount,
            _bondDetails.__campaignMaxAmount,
            _bondDetails.__maxAmountPerInvestor
        );
        emit CampaignStartAndEndDateSet(bi.__bondId, _bondDetails.__campaignStartDate, _bondDetails.__campaignEndDate);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    // Implement onERC1155Received to handle single token type receipt
    function onERC1155Received(
        address, /*  operator */
        address, /*  from */
        uint256, /*  id */
        uint256, /*  value */
        bytes calldata /*  data */
    )
        external
        override
        returns (bytes4)
    {
        // Handle the receipt of the ERC1155 token(s) here

        // Return the acceptance magic value
        return this.onERC1155Received.selector;
    }

    // Implement onERC1155BatchReceived to handle multiple token type receipt
    function onERC1155BatchReceived(
        address, /*  operator */
        address, /*  from */
        uint256[] calldata, /*  ids */
        uint256[] calldata, /*  values */
        bytes calldata /*  data */
    )
        external
        override
        returns (bytes4)
    {
        // Handle the receipt of the ERC1155 tokens here

        // Return the acceptance magic value
        return this.onERC1155BatchReceived.selector;
    }

    function initializeBond(BondInitParams.BondInit memory bi) external {
        //BondDetails storage _bondDetails = __bondDetails[bi.__bondId];
        __bond = address(this);
        BondParams storage _bondDetails = bondStorage(bi.__bondId);
        if (_bondDetails.__initDone) {
            revert BondAlreadyInitialized();
        }
        setParameters(bi, false);
        _bondDetails.__initDone = true;
        _bondDetails.__currencyAddress = __currencyAddress;
        emit BondInitializedPart1(
            bi.__bondId,
            bi.__coupure,
            bi.__interestNum,
            bi.__interestDen,
            bi.__withholdingTaxNum,
            bi.__withholdingTaxDen,
            bi.__issuer
        );
        emit BondInitializedPart2(
            bi.__bondId,
            _bondDetails.__periodicInterestRate,
            _bondDetails.__netReturn,
            bi.__periodicity,
            bi.__duration,
            bi.__methodOfRepayment,
            _bondDetails.__maxSupply,
            uint256(_bondDetails.__formOfFinancing)
        );
        setCouponDatesFromIssueDate(bi.__bondId, bi.__expectedIssueDate);
        setCouponRates(bi.__bondId);
    }

    function editBondParameters(BondInitParams.BondInit memory bi) external {
        //BondDetails storage _bondDetails = __bondDetails[bi.__bondId];
        BondParams storage _bondDetails = bondStorage(bi.__bondId);
        if (_bondDetails.__issued) {
            revert BondAlreadyIssued();
        }
        setParameters(bi, false);
        emit CampaignStartAndEndDateSet(bi.__bondId, _bondDetails.__campaignStartDate, _bondDetails.__campaignEndDate);
        emit MinAndMaxAmountSet(
            bi.__bondId,
            _bondDetails.__campaignMinAmount,
            _bondDetails.__campaignMaxAmount,
            _bondDetails.__maxAmountPerInvestor
        );
        emit BondParametersEditedPart1(
            bi.__bondId,
            bi.__coupure,
            bi.__interestNum,
            bi.__interestDen,
            bi.__withholdingTaxNum,
            bi.__withholdingTaxDen,
            bi.__issuer
        );
        emit BondParametersEditedPart2(
            bi.__bondId,
            _bondDetails.__periodicInterestRate,
            _bondDetails.__netReturn,
            bi.__periodicity,
            bi.__duration,
            bi.__methodOfRepayment,
            _bondDetails.__maxSupply,
            uint256(_bondDetails.__formOfFinancing)
        );

        setCouponDatesFromIssueDate(bi.__bondId, bi.__expectedIssueDate);
        setCouponRates(bi.__bondId);
    }

    function setBalloonRate(uint256 _bondId, uint256 _balloonRateNum, uint256 _balloonRateDen) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__balloonRate = convert(div(ud60x18(_balloonRateNum), ud60x18(_balloonRateDen)));
        emit BalloonRateSet(_bondId, _balloonRateNum, _balloonRateDen);
    }

    function setCapitalAmortizationFreeDuration(uint256 _bondId, uint256 _duration) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__capitalAmortizationDuration = _duration;
        emit CapitalAmortizationFreePeriodSet(_bondId, _duration);
    }

    function setGracePeriodDuration(uint256 _bondId, uint256 _duration) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__gracePeriodDuration = _duration;
        emit GracePeriodSet(_bondId, _duration);
    }

    function reserve(
        string memory _bondPurchaseId,
        uint256 _bondId,
        uint256 _bondAmount,
        address _buyer
    )
        external
        campaignNotPaused(_bondId)
        returns (uint256)
    {
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 availableAmountOfBonds;
        if (_bondDetails.__maxSupply > _bondDetails.__reservedAmount) {
            availableAmountOfBonds = _bondDetails.__maxSupply - _bondDetails.__reservedAmount;
        } else {
            availableAmountOfBonds = 0;
        }
        uint256 actualAmountOfBonds;
        if (_bondAmount > availableAmountOfBonds) {
            actualAmountOfBonds = availableAmountOfBonds;
        } else {
            actualAmountOfBonds = _bondAmount;
        }

        if (block.timestamp < _bondDetails.__campaignStartDate) {
            revert CannotReserveBeforeSignupDate();
        }
        if (block.timestamp > _bondDetails.__campaignEndDate) {
            revert CannotReserveAfterCampaignEnd();
        }
        if (actualAmountOfBonds == 0) {
            revert NoMoreBondsToBuy();
        }
        if (_bondDetails.__reservedAmountByAddress[_buyer] + actualAmountOfBonds > _bondDetails.__maxAmountPerInvestor)
        {
            revert ExceedingMaxAmountPerInvestor();
        }
        if (_bondDetails.__reservedAmountByAddress[_buyer] == 0) {
            _bondDetails.__investorsCount += 1;
            emit InvestorsCountChanged(_bondId, _bondDetails.__investorsCount);
        }
        _bondDetails.__reservedAmount += actualAmountOfBonds;
        _bondDetails.__reservedAmountByAddress[_buyer] += actualAmountOfBonds;
        _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId] = actualAmountOfBonds;
        emit ReservedAmountChanged(_bondId, _bondDetails.__reservedAmount);
        return actualAmountOfBonds;
    }

    function pauseCampaign(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__paused) {
            revert CampaignAlreadyPaused();
        }

        if (_bondDetails.__campaignStartDate >= block.timestamp || _bondDetails.__campaignEndDate <= block.timestamp) {
            revert CampaignIsClosed();
        }
        _bondDetails.__paused = true;
        emit CampaignPaused(_bondId);
    }

    function unpauseCampaign(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__paused) {
            revert CampaignNotPaused();
        }
        if (_bondDetails.__campaignStartDate >= block.timestamp || _bondDetails.__campaignEndDate <= block.timestamp) {
            revert CampaignIsClosed();
        }
        _bondDetails.__paused = false;
        emit CampaignUnpaused(_bondId);
    }

    function rescindReservation(string memory _bondPurchaseId, uint256 _bondId, address _buyer) external {
        BondParams storage _bondDetails = bondStorage(_bondId);

        require(
            _bondDetails.__reservedAmount >= _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId],
            "Underflow: reserved amount"
        );
        require(
            _bondDetails.__reservedAmountByAddress[_buyer] >= _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId],
            "Underflow: reserved amount by address"
        );

        _bondDetails.__reservedAmount -= _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId];
        _bondDetails.__reservedAmountByAddress[_buyer] -= _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId];

        if (_bondDetails.__reservedAmountByAddress[_buyer] == 0) {
            _bondDetails.__investorsCount -= 1;
            emit InvestorsCountChanged(_bondId, _bondDetails.__investorsCount);
        }
        _bondDetails.__revocationsCount += 1;
        _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId] = 0;
        emit RevocationsCountChanged(_bondId, _bondDetails.__revocationsCount);
        emit ReservedAmountChanged(_bondId, _bondDetails.__reservedAmount);
    }

    function issueBond(uint256 _bondId, uint256 _issueDate) external onlyOwner {
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__currentLine = 1;
        if (_bondDetails.__issued) {
            revert BondAlreadyIssued();
        }
        setCouponDatesFromIssueDate(_bondId, _issueDate);
        setCouponRates(_bondId);
        _bondDetails.__issued = true;
        _bondDetails.__status = BondStatus.Issued;
        _bondDetails.__issuedAmount = _bondDetails.__reservedAmount;
        ERC1155Facet(__bond).mint(address(this), _bondId, _bondDetails.__issuedAmount, "");

        emit BondIssued(_bondId, _issueDate, _bondDetails.__issuedAmount);
    }

    function withdrawBondsPurchased(string memory _bondPurchaseId, uint256 _bondId, address holder) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__issued) {
            revert BondHasNotBeenIssued();
        }
        uint256 amount = _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId];
        uint256 tokenAmount = amount * _bondDetails.__coupure;
        uint256 currentAllowance = ERC20(__currencyAddress).allowance(holder, address(this));
        require(currentAllowance >= tokenAmount, "ERC20: transfer amount exceeds allowance");
        // slither-disable-next-line all
        bool success = ERC20(__currencyAddress).transferFrom(holder, _bondDetails.__issuer, tokenAmount);
        require(success, "ERC20: transfer failed");
        ERC1155Facet(__bond).mint(holder, _bondId, amount, "");
        //_bondDetails.__confirmedReservationByAddress[holder] = 0;
        _bondDetails.__isHolder[holder] = true;
        emit BondsWithdrawn(_bondPurchaseId, _bondId, holder, amount);
    }

    function transferBond(
        string memory _bondTransferId,
        uint256 _bondId,
        address _old,
        address _new,
        uint256 _amount
    )
        external
        onlyOwner
    {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__issued) {
            revert BondHasNotBeenIssued();
        }
        if (ERC1155Facet(__bond).balanceOf(_old, _bondId) < _amount) {
            revert OldAccountDoesNotHaveEnoughBonds();
        }
        uint256 _tokenAmount = _amount * _bondDetails.__coupure;
        uint256 currentAllowance = ERC20(__currencyAddress).allowance(_new, address(this));
        require(currentAllowance >= _tokenAmount, "ERC20: transfer amount exceeds allowance");
        // slither-disable-next-line all
        bool success = ERC20(__currencyAddress).transferFrom(_new, _old, _tokenAmount);
        require(success, "ERC20: transfer failed");
        ERC1155Facet(__bond).safeTransferFrom(_old, _new, _bondId, _amount, "");
        emit BondTransferred(_bondTransferId, _bondId, _old, _new, _amount);
    }

    function getSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](15);
        selectors[0] = BondFacet.initializeBond.selector;
        selectors[1] = BondFacet.setCurrencyAddress.selector;
        selectors[2] = BondFacet.editBondParameters.selector;
        selectors[3] = BondFacet.setBalloonRate.selector;
        selectors[4] = BondFacet.setCapitalAmortizationFreeDuration.selector;
        selectors[5] = BondFacet.setGracePeriodDuration.selector;
        selectors[6] = BondFacet.reserve.selector;
        selectors[7] = BondFacet.pauseCampaign.selector;
        selectors[8] = BondFacet.unpauseCampaign.selector;
        selectors[9] = BondFacet.rescindReservation.selector;
        selectors[10] = BondFacet.transferBond.selector;
        selectors[11] = BondFacet.withdrawBondsPurchased.selector;
        selectors[12] = BondFacet.issueBond.selector;
        selectors[13] = BondFacet.onERC1155Received.selector;
        selectors[14] = BondFacet.onERC1155BatchReceived.selector;

        return selectors;
    }
}
