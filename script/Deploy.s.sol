// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FlatCoin} from "../src/FlatCoin.sol";
import {FlatCoinEngine} from "../src/FlatCoinEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Deploy is Script {
    function run() external {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory net = config.activeNetworkConfig();

        vm.startBroadcast();

        // 1. Deploy FlatCoin
        FlatCoin flatCoin = new FlatCoin();

        // 2. Deploy Engine
        FlatCoinEngine engine = new FlatCoinEngine(address(flatCoin), net.treasury);

        // 3. Set engine in token
        flatCoin.setEngine(address(engine));

        // 4. Add collateral types
        for (uint256 i = 0; i < net.collateralTokens.length; i++) {
            engine.addCollateral(
                net.collateralTokens[i],
                net.priceFeeds[i],
                80, // liquidation threshold
                10 // bonus
            );
        }

        vm.stopBroadcast();

        // Logs (very useful in hackathon demo)
        console.log("FlatCoin:", address(flatCoin));
        console.log("Engine:", address(engine));
        console.log("Treasury:", net.treasury);
    }
}
