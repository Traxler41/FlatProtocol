// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FlatCoinEngine} from "../../src/FlatCoinEngine.sol";
import {FlatCoin} from "../../src/FlatCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract FlatCoinInteractionTest is Test {
    FlatCoinEngine engine;
    FlatCoin flatCoin;
    HelperConfig config;

    address USER = address(1);
    address LIQUIDATOR = address(2);

    address weth;
    address priceFeed;

    uint256 constant STARTING_BALANCE = 1000e18;

    function setUp() public {
        config = new HelperConfig();
        HelperConfig.NetworkConfig memory net = config.activeNetworkConfig();

        flatCoin = new FlatCoin();
        engine = new FlatCoinEngine(address(flatCoin), address(this));

        flatCoin.setEngine(address(engine));

        weth = net.collateralTokens[0];
        priceFeed = net.priceFeeds[0];

        engine.addCollateral(weth, priceFeed, 80, 10);

        // fund users
        ERC20Mock(weth).mint(USER, STARTING_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                        FULL USER FLOW
    //////////////////////////////////////////////////////////////*/

    function testFullLifecycle() public {
        vm.startPrank(USER);

        // 1. Deposit
        ERC20Mock(weth).approve(address(engine), 100e18);
        engine.deposit(weth, 100e18);

        // 2. Mint
        engine.mint(10_000e18);

        // 3. Health Factor check
        uint256 hf = engine.getHealthFactor(USER);
        assertGt(hf, 1e18);

        // 4. Partial Withdraw
        engine.withdraw(weth, 10e18);

        vm.stopPrank();

        // 5. Price Crash
        MockV3Aggregator(priceFeed).updateAnswer(300e8);

        // 6. Liquidation
        vm.startPrank(USER);
        flatCoin.transfer(LIQUIDATOR, 10_000e18);
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        flatCoin.approve(address(engine), 10_000e18);

        engine.liquidate(USER, weth, 5_000e18);
        vm.stopPrank();

        // 7. Check position reduced
        uint256 remainingCollateral = engine.getCollateral(USER, weth);
        assertLt(remainingCollateral, 90e18);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI USER INTERACTION
    //////////////////////////////////////////////////////////////*/

    function testMultipleUsersDoNotAffectEachOther() public {
        address USER2 = address(3);

        ERC20Mock(weth).mint(USER2, STARTING_BALANCE);

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), 100e18);
        engine.deposit(weth, 100e18);
        engine.mint(5_000e18);
        vm.stopPrank();

        vm.startPrank(USER2);
        ERC20Mock(weth).approve(address(engine), 50e18);
        engine.deposit(weth, 50e18);
        engine.mint(2_000e18);
        vm.stopPrank();

        assertGt(engine.getHealthFactor(USER), 1e18);
        assertGt(engine.getHealthFactor(USER2), 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                        STRESS TEST
    //////////////////////////////////////////////////////////////*/

    function testRepeatedMintBurnCycle() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(engine), 100e18);
        engine.deposit(weth, 100e18);

        for (uint256 i = 0; i < 5; i++) {
            engine.mint(1000e18);

            flatCoin.approve(address(engine), 1000e18);
            engine.burn(1000e18);
        }

        assertEq(flatCoin.balanceOf(USER), 0);

        vm.stopPrank();
    }
}