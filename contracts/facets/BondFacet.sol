// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1155Facet} from "./ERC1155Facet.sol";
import "prb-math/UD60x18.sol";
import {BokkyPooBahsDateTimeLibrary} from "../libraries/BokkyPooBahsDateTimeLibrary.sol";
import {BondInitParams} from "../libraries/StructBondInit.sol";
import {BondStorage} from "./BondStorage.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondFacet is BondStorage {
    ERC1155Facet private __bond;
    address private __currencyAddress;

    // Events
    event BondInitializedPart1(
        uint256 bondId,
        uint256 coupure,
        uint256 interestNum,
        uint256 interestDen,
        uint256 withholdingTaxNum,
        uint256 withholdingTaxDen
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

    event MinAndMaxAmountSet(
        uint256 bondId,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxAmountPerInvestor
    );

    event BondParametersEditedPart1(
        uint256 bondId,
        uint256 coupure,
        uint256 interestNum,
        uint256 interestDen,
        uint256 withholdingTaxNum,
        uint256 withholdingTaxDen
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

    event CampaignStartAndEndDateSet(
        uint256 bondId,
        uint256 startDate,
        uint256 endDate
    );
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
    event BondsWithdrawn(
        string bondPurchaseId,
        uint256 bondId,
        address holder,
        uint256 amount
    );
    event BalloonRateSet(
        uint256 bondId,
        uint256 balloonRateNum,
        uint256 balloonRateDen
    );
    event GracePeriodSet(uint256 bondId, uint256 gracePeriodDuration);
    event CapitalAmortizationFreePeriodSet(
        uint256 bondId,
        uint256 capitalAmortizationFreePeriodDuration
    );
    event InvestorsCountChanged(uint256 bondId, uint256 investorsCount);
    event RevocationsCountChanged(uint256 bondId, uint256 revocationsCount);

    event CampaignPaused(uint256 bondId);
    event CampaignUnpaused(uint256 bondId);

    event BondTerminated(uint256 bondId);
    event PeriodicInterestRateSet(uint256 bondId, uint256 periodicInterest);

    event BondTransferred(
        string bondTransferId,
        uint256 bondId,
        address oldAccount,
        address newAccount,
        uint256 amount
    );
    event ReservedAmountChanged(uint256 bondId, uint256 reservedAmount);

    event CapitalClaimAmountSet(
        uint256 bondId,
        string capitalClaimId,
        uint256 capitalAmount
    );

    event CouponStatusChanged(uint256 bondId, uint256 lineNumber);

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
    error ExceedingMaxAmountPerInvestor();
    error NotAllClaimsReceivedForNextPayment();
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

    function setCouponDatesFromIssueDate(
        uint256 _bondId,
        uint256 _issueTimeStamp
    ) internal {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__issued == true) {
            revert BondAlreadyIssued();
        }
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(
            _issueTimeStamp
        );

        uint256 nbrOfPayments;
        if (_bondDetails.__periodicity == Periodicity.Annual) {
            nbrOfPayments = _bondDetails.__duration / 12;
        } else if (_bondDetails.__periodicity == Periodicity.Quarterly) {
            nbrOfPayments = _bondDetails.__duration / 3;
        } else {
            nbrOfPayments = _bondDetails.__duration;
        }

        uint256 couponMonth;
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
                    if (month >= 11) {
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
                    if (month == 12) {
                        couponYear = year + 1;
                    }
                    couponMonth = (month) % 12;
                    if (couponMonth == 0) {
                        couponMonth = 12;
                    }
                } else {
                    couponYear = couponYear + 1;
                }
            }
            _bondDetails.__couponDates.push(
                BokkyPooBahsDateTimeLibrary.timestampFromDate(
                    couponYear,
                    couponMonth,
                    couponDay
                )
            );

            if (i == nbrOfPayments - 1) {
                _bondDetails.__maturityDate = BokkyPooBahsDateTimeLibrary
                    .timestampFromDate(couponYear, couponMonth, couponDay);
            }
            _bondDetails.__couponStatus.push(CouponStatus.Todo);
        }

        _bondDetails.__issueDate = _issueTimeStamp;
        emit IssueDateSet(_bondId, _issueTimeStamp);
    }

    function setCouponRates(
        uint256 _bondId
    ) internal returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__issued == true) {
            revert BondAlreadyIssued();
        }

        uint256 nbrOfPayments;
        uint256 capitalRepayment;
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
            } else if (
                _bondDetails.__methodOfRepayment == MethodOfRepayment.Degressive
            ) {
                capitalRepayment = convert(
                    div(ud60x18(_bondDetails.__coupure), ud60x18(nbrOfPayments))
                );
            } else if (
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.WithCapitalAmortizationFreePeriod ||
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.CapitalAmortizationAndGracePeriod
            ) {
                if (_bondDetails.__periodicity == Periodicity.Annual) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__capitalAmortizationDuration /
                                    12
                            )
                        )
                    );
                } else if (
                    _bondDetails.__periodicity == Periodicity.Quarterly
                ) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__capitalAmortizationDuration /
                                    3
                            )
                        )
                    );
                } else {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__capitalAmortizationDuration
                            )
                        )
                    );
                }
            } else if (
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.GracePeriod
            ) {
                if (_bondDetails.__periodicity == Periodicity.Annual) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__gracePeriodDuration /
                                    12
                            )
                        )
                    );
                } else if (
                    _bondDetails.__periodicity == Periodicity.Quarterly
                ) {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__gracePeriodDuration /
                                    3
                            )
                        )
                    );
                } else {
                    capitalRepayment = convert(
                        div(
                            ud60x18(_bondDetails.__coupure),
                            ud60x18(
                                nbrOfPayments -
                                    _bondDetails.__gracePeriodDuration
                            )
                        )
                    );
                }
            }

            uint256 grossInterest = convert(
                mul(
                    ud60x18(_bondDetails.__periodicInterestRate),
                    ud60x18(remainingCapital)
                )
            );
            UD60x18 taxMultiplier = ud60x18(1) -
                ud60x18(_bondDetails.__withholdingTax);
            UD60x18 taxableInterest = mul(
                ud60x18(grossInterest),
                taxMultiplier
            );
            uint256 netInterest = convert(taxableInterest);

            if (_bondDetails.__methodOfRepayment == MethodOfRepayment.Bullet) {
                if (i < nbrOfPayments - 1) {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                } else {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(remainingCapital);
                }
            } else if (
                _bondDetails.__methodOfRepayment == MethodOfRepayment.Balloon
            ) {
                if (i == 0) {
                    uint256 balloonRate = _bondDetails.__balloonRate;
                    UD60x18 temp = mul(
                        ud60x18(balloonRate),
                        ud60x18(remainingCapital)
                    );
                    remainingCapital = remainingCapital - convert(temp);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(convert(temp));
                } else if (i == nbrOfPayments - 1) {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(remainingCapital);
                } else {
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(0);
                }
            } else if (
                _bondDetails.__methodOfRepayment == MethodOfRepayment.Degressive
            ) {
                if (i < nbrOfPayments - 1) {
                    remainingCapital = remainingCapital - capitalRepayment;
                    _bondDetails.__remainingCapital.push(remainingCapital);
                    _bondDetails.__capitalRepayment.push(capitalRepayment);
                } else {
                    _bondDetails.__remainingCapital.push(0);
                    _bondDetails.__capitalRepayment.push(
                        _bondDetails.__remainingCapital[i]
                    );
                }
            } else if (
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.WithCapitalAmortizationFreePeriod
            ) {
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual &&
                        i >= _bondDetails.__capitalAmortizationDuration / 12) ||
                    (_bondDetails.__periodicity == Periodicity.Quarterly &&
                        i >= _bondDetails.__capitalAmortizationDuration / 3) ||
                    (_bondDetails.__periodicity == Periodicity.Monthly &&
                        i >= _bondDetails.__capitalAmortizationDuration)
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(
                            _bondDetails.__remainingCapital[i]
                        );
                    }
                } else {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
            } else if (
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.GracePeriod
            ) {
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual &&
                        i >= _bondDetails.__gracePeriodDuration / 12) ||
                    (_bondDetails.__periodicity == Periodicity.Quarterly &&
                        i >= _bondDetails.__gracePeriodDuration / 3) ||
                    (_bondDetails.__periodicity == Periodicity.Monthly &&
                        i >= _bondDetails.__gracePeriodDuration)
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(
                            _bondDetails.__remainingCapital[i]
                        );
                    }
                } else {
                    grossInterest = 0;
                    netInterest = 0;
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
            } else if (
                _bondDetails.__methodOfRepayment ==
                MethodOfRepayment.CapitalAmortizationAndGracePeriod
            ) {
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual &&
                        i >= _bondDetails.__capitalAmortizationDuration / 12) ||
                    (_bondDetails.__periodicity == Periodicity.Quarterly &&
                        i >= _bondDetails.__capitalAmortizationDuration / 3) ||
                    (_bondDetails.__periodicity == Periodicity.Monthly &&
                        i >= _bondDetails.__capitalAmortizationDuration)
                ) {
                    if (i < nbrOfPayments - 1) {
                        remainingCapital = remainingCapital - capitalRepayment;
                        _bondDetails.__capitalRepayment.push(capitalRepayment);
                        _bondDetails.__remainingCapital.push(remainingCapital);
                    } else {
                        remainingCapital = 0;
                        _bondDetails.__remainingCapital.push(remainingCapital);
                        _bondDetails.__capitalRepayment.push(
                            _bondDetails.__remainingCapital[i]
                        );
                    }
                } else {
                    _bondDetails.__capitalRepayment.push(0);
                    _bondDetails.__remainingCapital.push(remainingCapital);
                }
                if (
                    (_bondDetails.__periodicity == Periodicity.Annual &&
                        i < _bondDetails.__gracePeriodDuration / 12) ||
                    (_bondDetails.__periodicity == Periodicity.Quarterly &&
                        i < _bondDetails.__gracePeriodDuration / 3) ||
                    (_bondDetails.__periodicity == Periodicity.Monthly &&
                        i < _bondDetails.__gracePeriodDuration)
                ) {
                    grossInterest = 0;
                    netInterest = 0;
                }
            }
            _bondDetails.__grossCouponRates.push(grossInterest);

            _bondDetails.__netCouponRates.push(netInterest);
            _bondDetails.__totalToBeRepaid += netInterest;
        }

        if (_bondDetails.__periodicInterestRate < 1) {
            emit PeriodicInterestRateSet(
                _bondId,
                _bondDetails.__periodicInterestRate
            );
        } else {
            emit PeriodicInterestRateSet(
                _bondId,
                _bondDetails.__periodicInterestRate
            );
        }
        emit CouponsComputed(
            _bondId,
            _bondDetails.__couponDates,
            _bondDetails.__remainingCapital,
            _bondDetails.__capitalRepayment,
            _bondDetails.__grossCouponRates,
            _bondDetails.__netCouponRates
        );
        return (
            _bondDetails.__couponDates,
            _bondDetails.__grossCouponRates,
            _bondDetails.__netCouponRates
        );
    }

    function setParameters(
        BondInitParams.BondInit memory bi,
        bool replacementBond
    ) internal {
        //BondDetails storage _bondDetails = __bondDetails[bi.__bondId];
        BondParams storage _bondDetails = bondStorage(bi.__bondId);
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
                }
            } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
                if (bi.__gracePeriodDuration % 3 != 0) {
                    revert GracePeriodDurationIsNotAMultpleOfThree();
                }
            }
        }
        if (bi.__capitalAmortizationDuration != 0) {
            if (bi.__periodicity == uint256(Periodicity.Annual)) {
                if (bi.__capitalAmortizationDuration % 12 != 0) {
                    revert CapitalAmortizationFreePeriodDurationIsNotAMultpleOfTwelve();
                }
            } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
                if (bi.__capitalAmortizationDuration % 3 != 0) {
                    revert CapitalAmortizationFreePeriodDurationIsNotAMultpleOfThree();
                }
            }
        }
        _bondDetails.__interestRate = convert(
            div(ud60x18(bi.__interestNum), ud60x18(bi.__interestDen))
        );
        _bondDetails.__withholdingTax = convert(
            div(
                ud60x18(bi.__withholdingTaxNum),
                ud60x18(bi.__withholdingTaxDen)
            )
        );
        _bondDetails.__campaignMaxAmount = bi.__campaignMaxAmount;
        _bondDetails.__campaignMinAmount = bi.__campaignMinAmount;
        _bondDetails.__maxSupply = convert(
            div(ud60x18(bi.__campaignMaxAmount), ud60x18(bi.__coupure))
        );
        //_bondDetails.__maxAmountPerInvestor = ud60x18(bi.__maxAmountPerInvestor);
        _bondDetails.__maxAmountPerInvestor = bi.__maxAmountPerInvestor;
        _bondDetails.__duration = bi.__duration;

        _bondDetails.__campaignStartDate = bi.__campaignStartDate;
        _bondDetails.__campaignEndDate = BokkyPooBahsDateTimeLibrary.addDays(
            bi.__campaignStartDate,
            60
        );

        if (bi.__periodicity == uint256(Periodicity.Annual)) {
            _bondDetails.__periodicity = Periodicity.Annual;
            _bondDetails.__periodicInterestRate = _bondDetails.__interestRate;
        } else if (bi.__periodicity == uint256(Periodicity.Quarterly)) {
            _bondDetails.__periodicity = Periodicity.Quarterly;
            UD60x18 a = ud60x18(bi.__interestDen + bi.__interestNum);
            UD60x18 b = ud60x18(bi.__interestDen);
            UD60x18 c = ud60x18(1);
            UD60x18 d = ud60x18(4);
            _bondDetails.__periodicInterestRate = convert(
                pow(div(a, b), div(c, d)) - ud60x18(1)
            );
        } else if (bi.__periodicity == uint256(Periodicity.Monthly)) {
            _bondDetails.__periodicity = Periodicity.Monthly;
            UD60x18 a = ud60x18(bi.__interestDen + bi.__interestNum);
            UD60x18 b = ud60x18(bi.__interestDen);
            UD60x18 c = ud60x18(1);
            UD60x18 d = ud60x18(12);
            _bondDetails.__periodicInterestRate = convert(
                pow(div(a, b), div(c, d)) - ud60x18(1)
            );
        }

        if (bi.__methodOfRepayment == uint256(MethodOfRepayment.Degressive)) {
            if (bi.__capitalAmortizationDuration != 0) {
                _bondDetails.__methodOfRepayment = MethodOfRepayment
                    .WithCapitalAmortizationFreePeriod;
            } else if (bi.__gracePeriodDuration != 0) {
                _bondDetails.__methodOfRepayment = MethodOfRepayment
                    .GracePeriod;
            } else {
                _bondDetails.__methodOfRepayment = MethodOfRepayment.Degressive;
            }
        } else if (
            bi.__methodOfRepayment == uint256(MethodOfRepayment.Bullet)
        ) {
            _bondDetails.__methodOfRepayment = MethodOfRepayment.Bullet;
        } else if (
            bi.__methodOfRepayment == uint256(MethodOfRepayment.Balloon)
        ) {
            _bondDetails.__methodOfRepayment = MethodOfRepayment.Balloon;
        }
        _bondDetails.__capitalAmortizationDuration = bi
            .__capitalAmortizationDuration;
        _bondDetails.__gracePeriodDuration = bi.__gracePeriodDuration;
        if (bi.__balloonRateNum != 0 && bi.__balloonRateDen != 0) {
            _bondDetails.__balloonRate = convert(
                div(ud60x18(bi.__balloonRateNum), ud60x18(bi.__balloonRateDen))
            );
        }

        _bondDetails.__isSub = replacementBond;

        _bondDetails.__netReturn =
            _bondDetails.__interestRate -
            convert(
                mul(
                    ud60x18(_bondDetails.__interestRate),
                    ud60x18(_bondDetails.__withholdingTax)
                )
            );

        emit GracePeriodSet(bi.__bondId, bi.__gracePeriodDuration);
        emit BalloonRateSet(
            bi.__bondId,
            bi.__balloonRateNum,
            bi.__balloonRateDen
        );
        emit CapitalAmortizationFreePeriodSet(
            bi.__bondId,
            bi.__capitalAmortizationDuration
        );
        emit MinAndMaxAmountSet(
            bi.__bondId,
            _bondDetails.__campaignMinAmount,
            _bondDetails.__campaignMaxAmount,
            _bondDetails.__maxAmountPerInvestor
        );
        emit CampaignStartAndEndDateSet(
            bi.__bondId,
            _bondDetails.__campaignStartDate,
            _bondDetails.__campaignEndDate
        );
    }

    function initializeBond(BondInitParams.BondInit memory bi) external {
        //BondDetails storage _bondDetails = __bondDetails[bi.__bondId];
        __bond = ERC1155Facet(address(this));
        BondParams storage _bondDetails = bondStorage(bi.__bondId);
        if (_bondDetails.__initDone) {
            revert BondAlreadyInitialized();
        }
        setParameters(bi, false);
        _bondDetails.__initDone = true;
        emit BondInitializedPart1(
            bi.__bondId,
            bi.__coupure,
            bi.__interestNum,
            bi.__interestDen,
            bi.__withholdingTaxNum,
            bi.__withholdingTaxDen
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
        emit CampaignStartAndEndDateSet(
            bi.__bondId,
            _bondDetails.__campaignStartDate,
            _bondDetails.__campaignEndDate
        );
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
            bi.__withholdingTaxDen
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

    function cancel(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);

        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        _bondDetails.__cancelled = true;
        //_bondDetails2.__cancelled = true;
    }

    function setBalloonRate(
        uint256 _bondId,
        uint256 _balloonRateNum,
        uint256 _balloonRateDen
    ) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__balloonRate = convert(
            div(ud60x18(_balloonRateNum), ud60x18(_balloonRateDen))
        );
        emit BalloonRateSet(_bondId, _balloonRateNum, _balloonRateDen);
    }

    function setCapitalAmortizationFreeDuration(
        uint256 _bondId,
        uint256 _duration
    ) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__capitalAmortizationDuration = _duration;
        emit CapitalAmortizationFreePeriodSet(_bondId, _duration);
    }

    function setGracePeriodDuration(
        uint256 _bondId,
        uint256 _duration
    ) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__gracePeriodDuration = _duration;
        emit GracePeriodSet(_bondId, _duration);
    }

    function setInterestRate(
        uint256 _bondId,
        uint256 _interestNum,
        uint256 _interestDen
    ) external {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__interestRate = convert(
            div(ud60x18(_interestNum), ud60x18(_interestDen))
        );
    }

    function getCouponsDates(
        uint256 _bondId
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 dateLength = _bondDetails.__couponDates.length;
        uint256[] memory day = new uint256[](dateLength);
        uint256[] memory month = new uint256[](dateLength);
        uint256[] memory year = new uint256[](dateLength);
        for (uint256 i = 0; i < dateLength; i++) {
            (uint256 y, uint256 m, uint256 d) = BokkyPooBahsDateTimeLibrary
                .timestampToDate(_bondDetails.__couponDates[i]);
            day[i] = d;
            month[i] = m;
            year[i] = y;
        }
        return (day, month, year);
    }

    function getCouponsRates(
        uint256 _bondId
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        BondParams storage _bondDetails = bondStorage(_bondId);

        uint256[] memory gross = new uint256[](
            _bondDetails.__grossCouponRates.length
        );
        uint256[] memory net = new uint256[](
            _bondDetails.__grossCouponRates.length
        );
        uint256[] memory capital = new uint256[](
            _bondDetails.__capitalRepayment.length
        );
        uint256[] memory remainingCapital = new uint256[](
            _bondDetails.__remainingCapital.length
        );
        for (uint256 i = 0; i < _bondDetails.__grossCouponRates.length; i++) {
            gross[i] = _bondDetails.__grossCouponRates[i];
            net[i] = _bondDetails.__netCouponRates[i];
            capital[i] = _bondDetails.__capitalRepayment[i];
            remainingCapital[i] = _bondDetails.__remainingCapital[i];
        }
        return (gross, net, capital, remainingCapital);
    }

    function reserve(
        string memory _bondPurchaseId,
        uint256 _bondId,
        uint256 _bondAmount,
        address _buyer
    ) external campaignNotPaused(_bondId) returns (uint256) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 availableAmountOfBonds = _bondDetails.__maxSupply -
            _bondDetails.__reservedAmount;
        uint256 actualAmountOfBonds;
        if (_bondAmount > availableAmountOfBonds) {
            actualAmountOfBonds = availableAmountOfBonds;
        } else {
            actualAmountOfBonds = _bondAmount;
        }

        if (block.timestamp < _bondDetails.__campaignStartDate) {
            revert CannotReserveBeforeSignupDate();
        }
        if (actualAmountOfBonds == 0) {
            revert NoMoreBondsToBuy();
        }
        if (
            _bondDetails.__reservedAmountByAddress[_buyer] +
                actualAmountOfBonds >
            _bondDetails.__maxAmountPerInvestor
        ) {
            revert ExceedingMaxAmountPerInvestor();
        }
        if (_bondDetails.__reservedAmountByAddress[_buyer] == 0) {
            _bondDetails.__investorsCount += 1;
            emit InvestorsCountChanged(_bondId, _bondDetails.__investorsCount);
        }
        _bondDetails.__reservedAmount += actualAmountOfBonds;
        _bondDetails.__reservedAmountByAddress[_buyer] += actualAmountOfBonds;
        _bondDetails.__reservedAmountByPurchaseId[
            _bondPurchaseId
        ] = actualAmountOfBonds;
        emit ReservedAmountChanged(_bondId, _bondDetails.__reservedAmount);
        return actualAmountOfBonds;
    }

    function pauseCampaign(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (_bondDetails.__paused) {
            revert CampaignAlreadyPaused();
        }

        if (
            _bondDetails.__campaignStartDate >= block.timestamp ||
            _bondDetails.__campaignEndDate <= block.timestamp
        ) {
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
        if (
            _bondDetails.__campaignStartDate >= block.timestamp ||
            _bondDetails.__campaignEndDate <= block.timestamp
        ) {
            revert CampaignIsClosed();
        }
        _bondDetails.__paused = false;
        emit CampaignUnpaused(_bondId);
    }

    function rescindReservation(
        string memory _bondPurchaseId,
        uint256 _bondId,
        address _buyer
    ) external {
        BondParams storage _bondDetails = bondStorage(_bondId);

        /*require(
      __bondDetails[_bondId].__reservedAmountByPurchaseId[_bondPurchaseId] != 0,
      "BondFacet: Reservation does not exist"
    );*/
        //should the status be "reserved"?
        _bondDetails.__reservedAmount -= _bondDetails
            .__reservedAmountByPurchaseId[_bondPurchaseId];
        _bondDetails.__reservedAmountByAddress[_buyer] -= _bondDetails
            .__reservedAmountByPurchaseId[_bondPurchaseId];

        if (_bondDetails.__reservedAmountByAddress[_buyer] == 0) {
            _bondDetails.__investorsCount -= 1;
            emit InvestorsCountChanged(_bondId, _bondDetails.__investorsCount);
        }
        _bondDetails.__revocationsCount += 1;
        _bondDetails.__reservedAmountByPurchaseId[_bondPurchaseId] = 0;
        emit RevocationsCountChanged(_bondId, _bondDetails.__revocationsCount);
        emit ReservedAmountChanged(_bondId, _bondDetails.__reservedAmount);
    }

    function issueBond(uint256 _bondId, uint256 _issueDate) external {
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

        emit BondIssued(_bondId, _issueDate, _bondDetails.__issuedAmount);
    }

    function withdrawBondsPurchased(
        string memory _bondPurchaseId,
        uint256 _bondId,
        address holder
    ) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__issued) {
            revert BondHasNotBeenIssued();
        }
        uint256 amount = _bondDetails.__reservedAmountByPurchaseId[
            _bondPurchaseId
        ];
        uint256 tokenAmount = amount * _bondDetails.__coupure;
        ERC20(__currencyAddress).transferFrom(
            holder,
            address(this),
            tokenAmount
        );
        __bond.mint(holder, _bondId, amount);
        //_bondDetails.__confirmedReservationByAddress[holder] = 0;
        _bondDetails.__isHolder[holder] = true;
        emit BondsWithdrawn(_bondPurchaseId, _bondId, holder, amount);
    }

    function terminate(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__status = BondStatus.Terminated;
        emit BondTerminated(_bondId);
    }

    function transferBond(
        string memory _bondTransferId,
        uint256 _bondId,
        address _old,
        address _new,
        uint256 _amount
    ) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__issued) {
            revert BondHasNotBeenIssued();
        }
        if (__bond.balanceOf(_old, _bondId) < _amount) {
            revert OldAccountDoesNotHaveEnoughBonds();
        }
        uint256 _tokenAmount = _amount * _bondDetails.__coupure;
        ERC20(__currencyAddress).transferFrom(_new, _old, _tokenAmount);
        __bond.safeTransferFrom(_old, _new, _bondId, _amount, "");
        emit BondTransferred(_bondTransferId, _bondId, _old, _new, _amount);
    }

    // claim coupon (+ interest)
    function claimCoupon(
        uint256 _bondId,
        address _buyer
    ) external returns (uint256) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 userBalance = __bond.balanceOf(_buyer, _bondId);
        uint256 interestAmount = convert(
            mul(
                ud60x18(userBalance),
                ud60x18(
                    _bondDetails.__netCouponRates[_bondDetails.__currentLine]
                )
            )
        );
        uint256 capitalAmount = convert(
            mul(
                ud60x18(userBalance),
                ud60x18(
                    _bondDetails.__capitalRepayment[_bondDetails.__currentLine]
                )
            )
        );
        _bondDetails.__nextInterestAmount += userBalance;
        _bondDetails.__nextCapitalAmount += userBalance;

        if (
            _bondDetails.__nextCapitalAmount == _bondDetails.__issuedAmount &&
            _bondDetails.__nextInterestAmount == _bondDetails.__issuedAmount
        ) {
            _bondDetails.__allClaimsReceived = true;
        }
        return interestAmount + capitalAmount;
    }

    // withdraw coupon (with interest)
    function withdrawCouponClaim(uint256 _bondId, address _buyer) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__allClaimsReceived) {
            revert NotAllClaimsReceivedForNextPayment();
        }

        uint256 userBalance = __bond.balanceOf(_buyer, _bondId);
        uint256 interestAmount = convert(
            mul(
                ud60x18(userBalance),
                ud60x18(
                    _bondDetails.__netCouponRates[_bondDetails.__currentLine]
                )
            )
        );
        uint256 tokenAmount = userBalance *
            _bondDetails.__coupure +
            interestAmount;
        ERC20(__currencyAddress).transfer(_buyer, tokenAmount);
        _bondDetails.__nextInterestAmount -= userBalance;
        _bondDetails.__nextCapitalAmount -= userBalance;

        if (
            _bondDetails.__nextInterestAmount == 0 &&
            _bondDetails.__nextCapitalAmount == 0
        ) {
            _bondDetails.__couponStatus[
                _bondDetails.__currentLine
            ] = CouponStatus.Executed;
            emit CouponStatusChanged(_bondId, _bondDetails.__currentLine);
            _bondDetails.__currentLine += 1;
            _bondDetails.__allClaimsReceived = false;
        }
    }
    function getSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](20);
        selectors[0] = BondFacet.initializeBond.selector;
        selectors[1] = BondFacet.setCurrencyAddress.selector;
        selectors[2] = BondFacet.editBondParameters.selector;
        selectors[3] = BondFacet.cancel.selector;
        selectors[4] = BondFacet.setBalloonRate.selector;
        selectors[5] = BondFacet.setCapitalAmortizationFreeDuration.selector;
        selectors[6] = BondFacet.setGracePeriodDuration.selector;
        selectors[7] = BondFacet.getCouponsDates.selector;
        selectors[8] = BondFacet.getCouponsRates.selector;
        selectors[9] = BondFacet.setInterestRate.selector;
        selectors[10] = BondFacet.reserve.selector;
        selectors[11] = BondFacet.pauseCampaign.selector;
        selectors[12] = BondFacet.unpauseCampaign.selector;
        selectors[13] = BondFacet.rescindReservation.selector;
        selectors[14] = BondFacet.claimCoupon.selector;
        selectors[15] = BondFacet.withdrawCouponClaim.selector;
        selectors[16] = BondFacet.transferBond.selector;
        selectors[17] = BondFacet.withdrawBondsPurchased.selector;
        selectors[18] = BondFacet.terminate.selector;
        selectors[19] = BondFacet.issueBond.selector;

        return selectors;
    }
}
