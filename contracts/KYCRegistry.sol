// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title KYCRegistry
 * @dev Manages an on-chain Merkle root for a KYC whitelist.
 * An off-chain KYC provider updates the root, and users can submit proofs
 * to mark their address as verified.
 */
contract KYCRegistry is AccessControl {
    bytes32 public merkleRoot;
    mapping(address => bool) public isVerified;

    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");

    event RootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event AddressVerified(address indexed user);

    constructor(address admin, bytes32 initialRoot) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ADMIN_ROLE, admin);
        merkleRoot = initialRoot;
    }

    /**
     * @dev Updates the Merkle root. Only callable by the KYC_ADMIN_ROLE.
     * @param _newRoot The new Merkle root.
     */
    function updateRoot(bytes32 _newRoot) external onlyRole(KYC_ADMIN_ROLE) {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newRoot;
        emit RootUpdated(oldRoot, _newRoot);
    }

    /**
     * @dev Allows a user to submit a Merkle proof to verify their address.
     * If the proof is valid, the user's address is marked as verified.
     * The leaf for the proof must be keccak256(abi.encodePacked(msg.sender)).
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
}
