// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FlatCoinEngine} from "../../src/FlatCoinEngine.sol";
import {FlatCoin} from "../../src/FlatCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../../test/mock/MockV3Aggregator.sol";

contract FlatCoinEngineTest is Test {
    FlatCoinEngine engine;
    FlatCoin flatCoin;
    HelperConfig config;

    address weth;
    address wbtc;
    address priceFeed;

    address USER = address(1);
    address LIQUIDATOR = address(2);

    uint256 constant STARTING_BALANCE = 1000e18;
    uint256 constant DEPOSIT_AMOUNT = 100e18;
    uint256 constant MINT_AMOUNT = 30000e18;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        config = new HelperConfig();
        HelperConfig.NetworkConfig memory net = config.activeNetworkConfig();

        flatCoin = new FlatCoin();
        engine = new FlatCoinEngine(address(flatCoin), address(this));
        flatCoin.setEngine(address(engine));

        weth = net.collateralTokens[0];
        wbtc = net.collateralTokens[1];
        priceFeed = net.priceFeeds[0];

        // Configure engine
        engine.addCollateral(weth, net.priceFeeds[0], 80, 10);
        engine.addCollateral(wbtc, net.priceFeeds[1], 75, 12);

        // Fund users
        ERC20Mock(weth).mint(USER, STARTING_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositCollateral() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        assertEq(engine.getCollateral(USER, weth), DEPOSIT_AMOUNT);

        vm.stopPrank();
    }

    function testRevertIfDepositZero() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);

        vm.expectRevert();
        engine.deposit(weth, 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        MINT TESTS
    //////////////////////////////////////////////////////////////*/

    function testMintFlatCoin() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        engine.mint(MINT_AMOUNT);

        assertEq(flatCoin.balanceOf(USER), MINT_AMOUNT);

        vm.stopPrank();
    }

    function testRevertIfHealthFactorBrokenOnMint() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        // Try to mint near max
        uint256 unsafeMint = 160_000e18; // exceeds safe borrow

        vm.expectRevert();
        engine.mint(unsafeMint);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function testBurnReducesDebt() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        engine.mint(MINT_AMOUNT);

        flatCoin.approve(address(engine), MINT_AMOUNT);
        engine.burn(MINT_AMOUNT);

        assertEq(flatCoin.balanceOf(USER), 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawCollateral() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        engine.withdraw(weth, DEPOSIT_AMOUNT);

        assertEq(engine.getCollateral(USER, weth), 0);

        vm.stopPrank();
    }

    function testRevertWithdrawIfBreaksHealthFactor() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        engine.mint(MINT_AMOUNT);

        vm.expectRevert();
        engine.withdraw(weth, DEPOSIT_AMOUNT);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        HEALTH FACTOR
    //////////////////////////////////////////////////////////////*/

    function testHealthFactorImprovesWithMoreCollateral() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), 200e18);
        engine.deposit(weth, 200e18);

        engine.mint(MINT_AMOUNT);

        uint256 hf = engine.getHealthFactor(USER);

        assertGt(hf, 1e18);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        INTEREST TESTS
    //////////////////////////////////////////////////////////////*/

    function testInterestAccrualIncreasesDebt() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);

        engine.mint(MINT_AMOUNT);

        uint256 debtBefore = engine.getDebt(USER);

        vm.warp(block.timestamp + 365 days);

        // 🔥 Fix: refresh oracle so it's not stale
        MockV3Aggregator(priceFeed).updateAnswer(2000e8);

        engine.mint(1); // triggers accrue

        uint256 debtAfter = engine.getDebt(USER);

        assertGt(debtAfter, debtBefore);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testLiquidationAfterPriceCrash() public {
        // USER opens position
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.deposit(weth, DEPOSIT_AMOUNT);
        engine.mint(MINT_AMOUNT);
        vm.stopPrank();

        // Simulate price crash
        MockV3Aggregator(priceFeed).updateAnswer(500e8); // ETH drops from 2000 → 500

        // Liquidator gets FC
        vm.startPrank(USER);
        flatCoin.transfer(LIQUIDATOR, MINT_AMOUNT);
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        flatCoin.approve(address(engine), MINT_AMOUNT);

        engine.liquidate(USER, weth, MINT_AMOUNT);

        vm.stopPrank();

        uint256 userCollateral = engine.getCollateral(USER, weth);
        assertLt(userCollateral, DEPOSIT_AMOUNT);
    }
}
