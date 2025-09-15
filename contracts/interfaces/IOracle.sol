// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Note: The import of OracleAggregator may be for type-casting or to indicate a relationship,
// but is not strictly necessary for the interface definition itself.
import "../OracleAggregator.sol";

/**
 * @title IOracle
 * @author Your Name
 * @notice A simple interface for a contract that provides a single, latest price feed.
 * @dev This interface is suitable for oracles that report a single, specific asset price
 * rather than prices for multiple assets.
 */
interface IOracle {
    /**
     * @notice Returns the latest price from the oracle.
     * @dev The price is expected to be returned as a uint256 with a fixed number of decimals,
     * as defined by the oracle's implementation.
     * @return uint256 The latest price.
     */
    function latestPrice() external view returns (uint256);
}
