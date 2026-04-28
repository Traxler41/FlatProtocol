// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                STRUCT
    //////////////////////////////////////////////////////////////*/

    struct NetworkConfig {
        address[] collateralTokens;
        address[] priceFeeds;
        address treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    NetworkConfig private s_activeConfig;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_PRICE = 2000e8;
    int256 private constant BTC_PRICE = 30000e8;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        if (block.chainid == 11155111) {
            s_activeConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            s_activeConfig = getMainnetConfig();
        } else {
            s_activeConfig = getOrCreateAnvilConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        NETWORK CONFIGS
    //////////////////////////////////////////////////////////////*/

    function getSepoliaConfig() internal pure returns (NetworkConfig memory config) {
        address[] memory tokens = new address[](2);
        address[] memory feeds = new address[](2);

        // WETH
        tokens[0] = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81;
        feeds[0] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

        // WBTC
        tokens[1] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // example (can replace)
        feeds[1] = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

        config = NetworkConfig({collateralTokens: tokens, priceFeeds: feeds, treasury: msg.sender});
    }

    function getMainnetConfig() internal pure returns (NetworkConfig memory config) {
        address[] memory tokens = new address[](2);
        address[] memory feeds = new address[](2);

        // WETH
        tokens[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        feeds[0] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        // WBTC
        tokens[1] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        feeds[1] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

        config = NetworkConfig({collateralTokens: tokens, priceFeeds: feeds, treasury: msg.sender});
    }

    function getOrCreateAnvilConfig() internal returns (NetworkConfig memory config) {
        if (s_activeConfig.collateralTokens.length > 0) {
            return s_activeConfig;
        }

        vm.startBroadcast();

        // Deploy mocks
        MockV3Aggregator ethFeed = new MockV3Aggregator(DECIMALS, ETH_PRICE);
        MockV3Aggregator btcFeed = new MockV3Aggregator(DECIMALS, BTC_PRICE);

        ERC20Mock weth = new ERC20Mock("Wrapped ETH", "WETH", msg.sender, 1000e18);
        ERC20Mock wbtc = new ERC20Mock("Wrapped BTC", "WBTC", msg.sender, 1000e18);

        vm.stopBroadcast();

        address[] memory tokens = new address[](2);
        address[] memory feeds = new address[](2);

        tokens[0] = address(weth);
        feeds[0] = address(ethFeed);

        tokens[1] = address(wbtc);
        feeds[1] = address(btcFeed);

        config = NetworkConfig({collateralTokens: tokens, priceFeeds: feeds, treasury: msg.sender});
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    function activeNetworkConfig() external view returns (NetworkConfig memory) {
        return s_activeConfig;
    }
}
