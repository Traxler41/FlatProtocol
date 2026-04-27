//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FlatCoin} from "../src/FlatCoin.sol";

contract DeployFlatCoin is Script {
    function run() external returns (FlatCoin) {
        vm.startBroadcast();
        FlatCoin flatCoin = new FlatCoin();
        vm.stopBroadcast();

        return flatCoin;
    }
}
