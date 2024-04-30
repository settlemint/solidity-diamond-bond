// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library BondInitParams {
    struct BondInit {
        uint256 __bondId;
        uint256 __campaignMinAmount;
        uint256 __campaignMaxAmount;
        uint256 __campaignStartDate;
        uint256 __expectedIssueDate;
        uint256 __coupure;
        uint256 __interestNum;
        uint256 __interestDen;
        uint256 __withholdingTaxNum;
        uint256 __withholdingTaxDen;
        uint256 __balloonRateNum;
        uint256 __balloonRateDen;
        uint256 __duration;
        uint256 __capitalAmortizationDuration;
        uint256 __gracePeriodDuration;
        uint256 __maxAmountPerInvestor;
        uint256 __periodicity;
        uint256 __formOfFinancing;
        uint256 __methodOfRepayment;
    }
}
