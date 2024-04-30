// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BondStorage {
    enum BondStatus {
        Unset,
        Issued,
        Terminated,
        Maturity
    }

    enum CouponStatus {
        Todo,
        Executed
    }

    enum Periodicity {
        Annual,
        Quarterly,
        Monthly
    }

    enum FormOfFinancing {
        Bond,
        SubordinatedBond
    }

    enum MethodOfRepayment {
        Bullet,
        Degressive,
        Balloon,
        WithCapitalAmortizationFreePeriod,
        GracePeriod,
        CapitalAmortizationAndGracePeriod
    }

    struct BondParams {
        uint256 __campaignMinAmount;
        uint256 __campaignMaxAmount;
        uint256 __campaignStartDate;
        uint256 __campaignEndDate;
        uint256 __costEmittent;
        uint256 __coupure;
        uint256 __interestRate;
        uint256 __netReturn;
        uint256 __periodicInterestRate;
        uint256 __withholdingTax;
        uint256 __balloonRate;
        uint256 __issueDate;
        uint256 __maturityDate;
        uint256 __duration;
        uint256 __capitalAmortizationDuration;
        uint256 __gracePeriodDuration;
        uint256 __maxSupply;
        uint256 __reservedAmount;
        uint256 __maxAmountPerInvestor;
        uint256 __previousId;
        uint256 __investorsCount;
        uint256 __revocationsCount;
        uint256 __totalToBeRepaid;
        uint256 __issuedAmount;
        uint256 __currentLine;
        uint256 __nextInterestAmount;
        uint256 __nextCapitalAmount;
        bool __allClaimsReceived;
        bool __isSub;
        bool __initDone;
        bool __paused;
        bool __issued;
        bool __cancelled;
        uint256[] __grossCouponRates;
        uint256[] __couponDates;
        uint256[] __netCouponRates;
        uint256[] __capitalRepayment;
        uint256[] __remainingCapital;
        CouponStatus[] __couponStatus;
        mapping(address => bool) __isHolder;
        mapping(address => uint256) __reservedAmountByAddress;
        mapping(string => uint256) __reservedAmountByPurchaseId;
        Periodicity __periodicity;
        FormOfFinancing __formOfFinancing;
        MethodOfRepayment __methodOfRepayment;
        BondStatus __status;
        address __currencyAddress;
    }

    function bondStorage(
        uint256 slot
    ) internal pure returns (BondParams storage bs) {
        bytes32 bsSlot = keccak256(
            abi.encodePacked("storage.bond", Strings.toString(slot))
        );
        assembly {
            bs.slot := bsSlot
        }
    }
}
