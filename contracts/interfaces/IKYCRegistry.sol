// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IKYCRegistry Interface
 * @dev Defines the external functions for the KYCRegistry contract that other contracts can call.
 */
interface IKYCRegistry {
    /**
     * @dev Returns true if a user's address has been verified against the Merkle root.
     * @param _user The address to check.
     * @return bool True if the user is verified, false otherwise.
     */
    function isVerified(address _user) external view returns (bool);

    /**
     * @dev Returns the current Merkle root of the KYC whitelist.
     * @return bytes32 The current Merkle root.
     */
    function merkleRoot() external view returns (bytes32);
}
