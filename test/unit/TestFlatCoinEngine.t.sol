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
        // 1. Setup: User deposits 5 ETH ($10k) and mints 3k FC 0.8) / 3,000 = 2.66 (Healthy)
        vm.startPrank(USER);
        flatCoinEngine.stakeCollateral{value: 5 ether}();
        flatCoinEngine.mintCoins(3000 ether);

        // Give Liquidator enough tokens to pay half the debt
        uint256 debtToCover = 1500 ether;
        flatCoin.transfer(LIQUIDATOR, debtToCover);
        vm.stopPrank();

        // 2. Price Crash: ETH drops to $700700 * 0.8) / 3,000 = 0.93 (Liquidatable!)
        MockV3Aggregator(address(priceFeed)).updateAnswer(700e8);

        uint256 hfBefore = flatCoinEngine.getHealthFactor(USER);
        console.log("Health Factor Before:", hfBefore);
        assert(hfBefore < 1e18);

        // 3. Execution: Liquidator pays off 1,500 FC debt
        vm.startPrank(LIQUIDATOR);
        flatCoin.approve(address(flatCoinEngine), debtToCover);
        flatCoinEngine.liquidate(USER, debtToCover);
        vm.stopPrank();

        // 4. Assertions
        uint256 hfAfter = flatCoinEngine.getHealthFactor(USER);
        console.log("Health Factor After:", hfAfter);

        // Health Factor must have improved significantly
        assert(hfAfter > hfBefore);

        // User debt should be reduced
        assertEq(flatCoinEngine.getMintedAmount(USER), 1500 ether);

        // Liquidator should have earned ETH (Debt + 10% Bonus)
        // 1500 USD / 700 = 2.14 ETH + 10% bonus = ~2.35 ETH
        uint256 liquidatorCollateral = flatCoinEngine.getCollateralStaked(LIQUIDATOR);
        assert(liquidatorCollateral > 0);
        console.log("Liquidator earned ETH:", liquidatorCollateral);
    }
}

