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

    function testAnyoneCannotBurnToken() public {
        vm.startPrank(USER);

        vm.expectRevert(FlatCoin.FlatCoin__NotEngine.selector);
        flatCoin.burn(USER, 2e18);

        vm.stopPrank();
    }
}
