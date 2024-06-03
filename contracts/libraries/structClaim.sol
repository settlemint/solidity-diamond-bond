// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library ClaimParams {
    struct Claim {
        string claimId;
        uint256 bondId;
        uint256 amount;
        bytes32 hashLockWithdrawPayment;
        uint256 withdrawPaymentTimestampEnd;
        address beneficiary;
    }
}
