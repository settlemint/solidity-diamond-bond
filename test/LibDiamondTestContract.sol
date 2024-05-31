// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../contracts/DiamondTestContract.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamond.sol";

contract DiamondTest is Test {
    DiamondTestContract diamondTest;
    SecondFacet secondFacet;
    address owner = address(1);
    address newOwner = address(2);

    function setUp() public {
        diamondTest = new DiamondTestContract();
        diamondTest.setContractOwner(owner);
        secondFacet = new SecondFacet();
    }

    function testSetContractOwner() public {
        diamondTest.setContractOwner(newOwner);
        assertEq(
            diamondTest.contractOwner(),
            newOwner,
            "Contract owner should be newOwner"
        );
    }

    function testEnforceIsContractOwner() public {
        vm.prank(owner);
        diamondTest.enforceIsContractOwner();

        vm.prank(newOwner);
        vm.expectRevert();
        diamondTest.enforceIsContractOwner();
    }

    function testDiamondCut() public {
        // Create a mock facet cut
        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](
            1
        );
        diamondCut[0] = IDiamond.FacetCut({
            facetAddress: address(this),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: new bytes4[](1)
        });
        diamondCut[0].functionSelectors[0] = this.testDiamondCut.selector;

        // Perform the diamond cut
        vm.prank(owner);
        diamondTest.diamondCut(diamondCut, address(0), "");
    }

    function testDiamondCutDelete() public {
        // First, add a function to replace
        IDiamondCut.FacetCut[]
            memory diamondCutAdd = new IDiamondCut.FacetCut[](1);
        diamondCutAdd[0] = IDiamond.FacetCut({
            facetAddress: address(this),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: new bytes4[](1)
        });
        diamondCutAdd[0].functionSelectors[0] = this.validFunction.selector;

        vm.prank(owner);
        diamondTest.diamondCut(diamondCutAdd, address(0), "");

        // Now, replace the function
        IDiamondCut.FacetCut[]
            memory diamondCutDelete = new IDiamondCut.FacetCut[](1);
        diamondCutDelete[0] = IDiamond.FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: new bytes4[](1)
        });
        diamondCutDelete[0].functionSelectors[0] = this.validFunction.selector;

        vm.prank(owner);
        diamondTest.diamondCut(diamondCutDelete, address(0), "");
    }

    function testDiamondCutReplace() public {
        // First, add a function to replace
        IDiamondCut.FacetCut[]
            memory diamondCutAdd = new IDiamondCut.FacetCut[](1);
        diamondCutAdd[0] = IDiamond.FacetCut({
            facetAddress: address(secondFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: new bytes4[](1)
        });
        diamondCutAdd[0].functionSelectors[0] = this.validFunction.selector;

        vm.prank(owner);
        diamondTest.diamondCut(diamondCutAdd, address(0), "");

        // Now, replace the function
        IDiamondCut.FacetCut[]
            memory diamondCutDelete = new IDiamondCut.FacetCut[](1);
        diamondCutDelete[0] = IDiamond.FacetCut({
            facetAddress: address(this),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: new bytes4[](1)
        });
        diamondCutDelete[0].functionSelectors[0] = this.validFunction.selector;

        vm.prank(owner);
        diamondTest.diamondCut(diamondCutDelete, address(0), "");
    }

    function replacementFunction() external pure returns (string memory) {
        return "Replacement function called";
    }
    function validFunction() external pure returns (string memory) {
        return "Valid function called";
    }
}

contract SecondFacet {
    function validFunction() external pure returns (string memory) {
        return "Replacement function called";
    }
}
