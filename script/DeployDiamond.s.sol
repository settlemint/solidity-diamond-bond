// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/facets/BondFacet.sol";
import "../src/facets/ERC1155Facet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/Diamond.sol";
import "../src/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {BondInitParams} from "../src/libraries/StructBondInit.sol";
import "../src/interfaces/IDiamond.sol";
import "../src/GenericToken.sol";

contract DeployDiamondScript is Script {
    function run() public {
        vm.startBroadcast();
        address owner = msg.sender;
        console.log(owner);

        DiamondCutFacet diamondCut = new DiamondCutFacet();
        address diamondCutAddress = address(diamondCut);

        DiamondInit diamondInit = new DiamondInit();
        address diamondInitAddress = address(diamondInit);

        ERC1155Facet erc1155Facet = new ERC1155Facet();
        address erc1155FacetAddress = address(erc1155Facet);

        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        address diamondLoupeFacetAddress = address(diamondLoupeFacet);

        BondFacet bondFacet = new BondFacet();
        address bondFacetAddress = address(bondFacet);

        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](3);
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
        address diamondAddress = address(diamond);

        new GenericToken("GenericToken", "GT");

        vm.stopBroadcast();
    }
}
