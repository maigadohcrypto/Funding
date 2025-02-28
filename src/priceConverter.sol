// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {AggregatorV3Interface} from "lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

// A price converter library
contract PriceConverter {
    AggregatorV3Interface internal dataFeed;

    function priceConvertion(uint256 _ethAmount) internal view returns (uint256) {
        // Price feed has 8 decimals, so we need to scale it to 18 decimals
        uint256 usdAmount = (_ethAmount * getPrice()) / 1e8;
        return usdAmount;
    }

    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
