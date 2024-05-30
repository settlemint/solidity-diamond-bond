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
        vm.stopPrank();
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
}
