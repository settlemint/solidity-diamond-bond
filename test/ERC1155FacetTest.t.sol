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

    function testBalanceOfBatch() public {
        address[] memory accounts = new address[](3);
        uint256[] memory ids = new uint256[](3);

        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        erc1155.mint(owner, tokenId1, 100);
        erc1155.mint(user1, tokenId1, 50);
        erc1155.mint(user2, tokenId2, 200);

        accounts[0] = owner;
        accounts[1] = user1;
        accounts[2] = user2;

        ids[0] = tokenId1;
        ids[1] = tokenId1;
        ids[2] = tokenId2;

        uint256[] memory balances = erc1155.balanceOfBatch(accounts, ids);

        assertEq(
            balances[0],
            100,
            "Balance of owner for tokenId1 should be 100"
        );
        assertEq(balances[1], 50, "Balance of user1 for tokenId1 should be 50");
        assertEq(
            balances[2],
            200,
            "Balance of user2 for tokenId2 should be 200"
        );
    }
    function testSupportsInterface() public {
        // ERC165 Interface ID for IERC165
        bytes4 interfaceIdERC165 = type(IERC165).interfaceId;
        // ERC165 Interface ID for IERC1155v2
        bytes4 interfaceIdERC1155v2 = type(IERC1155v2).interfaceId;
        // ERC165 Interface ID for non-supported interface (example)
        bytes4 interfaceIdNonSupported = 0xffffffff;

        assertTrue(
            erc1155.supportsInterface(interfaceIdERC165),
            "Should support IERC165 interface"
        );
        assertTrue(
            erc1155.supportsInterface(interfaceIdERC1155v2),
            "Should support IERC1155v2 interface"
        );
        assertFalse(
            erc1155.supportsInterface(interfaceIdNonSupported),
            "Should not support non-supported interface"
        );
    }
}
