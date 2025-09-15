// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IKYCRegistry Interface
 * @author Your Name
 * @notice Defines the standard interface for a KYC (Know Your Customer) Registry.
 * @dev Contracts can use this interface to query whether a user is verified,
 * allowing for different KYC implementation contracts to be used.
 */
interface IKYCRegistry {
    /**
     * @notice Checks if a user's address has been verified.
     * @dev In a Merkle-based implementation, this would return true if the user has successfully submitted a valid proof.
     * @param _user The address to check.
     * @return bool True if the user is verified, false otherwise.
     */
    function isVerified(address _user) external view returns (bool);

    /**
     * @notice Returns the current Merkle root of the KYC whitelist.
     * @dev Allows external contracts or users to see the current root, which can be useful for generating proofs off-chain.
     * @return bytes32 The current Merkle root.
     */
    function merkleRoot() external view returns (bytes32);
}
