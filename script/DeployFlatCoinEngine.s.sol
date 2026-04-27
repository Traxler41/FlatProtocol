//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FlatCoinEngine} from "../src/FlatCoinEngine.sol";
import {FlatCoin} from "../src/FlatCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFlatCoinEngine is Script {
    FlatCoin flatCoin;

    function deployFlatCoinEngine() public returns (FlatCoinEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (, address priceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FlatCoinEngine flatCoinEngine = new FlatCoinEngine(priceFeed, address(flatCoin));
        vm.stopPrank();

        return (flatCoinEngine, helperConfig);
    }

    function run() external returns (FlatCoinEngine, HelperConfig) {
        return deployFlatCoinEngine();
    }
}
