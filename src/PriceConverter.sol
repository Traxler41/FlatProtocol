//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /**
     *
     * @param priceFeed PriceFeed Address for ETH/USD conversion
     */
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    /**
     *
     * @param ethAmount Amount of ETH to check total amount in USD
     * @param priceFeed PriceFeed Address for ETH/USD conversion
     */
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;

        return ethAmountInUsd;
    }
}
