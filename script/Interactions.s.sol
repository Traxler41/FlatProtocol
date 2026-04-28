// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FlatCoinEngine} from "../src/FlatCoinEngine.sol";
import {FlatCoin} from "../src/FlatCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Interactions is Script {
    function run() external {
        // 🔴 Replace these with your deployed addresses
        address ENGINE = vm.envAddress("ENGINE_ADDRESS");
        address FLATCOIN = vm.envAddress("FLATCOIN_ADDRESS");
        address COLLATERAL = vm.envAddress("COLLATERAL_ADDRESS");

        uint256 PRIVATE_KEY = vm.envUint("PRIVATE_KEY");

        FlatCoinEngine engine = FlatCoinEngine(ENGINE);
        FlatCoin flatCoin = FlatCoin(FLATCOIN);

        vm.startBroadcast(PRIVATE_KEY);

        console.log("Starting interaction...");

        // 1. Approve collateral
        IERC20(COLLATERAL).approve(ENGINE, 1 ether);

        // 2. Deposit collateral
        engine.deposit(COLLATERAL, 1 ether);
        console.log("Deposited collateral");

        // 3. Mint stablecoin
        engine.mint(500e18);
        console.log("Minted FlatCoin");

        // 4. Check balance
        uint256 balance = flatCoin.balanceOf(msg.sender);
        console.log("FlatCoin Balance:", balance);

        // 5. Burn some debt
        flatCoin.approve(ENGINE, 100e18);
        engine.burn(100e18);
        console.log("Burned 100 FC");

        // 6. Withdraw collateral
        engine.withdraw(COLLATERAL, 0.2 ether);
        console.log("Withdrew collateral");

        vm.stopBroadcast();
    }
}
