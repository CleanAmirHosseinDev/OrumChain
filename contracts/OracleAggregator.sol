// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title OracleAggregator
 * @dev This contract maintains a trusted on-chain price for an asset (e.g., Gold).
 * It is updated via EIP-712 signed price reports from one or more trusted oracles.
 */
contract OracleAggregator is EIP712, AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 private constant PRICE_REPORT_TYPEHASH = keccak256(
        "PriceReport(uint256 price,uint256 timestamp)"
    );

    uint256 public latestPrice;
    uint256 public lastUpdateTimestamp;

    event PriceUpdated(uint256 newPrice, uint256 timestamp, address indexed oracle);

    constructor(address admin, address initialOracle) EIP712("OracleAggregator", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ROLE, initialOracle);
    }

    /**
     * @dev Updates the on-chain price after verifying an oracle's signature.
     * @param price The new price, with appropriate decimals.
     * @param timestamp The timestamp of the price report. Must be greater than the last update.
     * @param signature The EIP-712 signature from a wallet with ORACLE_ROLE.
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
}
