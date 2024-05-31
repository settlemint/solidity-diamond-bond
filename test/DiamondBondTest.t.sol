// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/facets/BondFacet.sol";
import "../contracts/facets/ERC1155Facet.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import {BondInitParams} from "../contracts/libraries/StructBondInit.sol";
import "../contracts/interfaces/IDiamond.sol";
import "../contracts/GenericToken.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";

contract DiamondBondTest is Test {
    address owner;
    address issuer;
    address investor;
    address diamondCutAddress;
    address erc1155FacetAddress;
    address diamondLoupeFacetAddress;
    address bondFacetAddress;
    address diamondAddress;
    address diamondInitAddress;
    address genericTokenAddress;

    IDiamondLoupe ILoupe;

    function setUp() public {
        owner = vm.addr(123);
        issuer = vm.addr(456);
        investor = vm.addr(789);
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

        GenericToken genericToken = new GenericToken("GenericToken", "GEN");
        genericTokenAddress = address(genericToken);

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

        // Set the currency address in BondFacet
        BondFacet(diamondAddress).setCurrencyAddress(genericTokenAddress);

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
            __maxAmountPerInvestor: 5,
            __campaignStartDate: 0,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        BondFacet(diamondAddress).initializeBond(params);
        vm.stopPrank();
    }

    function testEditBondParameters() public {
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: 1,
            __coupure: 1000,
            __interestNum: 6,
            __interestDen: 100,
            __withholdingTaxNum: 10,
            __withholdingTaxDen: 100,
            __periodicity: uint256(BondStorage.Periodicity.Annual),
            __duration: 24,
            __methodOfRepayment: uint256(BondStorage.MethodOfRepayment.Bullet),
            __campaignMaxAmount: 100000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 5,
            __campaignStartDate: 0,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        vm.prank(owner);
        BondFacet(diamondAddress).editBondParameters(params);
    }

    function testInitializeCampaigns() public {
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: 2,
            __coupure: 1000,
            __interestNum: 6,
            __interestDen: 100,
            __withholdingTaxNum: 10,
            __withholdingTaxDen: 100,
            __periodicity: uint256(BondStorage.Periodicity.Monthly),
            __duration: 24,
            __methodOfRepayment: uint256(BondStorage.MethodOfRepayment.Bullet),
            __campaignMaxAmount: 100000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 5,
            __campaignStartDate: 0,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        vm.startPrank(owner);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 3;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 4;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__balloonRateNum = 10;
        params.__balloonRateDen = 100;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 5;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__gracePeriodDuration = 2;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 6;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__gracePeriodDuration = 3;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 7;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__gracePeriodDuration = 12;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 8;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__capitalAmortizationDuration = 2;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 9;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__capitalAmortizationDuration = 3;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 10;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__capitalAmortizationDuration = 12;
        BondFacet(diamondAddress).initializeBond(params);
    }

    function testEditBondParametersWhenBondIsIssued() public {
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: 1,
            __coupure: 1000,
            __interestNum: 6,
            __interestDen: 100,
            __withholdingTaxNum: 10,
            __withholdingTaxDen: 100,
            __periodicity: uint256(BondStorage.Periodicity.Annual),
            __duration: 24,
            __methodOfRepayment: uint256(BondStorage.MethodOfRepayment.Bullet),
            __campaignMaxAmount: 100000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 5,
            __campaignStartDate: 0,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        vm.startPrank(owner);
        BondFacet(diamondAddress).issueBond(1, 2);
        vm.expectRevert();
        BondFacet(diamondAddress).editBondParameters(params);
    }

    function testReserveBonds() public {
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
    }

    function testReserveMoreThanMax() public {
        uint256 reserveAmount = 5;
        vm.startPrank(investor);
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
        vm.expectRevert();
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
    }

    function testReserveAndRescind() public {
        // Call initializeBond using the deployed Diamond as the caller
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
        vm.prank(investor);
        BondFacet(diamondAddress).rescindReservation(
            "bondPurchaseId",
            1,
            investor
        );
    }

    function testIssueBonds() public {
        // Issue bonds

        // Call initializeBond using the deployed Diamond as the caller
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
        vm.prank(owner);
        BondFacet(diamondAddress).issueBond(1, 0);
    }

    function testPauseUnpause() public {
        vm.startPrank(owner);
        BondFacet(diamondAddress).pauseCampaign(1);
        BondFacet(diamondAddress).unpauseCampaign(1);
        vm.stopPrank();
    }

    function testBuyingAfterCampaignEnds() public {
        vm.startPrank(investor);
        vm.warp(2000000000);
        vm.expectRevert();
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, 1, investor);
    }

    function testCancelCampaign() public {
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: 2,
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
            __campaignStartDate: 0,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        BondFacet(diamondAddress).initializeBond(params);
        BondFacet(diamondAddress).cancel(2);
    }

    function testWithdrawBonds() public {
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve(
            "bondPurchaseId",
            1,
            reserveAmount,
            investor
        );
        vm.prank(owner);
        BondFacet(diamondAddress).issueBond(1, 0);
        GenericToken(genericTokenAddress).mint(investor, 1000 * 10 ** 18);
        vm.prank(investor);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);

        // Withdraw bonds
        vm.prank(owner);
        BondFacet(diamondAddress).withdrawBondsPurchased(
            "bondPurchaseId",
            1,
            investor
        );
    }

    function testClaimCoupon() public {
        vm.prank(investor);
        BondFacet(diamondAddress).claimCoupon(1, investor);
    }

    function testWithdrawCoupon() public {
        vm.prank(investor);
        BondFacet(diamondAddress).claimCoupon(1, investor);
        vm.prank(owner);
        GenericToken(genericTokenAddress).mint(investor, 10000 * 10 ** 18);
        vm.startPrank(issuer);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        BondFacet(diamondAddress).withdrawCouponClaim(1, investor);
        vm.stopPrank();
    }

    function testLoupeFacetAddresses() public {
        vm.prank(owner);
        address[] memory addresses;
        addresses = DiamondLoupeFacet(diamondAddress).facetAddresses();
        assertEq(addresses[0], erc1155FacetAddress);
        assertEq(addresses[1], diamondLoupeFacetAddress);
        assertEq(addresses[2], bondFacetAddress);
    }

    function testLoupeSselectors() public {
        vm.prank(owner);
        bytes4[] memory diamondSelectors;
        bytes4[] memory facetSelectors;
        diamondSelectors = DiamondLoupeFacet(diamondAddress)
            .facetFunctionSelectors(erc1155FacetAddress);
        facetSelectors = ERC1155Facet(erc1155FacetAddress).getSelectors();
        assertEq(diamondSelectors[0], facetSelectors[0]);
    }

    function testLoupeFacets() public {
        IDiamondLoupe.Facet memory facet = IDiamondLoupe.Facet({
            facetAddress: erc1155FacetAddress,
            functionSelectors: ERC1155Facet(erc1155FacetAddress).getSelectors()
        });
        IDiamondLoupe.Facet[] memory diamondFacets = DiamondLoupeFacet(
            diamondAddress
        ).facets();

        assertEq(facet.facetAddress, diamondFacets[0].facetAddress);
    }
}
