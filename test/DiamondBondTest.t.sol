// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/facets/BondFacet.sol";
import "../src/facets/ERC1155Facet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/Diamond.sol";
import "../src/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {BondInitParams} from "../src/libraries/StructBondInit.sol";
import "../src/interfaces/IDiamond.sol";

contract DiamondBondTest is Test {
    address ownership;
    address owner;
    address diamondCutAddress;
    address erc1155FacetAddress;
    address diamondLoupeFacetAddress;
    address bondFacetAddress;
    address diamondAddress;
    address diamondInitAddress;

    IDiamondLoupe ILoupe;

    function setUp() public {
        owner = vm.addr(123);
        vm.startPrank(owner);
        DiamondCutFacet diamondCut = new DiamondCutFacet();
        diamondCutAddress = address(diamondCut);

        DiamondInit diamondInit = new DiamondInit();
        diamondInitAddress = address(diamondInit);

        ERC1155Facet erc1155Facet = new ERC1155Facet();
        erc1155FacetAddress = address(erc1155Facet);

        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        diamondLoupeFacetAddress = address(diamondLoupeFacet);

        BondFacet bondFacet = new BondFacet();
        bondFacetAddress = address(bondFacet);

        //Diamond diamond = new Diamond(owner, diamondCutAddress);

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        cuts[0] = IDiamond.FacetCut({
            facetAddress: erc1155FacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: erc1155Facet.getSelectors()
        });

        cuts[1] = IDiamond.FacetCut({
            facetAddress: diamondLoupeFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: diamondLoupeFacet.getSelectors()
        });

        cuts[2] = IDiamond.FacetCut({
            facetAddress: bondFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: bondFacet.getSelectors()
        });

        DiamondArgs memory da = DiamondArgs({
            owner: owner,
            init: diamondInitAddress,
            initCalldata: abi.encodeWithSelector(bytes4(keccak256("init()")))
        });

        Diamond diamond = new Diamond(cuts, da);
        diamondAddress = address(diamond);

        // Assign diamond address to a state variable for further testing
        vm.stopPrank();
    }

    function testInitializeBond() public {
        // Create mock parameters for initializing a bond
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: 1,
            __coupure: 1000,
            __interestNum: 5,
            __interestDen: 100,
            __withholdingTaxNum: 10,
            __withholdingTaxDen: 100,
            __periodicity: uint256(BondStorage.Periodicity.Annual),
            __duration: 24,
            __methodOfRepayment: uint256(BondStorage.MethodOfRepayment.Bullet),
            __campaignMaxAmount: 100000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 5000,
            __campaignStartDate: 1713603094,
            __expectedIssueDate: 1716195094,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond)
        });

        // Call initializeBond using the deployed Diamond as the caller
        vm.prank(owner);
        BondFacet(diamondAddress).initializeBond(params);
    }
}
