// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../contracts/facets/ERC1155Facet.sol";

contract ERC1155FacetTest is Test {
    ERC1155Facet erc1155;
    address owner;
    address user1;
    address user2;
    address operator;

    function setUp() public {
        owner = vm.addr(1);
        user1 = vm.addr(2);
        user2 = vm.addr(3);
        operator = vm.addr(4);

        vm.prank(owner);
        erc1155 = new ERC1155Facet();
    }

    function testMint() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        vm.prank(owner);
        erc1155.mint(user1, tokenId, amount);

        uint256 user1Balance = erc1155.balanceOf(user1, tokenId);
        assertEq(user1Balance, amount);
    }

    function testBurn() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        vm.prank(owner);
        erc1155.mint(user1, tokenId, amount);

        vm.prank(user1);
        erc1155.burn(user1, tokenId, amount);

        uint256 user1Balance = erc1155.balanceOf(user1, tokenId);
        assertEq(user1Balance, 0);
    }

    function testSafeTransferFrom() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        vm.prank(owner);
        erc1155.mint(user1, tokenId, amount);

        vm.prank(user1);
        erc1155.safeTransferFrom(user1, user2, tokenId, amount, "");

        uint256 user1Balance = erc1155.balanceOf(user1, tokenId);
        uint256 user2Balance = erc1155.balanceOf(user2, tokenId);
        assertEq(user1Balance, 0);
        assertEq(user2Balance, amount);
    }

    function testSafeBatchTransferFrom() public {
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(owner);
        erc1155.mint(user1, tokenIds[0], amounts[0]);
        erc1155.mint(user1, tokenIds[1], amounts[1]);

        vm.prank(user1);
        erc1155.safeBatchTransferFrom(user1, user2, tokenIds, amounts, "");

        uint256 user1Balance1 = erc1155.balanceOf(user1, tokenIds[0]);
        uint256 user1Balance2 = erc1155.balanceOf(user1, tokenIds[1]);
        uint256 user2Balance1 = erc1155.balanceOf(user2, tokenIds[0]);
        uint256 user2Balance2 = erc1155.balanceOf(user2, tokenIds[1]);
        assertEq(user1Balance1, 0);
        assertEq(user1Balance2, 0);
        assertEq(user2Balance1, amounts[0]);
        assertEq(user2Balance2, amounts[1]);
    }

    function testSetApprovalForAll() public {
        vm.prank(user1);
        erc1155.setApprovalForAll(user1, operator, true);

        bool isApproved = erc1155.isApprovedForAll(user1, operator);
        assertTrue(isApproved);
    }
}