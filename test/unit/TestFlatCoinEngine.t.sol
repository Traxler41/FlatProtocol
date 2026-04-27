//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FlatCoin} from "../../src/FlatCoin.sol";
import {FlatCoinEngine} from "../../src/FlatCoinEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {MockV3Aggregator} from "../../test/mock/MockV3Aggregator.sol";

contract TestFlatCoinEngine is Test {
    FlatCoin flatCoin;
    FlatCoinEngine flatCoinEngine;
    HelperConfig helperConfig;
    address priceFeed;

    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint256 public constant FUND_AMOUNT = 5 ether;
    uint256 public constant MINT_AMOUNT = 3000e18;
    uint256 public constant BROKEN_MINT_AMOUNT = 10000 ether;
    uint256 public constant LIQUIDATOR_FUND = 2 ether;

    address USER = makeAddr("user");
    address LIQUIDATOR = makeAddr("liquidator");

    function setUp() public {
        flatCoin = new FlatCoin();
        helperConfig = new HelperConfig();
        (, priceFeed) = helperConfig.activeNetworkConfig();
        flatCoinEngine = new FlatCoinEngine(priceFeed, address(flatCoin));

        vm.deal(USER, INITIAL_BALANCE);
        vm.deal(LIQUIDATOR, INITIAL_BALANCE);
    }

    function testCanStakeAssets() public {
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: FUND_AMOUNT}();
        vm.stopPrank();

        assertEq(flatCoinEngine.getCollateralStaked(USER), FUND_AMOUNT);
    }

    function testCanStakeAssetsAndMint() public {
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: FUND_AMOUNT}();
        flatCoinEngine.mintCoins(MINT_AMOUNT);
        vm.stopPrank();

        assertEq(flatCoin.balanceOf(USER), MINT_AMOUNT);
    }

    function testCannotMintExcessTokens() public {
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: FUND_AMOUNT}();
        vm.expectRevert();
        flatCoinEngine.mintCoins(BROKEN_MINT_AMOUNT);
    }

    function testHealthFactor() public {
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: FUND_AMOUNT}();
        flatCoinEngine.mintCoins(MINT_AMOUNT);
        vm.stopPrank();

        console.log("HEALTH FACTOR=", flatCoinEngine.getHealthFactor(USER));
    }

    function testCanLiquidate() public {
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: FUND_AMOUNT}();
        flatCoinEngine.mintCoins(MINT_AMOUNT);
        flatCoin.transfer(LIQUIDATOR, 1000e18);
        vm.stopPrank();

        MockV3Aggregator(address(priceFeed)).updateAnswer(400e8);

        uint256 userHealthFactorBefore = flatCoinEngine.getHealthFactor(USER);
        console.log("Health Factor Before Liquidation:", userHealthFactorBefore);
        assert(userHealthFactorBefore < 1e18);

        vm.startPrank(LIQUIDATOR);
        flatCoin.approve(address(flatCoinEngine), 1000e18); // Approve engine to burn
        flatCoinEngine.liquidate(USER, 1000e18); // Liquidate 1000 debt
        vm.stopPrank();

        assert(flatCoinEngine.getHealthFactor(USER) > 1e18);
    }
}
