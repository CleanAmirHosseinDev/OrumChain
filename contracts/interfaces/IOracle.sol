// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../OracleAggregator.sol";

interface IOracle {
    function latestPrice() external view returns (uint256);
}
