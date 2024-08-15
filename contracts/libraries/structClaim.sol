// SPDX-License-Identifier: FSL-1.1-MIT
pragma solidity ^0.8.24;

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
