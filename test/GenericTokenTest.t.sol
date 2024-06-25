// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/GenericToken.sol";

contract GenericTokenTest is Test {
    GenericToken token;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = vm.addr(1);
        user1 = vm.addr(2);
        user2 = vm.addr(3);

        vm.startPrank(owner);
        token = new GenericToken("GenericToken", "GEN");
        vm.stopPrank();
    }

    function testInitialSupply() public {
        uint256 initialSupply = token.totalSupply();
        assertEq(initialSupply, 1_000_000 * 10 ** token.decimals());
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** token.decimals();
        vm.prank(owner);
        token.mint(user1, mintAmount);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, mintAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 500 * 10 ** token.decimals();
        vm.prank(owner);
        token.mint(user1, burnAmount);

        vm.prank(user1);
        token.burn(burnAmount);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 0);
    }

    function testPauseAndUnpause() public {
        vm.prank(owner);
        token.pause();
        assertEq(token.paused(), true);
        vm.prank(owner);
        vm.expectRevert();
        token.mint(user1, 10);
        vm.prank(owner);
        token.unpause();
        assertEq(token.paused(), false);
        vm.prank(owner);
        token.mint(user1, 10);
    }

    function testTransfer() public {
        uint256 transferAmount = 200 * 10 ** token.decimals();
        vm.prank(owner);
        token.mint(user1, transferAmount);

        vm.prank(user1);
        token.transfer(user2, transferAmount);

        uint256 user1Balance = token.balanceOf(user1);
        uint256 user2Balance = token.balanceOf(user2);
        assertEq(user1Balance, 0);
        assertEq(user2Balance, transferAmount);
    }
}
