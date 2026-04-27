//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FlatCoin} from "../../src/FlatCoin.sol";

contract TestFlatCoin is Test {
    FlatCoin flatCoin;

    address USER = makeAddr("user");

    uint256 public constant INITIAL_SUPPLY = 10e18;
    uint256 public constant BURN_AMOUNT = 2e18;

    function setUp() public {
        flatCoin = new FlatCoin();
    }

    function testTokenName() public view {
        assertEq(flatCoin.name(), "FlatCoin");
    }

    function testTokenSymbol() public view {
        assertEq(flatCoin.symbol(), "FC");
    }

    function testPauseToken() public {
        flatCoin.pause();
        vm.startPrank(USER);
        vm.expectRevert();
        flatCoin.mint(USER, INITIAL_SUPPLY);
        vm.stopPrank();
    }

    function testUnpauseToken() public {
        flatCoin.pause();

        vm.startPrank(USER);
        vm.expectRevert();
        flatCoin.mint(USER, INITIAL_SUPPLY);
        vm.stopPrank();

        flatCoin.unpause();

        vm.startPrank(USER);
        flatCoin.mint(USER, INITIAL_SUPPLY);
        vm.stopPrank();
    }

    function testAnyoneCanMintToken() public {
        vm.startPrank(USER);
        flatCoin.mint(USER, INITIAL_SUPPLY);
        vm.stopPrank();

        assertEq(flatCoin.balanceOf(USER), INITIAL_SUPPLY);
    }

    function testAnyoneCanBurnToken() public {
        vm.startPrank(USER);
        flatCoin.mint(USER, INITIAL_SUPPLY);
        flatCoin.burn(USER, BURN_AMOUNT);
        vm.stopPrank();

        assertEq(flatCoin.balanceOf(USER), (INITIAL_SUPPLY - BURN_AMOUNT));
    }
}
