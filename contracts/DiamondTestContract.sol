// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondCut.sol";

contract DiamondTestContract {
    using LibDiamond for *;

    function setContractOwner(address _newOwner) external {
        LibDiamond.setContractOwner(_newOwner);
    }

    function contractOwner() external view returns (address) {
        return LibDiamond.contractOwner();
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    function enforceIsContractOwner() external view {
        LibDiamond.enforceIsContractOwner();
    }
}
