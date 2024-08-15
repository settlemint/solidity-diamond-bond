// SPDX-License-Identifier: FSL-1.1-MIT
pragma solidity ^0.8.24;

import "@prb/math/src/UD60x18.sol";
import { BondStorage } from "./BondStorage.sol";

contract BondManagerFacet is BondStorage {
    event BondTerminated(uint256 bondId);
    event Cancelled(uint256 bondId);

    function terminate(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        _bondDetails.__status = BondStatus.Terminated;
        emit BondTerminated(_bondId);
    }

    function cancel(uint256 _bondId) external {
        BondParams storage _bondDetails = bondStorage(_bondId);

        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        _bondDetails.__cancelled = true;
        //_bondDetails2.__cancelled = true;
        emit Cancelled(_bondId);
    }

    function getSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = BondManagerFacet.terminate.selector;
        selectors[1] = BondManagerFacet.cancel.selector;
        return selectors;
    }
}
