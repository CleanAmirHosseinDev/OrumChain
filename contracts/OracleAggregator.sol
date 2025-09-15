// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOracle.sol";

/**
 * @title OracleAggregator
 * @author Your Name
 * @notice This contract maintains a trusted on-chain price for an asset, updated via EIP-712 signed price reports.
 * @dev It allows one or more trusted oracles (with `ORACLE_ROLE`) to submit signed price data. The contract verifies the signature and updates the on-chain price, ensuring data integrity and authenticity. It uses EIP-712 to prevent replay attacks. This contract can be used as a primary oracle itself, as it implements the `IOracle` interface.
 */
contract OracleAggregator is IOracle, EIP712, AccessControl {
    /**
     * @dev Role for trusted oracle entities authorized to sign price reports.
     */
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /**
     * @dev The EIP-712 type hash for the `PriceReport` struct.
     */
    bytes32 private constant PRICE_REPORT_TYPEHASH = keccak256(
        "PriceReport(uint256 price,uint256 timestamp)"
    );

    /**
     * @notice The latest price reported by a trusted oracle.
     */
    uint256 public latestPrice;

    /**
     * @notice The timestamp of the latest price update.
     */
    uint256 public lastUpdateTimestamp;

    /**
     * @notice Emitted when the on-chain price is successfully updated.
     * @param newPrice The new price that was set.
     * @param timestamp The timestamp of the price report.
     * @param oracle The address of the oracle that signed the report.
     */
    event PriceUpdated(uint256 newPrice, uint256 timestamp, address indexed oracle);

    /**
     * @notice Initializes the contract, setting up the EIP-712 domain and initial roles.
     * @param admin The address that will be granted the default admin role.
     * @param initialOracle The address of the first trusted oracle to be granted the `ORACLE_ROLE`.
     */
    constructor(address admin, address initialOracle) EIP712("OracleAggregator", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ROLE, initialOracle);
    }

    /**
     * @notice Updates the on-chain price after verifying a signed report from a trusted oracle.
     * @dev The function requires that the report's timestamp is newer than the last update to prevent stale data. It reconstructs the EIP-712 typed data hash, recovers the signer's address from the signature, and verifies that the signer has the `ORACLE_ROLE`.
     * @param price The new price, with appropriate decimals.
     * @param timestamp The timestamp of the price report. Must be greater than `lastUpdateTimestamp`.
     * @param signature The EIP-712 signature from a wallet with `ORACLE_ROLE`.
     */
    function updatePrice(uint256 price, uint256 timestamp, bytes calldata signature) external {
        require(timestamp > lastUpdateTimestamp, "OA: Stale timestamp");

        bytes32 structHash = keccak256(abi.encode(PRICE_REPORT_TYPEHASH, price, timestamp));
        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, signature);
        require(hasRole(ORACLE_ROLE, signer), "OA: Invalid oracle signature");

        latestPrice = price;
        lastUpdateTimestamp = timestamp;
        emit PriceUpdated(price, timestamp, signer);
    }

    /**
     * @notice Gets the latest price for a given asset.
     * @dev This contract itself acts as an oracle. This function from the `IOracle` interface returns the `latestPrice` stored in this contract. The `_asset` parameter is not used because this specific oracle is designed to track a single price.
     * @param _asset The address of the asset (ignored in this implementation).
     * @return The latest price.
     */
    function getPrice(address _asset) external view override returns (uint256) {
        // This oracle stores one price, so it ignores the asset parameter.
        // A more complex version could map assets to prices.
        return latestPrice;
    }
}
