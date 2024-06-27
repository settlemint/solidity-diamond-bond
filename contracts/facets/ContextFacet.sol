// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ContextFacet {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    // You might also want to implement _msgData()
    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}