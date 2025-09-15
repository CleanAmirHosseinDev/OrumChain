// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IKYCRegistry.sol";

/**
 * @title KYCRegistry
 * @author Your Name
 * @notice Manages an on-chain whitelist for Know Your Customer (KYC) verification using a Merkle root.
 * @dev An off-chain KYC provider generates a Merkle tree of verified user addresses and submits the root to this contract.
 * Users can then prove their inclusion in the whitelist by providing a valid Merkle proof, which marks their address as verified.
 * This contract implements the `IKYCRegistry` interface.
 */
contract KYCRegistry is AccessControl, IKYCRegistry {
    /**
     * @notice The current Merkle root of the KYC whitelist.
     */
    bytes32 public merkleRoot;

    /**
     * @notice A mapping to store the verification status of each address.
     * @dev `true` if the address has successfully submitted a proof, `false` otherwise.
     */
    mapping(address => bool) public isVerified;

    /**
     * @dev Role for administrators who can update the Merkle root.
     */
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");

    /**
     * @notice Emitted when the Merkle root is updated.
     * @param oldRoot The previous Merkle root.
     * @param newRoot The new Merkle root.
     */
    event RootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);

    /**
     * @notice Emitted when a user's address is successfully verified.
     * @param user The address that was verified.
     */
    event AddressVerified(address indexed user);

    /**
     * @notice Initializes the contract with an admin and an initial Merkle root.
     * @param admin The address that will be granted the default admin and KYC admin roles.
     * @param initialRoot The initial Merkle root of the KYC whitelist.
     */
    constructor(address admin, bytes32 initialRoot) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ADMIN_ROLE, admin);
        merkleRoot = initialRoot;
    }

    /**
     * @notice Updates the Merkle root of the KYC whitelist.
     * @dev Can only be called by an address with the `KYC_ADMIN_ROLE`.
     * @param _newRoot The new Merkle root.
     */
    function updateRoot(bytes32 _newRoot) external onlyRole(KYC_ADMIN_ROLE) {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newRoot;
        emit RootUpdated(oldRoot, _newRoot);
    }

    /**
     * @notice Allows a user to submit a Merkle proof to verify their address.
     * @dev The user calls this function with a proof generated off-chain. The function calculates the leaf node for the caller's address (`keccak256(abi.encodePacked(msg.sender))`) and verifies it against the `merkleRoot`. If the proof is valid and the user is not already verified, their status is updated.
     * @param proof The Merkle proof for the user's address.
     */
    function proveAndUpdate(bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "KYCR: Invalid proof");

        if (!isVerified[msg.sender]) {
            isVerified[msg.sender] = true;
            emit AddressVerified(msg.sender);
        }
    }

    /**
     * @notice Checks if a user is KYC verified.
     * @dev This is a view function that returns the status from the `isVerified` mapping.
     * @param _user The address to check.
     * @return bool True if the user is verified, false otherwise.
     */
    function isKYCVerified(address _user) external view override returns (bool) {
        return isVerified[_user];
    }
}
