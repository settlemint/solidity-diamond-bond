// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/facets/BondFacet.sol";
import "../contracts/facets/ERC1155Facet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/upgradeInitializers/DiamondInit.sol";
import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { BondInitParams } from "../contracts/libraries/StructBondInit.sol";
import "../contracts/interfaces/IDiamond.sol";
import "../contracts/GenericToken.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/BondStorage.sol";
import "../contracts/libraries/LibDiamond.sol";
import "../contracts/facets/BondReaderFacet.sol";
import "../contracts/facets/BondManagerFacet.sol";
import "../contracts/facets/CouponFacet.sol";

contract DiamondBondTest is Test {
    address owner;
    address issuer;
    address investor;
    address investor2;
    address erc1155FacetAddress;
    address diamondLoupeFacetAddress;
    address bondFacetAddress;
    address bondReaderFacetAddress;
    address ownershipFacetAddress;
    address bondManagerFacetAddress;
    address payable diamondAddress;
    address diamondInitAddress;
    address genericTokenAddress;
    address couponFacetAddress;

    IDiamondLoupe ILoupe;

    function setUp() public {
        owner = vm.addr(123);
        issuer = vm.addr(456);
        investor = vm.addr(789);
        investor2 = vm.addr(1011);
        vm.startPrank(owner);

        DiamondInit diamondInit = new DiamondInit();
        diamondInitAddress = address(diamondInit);

        ERC1155Facet erc1155Facet = new ERC1155Facet();
        erc1155FacetAddress = address(erc1155Facet);

        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        diamondLoupeFacetAddress = address(diamondLoupeFacet);

        BondFacet bondFacet = new BondFacet();
        bondFacetAddress = address(bondFacet);

        BondReaderFacet bondReaderFacet = new BondReaderFacet();
        bondReaderFacetAddress = address(bondReaderFacet);

        BondManagerFacet bondManagerFacet = new BondManagerFacet();
        bondManagerFacetAddress = address(bondManagerFacet);

        CouponFacet couponFacet = new CouponFacet();
        couponFacetAddress = address(couponFacet);

        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ownershipFacetAddress = address(ownershipFacet);

        GenericToken genericToken = new GenericToken("GenericToken", "GEN");
        genericTokenAddress = address(genericToken);

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](7);

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

        cuts[3] = IDiamond.FacetCut({
            facetAddress: ownershipFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ownershipFacet.getSelectorsOwnership()
        });

        cuts[4] = IDiamond.FacetCut({
            facetAddress: bondReaderFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: bondReaderFacet.getSelectors()
        });

        cuts[5] = IDiamond.FacetCut({
            facetAddress: bondManagerFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: bondManagerFacet.getSelectors()
        });

        cuts[6] = IDiamond.FacetCut({
            facetAddress: couponFacetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: couponFacet.getSelectors()
        });

        DiamondArgs memory da = DiamondArgs({
            owner: owner,
            init: diamondInitAddress,
            initCalldata: abi.encodeWithSelector(bytes4(keccak256("init()")))
        });

        Diamond diamond = new Diamond(cuts, da);
        diamondAddress = payable(address(diamond));

        OwnershipFacet(diamondAddress).initializeOwner(owner);

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
            __campaignMaxAmount: 100_000,
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

    function testRemoveFacet() public {
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);

        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: ERC1155Facet(erc1155FacetAddress).getSelectors()
        });

        vm.prank(owner);
        Diamond(diamondAddress).diamondCut(cuts, address(0), "");
        address[] memory addresses;
        addresses = DiamondLoupeFacet(diamondAddress).facetAddresses();
        assertEq(addresses.length, 6);
        vm.prank(owner);
        vm.expectRevert();
        ERC1155Facet(diamondAddress).balanceOf(owner, 1);
    }

    function testGetCouponDates() public view {
        uint256[] memory year;
        uint256[] memory month;
        uint256[] memory day;
        uint256[2] memory expectedYear = [uint256(1970), uint256(1971)];
        uint256[2] memory expectedMonth = [uint256(1), uint256(1)];
        uint256[2] memory expectedDay = [uint256(1), uint256(1)];

        (day, month, year) = BondReaderFacet(diamondAddress).getCouponsDates(1);
        for (uint256 i = 0; i < year.length; i++) {
            assertEq(year[i], expectedYear[i]);
            assertEq(month[i], expectedMonth[i]);
            assertEq(day[i], expectedDay[i]);
        }
    }

    function testGetCouponRates() public view {
        uint256[] memory gross;
        uint256[] memory net;
        uint256[] memory capital;
        uint256[] memory remainingCapital;
        (gross, net, capital, remainingCapital) = BondReaderFacet(diamondAddress).getCouponsRates(1);
    }

    function testFallbackFunction() public {
        // Test the fallback function by calling a non-existent function
        (bool success,) = address(diamondAddress).call(abi.encodeWithSignature("nonExistentFunction()"));
        assertFalse(success, "Fallback function should revert for non-existent function");
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
            __campaignMaxAmount: 100_000,
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
            __campaignMaxAmount: 100_000,
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
        vm.startPrank(owner);
        vm.expectRevert();
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 3;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 4;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__balloonRateNum = 10;
        params.__balloonRateDen = 100;
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Balloon);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 5;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__gracePeriodDuration = 2;
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.GracePeriod);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 6;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__gracePeriodDuration = 3;
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.GracePeriod);
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 7;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__gracePeriodDuration = 12;
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.GracePeriod);
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
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.WithCapitalAmortizationFreePeriod);
        params.__capitalAmortizationDuration = 12;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 11;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.WithCapitalAmortizationFreePeriod);
        params.__capitalAmortizationDuration = 2;
        vm.expectRevert();
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 12;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.WithCapitalAmortizationFreePeriod);
        params.__capitalAmortizationDuration = 11;
        vm.expectRevert();
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 13;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Bullet);
        params.__capitalAmortizationDuration = 0;

        params.__duration = 11;
        vm.expectRevert();
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 14;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Bullet);
        params.__duration = 11;
        vm.expectRevert();
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 15;
        params.__periodicity = uint256(BondStorage.Periodicity.Annual);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Degressive);
        params.__duration = 24;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 16;
        params.__periodicity = uint256(BondStorage.Periodicity.Quarterly);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Degressive);
        params.__duration = 24;
        BondFacet(diamondAddress).initializeBond(params);

        params.__bondId = 17;
        params.__periodicity = uint256(BondStorage.Periodicity.Monthly);
        params.__methodOfRepayment = uint256(BondStorage.MethodOfRepayment.Degressive);
        params.__duration = 24;
        BondFacet(diamondAddress).initializeBond(params);

        vm.stopPrank();
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
            __campaignMaxAmount: 100_000,
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
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
    }

    function testReserveBondsBeforeOrAfterCampaign() public {
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
            __campaignMaxAmount: 100_000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 5,
            __campaignStartDate: 2,
            __expectedIssueDate: 0,
            __balloonRateNum: 0,
            __balloonRateDen: 0,
            __capitalAmortizationDuration: 0,
            __gracePeriodDuration: 0,
            __formOfFinancing: uint256(BondStorage.FormOfFinancing.Bond),
            __issuer: issuer
        });
        BondFacet(diamondAddress).initializeBond(params);

        uint256 reserveAmount = 1;
        vm.prank(investor);
        vm.expectRevert();
        BondFacet(diamondAddress).reserve("bondPurchaseId", 2, reserveAmount, investor);
        vm.warp(4_000_000_000_000_000);
        vm.expectRevert();
        BondFacet(diamondAddress).reserve("bondPurchaseId", 2, reserveAmount, investor);
    }

    function testReserveMoreThanMax() public {
        uint256 reserveAmount = 5;
        vm.startPrank(investor);
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
        vm.expectRevert();
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
    }

    function testReserveWhenNotAvailable() public {
        uint256 bondId = 2;
        BondInitParams.BondInit memory params = BondInitParams.BondInit({
            __bondId: bondId,
            __coupure: 1000,
            __interestNum: 5,
            __interestDen: 100,
            __withholdingTaxNum: 10,
            __withholdingTaxDen: 100,
            __periodicity: uint256(BondStorage.Periodicity.Annual),
            __duration: 24,
            __methodOfRepayment: uint256(BondStorage.MethodOfRepayment.Bullet),
            __campaignMaxAmount: 100_000,
            __campaignMinAmount: 1000,
            __maxAmountPerInvestor: 100,
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
        uint256 reserveAmount = 100;
        vm.startPrank(investor);
        BondFacet(diamondAddress).reserve("bondPurchaseId", bondId, reserveAmount, investor);
        vm.startPrank(investor2);
        vm.expectRevert();
        BondFacet(diamondAddress).reserve("bondPurchaseId2", bondId, reserveAmount, investor2);
    }

    function testReserveAndRescind() public {
        // Call initializeBond using the deployed Diamond as the caller
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
        vm.prank(investor);
        BondFacet(diamondAddress).rescindReservation("bondPurchaseId", 1, investor);
    }

    function testIssueBonds() public {
        // Issue bonds

        // Call initializeBond using the deployed Diamond as the caller
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
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
        vm.warp(2_000_000_000);
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
            __campaignMaxAmount: 100_000,
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
        vm.expectEmit(true, true, true, true);
        emit BondManagerFacet.Cancelled(2);
        BondManagerFacet(diamondAddress).cancel(2);
    }

    function testWithdrawBonds() public {
        // Reserve bonds
        uint256 reserveAmount = 1;
        vm.prank(investor);
        BondFacet(diamondAddress).reserve("bondPurchaseId", 1, reserveAmount, investor);
        vm.prank(owner);
        BondFacet(diamondAddress).issueBond(1, 0);
        GenericToken(genericTokenAddress).mint(investor, 1000 * 10 ** 18);
        vm.prank(investor);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);

        // Withdraw bonds
        vm.prank(owner);
        BondFacet(diamondAddress).withdrawBondsPurchased("bondPurchaseId", 1, investor);
    }

    function testClaimAndWithdrawCoupon() public {
        vm.startPrank(investor);
        BondFacet(diamondAddress).reserve("bp1", 1, 1, investor);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        vm.stopPrank();
        vm.startPrank(owner);
        BondFacet(diamondAddress).issueBond(1, 0);
        GenericToken(genericTokenAddress).mint(investor, 10_000 * 10 ** 18);
        GenericToken(genericTokenAddress).mint(issuer, 10_000 * 10 ** 18);
        vm.stopPrank();
        vm.startPrank(investor);
        BondFacet(diamondAddress).withdrawBondsPurchased("bp1", 1, investor);
        CouponFacet(diamondAddress).claimCoupon(1, investor);
        vm.stopPrank();
        vm.prank(issuer);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        vm.prank(issuer);
        CouponFacet(diamondAddress).withdrawCouponClaim(1, investor);
    }

    function testWithdrawCouponBeforeAllClaimsReceived() public {
        vm.startPrank(investor);
        BondFacet(diamondAddress).reserve("bp1", 1, 1, investor);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        vm.stopPrank();
        vm.startPrank(investor2);
        BondFacet(diamondAddress).reserve("bp2", 1, 1, investor2);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        vm.stopPrank();
        vm.startPrank(owner);
        BondFacet(diamondAddress).issueBond(1, 0);
        GenericToken(genericTokenAddress).mint(investor, 10_000 * 10 ** 18);
        GenericToken(genericTokenAddress).mint(investor2, 10_000 * 10 ** 18);
        GenericToken(genericTokenAddress).mint(issuer, 10_000 * 10 ** 18);
        BondFacet(diamondAddress).withdrawBondsPurchased("bp1", 1, investor);
        BondFacet(diamondAddress).withdrawBondsPurchased("bp2", 1, investor2);
        CouponFacet(diamondAddress).claimCoupon(1, investor);
        vm.startPrank(issuer);
        GenericToken(genericTokenAddress).approve(diamondAddress, UINT256_MAX);
        vm.expectRevert();
        CouponFacet(diamondAddress).withdrawCouponClaim(1, investor);
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
        diamondSelectors = DiamondLoupeFacet(diamondAddress).facetFunctionSelectors(erc1155FacetAddress);
        facetSelectors = ERC1155Facet(erc1155FacetAddress).getSelectors();
        assertEq(diamondSelectors[0], facetSelectors[0]);
    }

    function testLoupeFacets() public view {
        IDiamondLoupe.Facet memory facet = IDiamondLoupe.Facet({
            facetAddress: erc1155FacetAddress,
            functionSelectors: ERC1155Facet(erc1155FacetAddress).getSelectors()
        });
        IDiamondLoupe.Facet[] memory diamondFacets = DiamondLoupeFacet(diamondAddress).facets();

        assertEq(facet.facetAddress, diamondFacets[0].facetAddress);
    }

    function testAddressOfSelector() public {
        vm.startPrank(owner);
        bytes4[] memory facetSelectors;
        address facetAddress;
        facetSelectors = ERC1155Facet(erc1155FacetAddress).getSelectors();
        facetAddress = DiamondLoupeFacet(diamondAddress).facetAddress(facetSelectors[4]);
        assertEq(facetAddress, erc1155FacetAddress);
    }

    function testFacetLoupeSupportsInterface() public view {
        bytes4 interfaceIdERC165 = type(IERC165).interfaceId;
        assertTrue(
            DiamondLoupeFacet(diamondAddress).supportsInterface(interfaceIdERC165), "Should support IERC165 interface"
        );
    }

    function testDiamaondReceivesEth() public {
        diamondAddress.transfer(1 ether);
    }

    function testFallback() public {
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");
        (bool success,) = address(diamondAddress).call(data);
        assertFalse(success, "Fallback should revert for non-existent function");
    }

    function testTransferBond() public {
        // Approve the new account to transfer tokens
        uint256 transferAmount = 2;
        uint256 initialAmount = 5;
        uint256 bondId = 1;
        uint256 coupure = 1000;
        vm.startPrank(owner);
        GenericToken(genericTokenAddress).mint(investor2, transferAmount * coupure);
        GenericToken(genericTokenAddress).mint(investor, initialAmount * coupure);
        vm.stopPrank();
        vm.startPrank(investor);
        GenericToken(genericTokenAddress).approve(diamondAddress, initialAmount * coupure);
        BondFacet(diamondAddress).reserve("bondPurchaseId", bondId, initialAmount, investor);
        vm.stopPrank();
        vm.startPrank(owner);
        BondFacet(diamondAddress).issueBond(bondId, 0);
        BondFacet(diamondAddress).withdrawBondsPurchased("bondPurchaseId", bondId, investor);

        vm.stopPrank();
        vm.prank(investor2);
        GenericToken(genericTokenAddress).approve(diamondAddress, transferAmount * coupure);

        // Transfer the bond
        vm.prank(investor);
        ERC1155Facet(diamondAddress).setApprovalForAll(diamondAddress, true);
        vm.prank(owner);
        BondFacet(diamondAddress).transferBond("transfer1", bondId, investor, investor2, transferAmount);

        // Check balances
        assertEq(ERC1155Facet(diamondAddress).balanceOf(investor, bondId), initialAmount - transferAmount);
        assertEq(ERC1155Facet(diamondAddress).balanceOf(investor2, bondId), transferAmount);
    }

    function testTerminateBond() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit BondManagerFacet.BondTerminated(1);
        BondManagerFacet(diamondAddress).terminate(1);
    }
}
