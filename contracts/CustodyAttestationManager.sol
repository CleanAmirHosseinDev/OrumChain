// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GoldToken.sol";

/**
 * @title CustodyAttestationManager
 * @dev This contract verifies EIP-712 signed attestations from a trusted custodian
 * and mints new GoldTokens accordingly. It is the only entity with MINTER_ROLE.
 */
contract CustodyAttestationManager is EIP712, AccessControl {
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
        "MintAttestation(address recipient,uint256 amount,bytes32 nonce)"
    );

    GoldToken public immutable goldToken;
    mapping(bytes32 => bool) public usedNonces;

    event AttestationMint(address indexed recipient, uint256 amount, bytes32 indexed nonce);

    constructor(address admin, address _goldTokenAddress) EIP712("CustodyAttestation", "1") {
        require(_goldTokenAddress != address(0), "CAM: Zero address for token");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        goldToken = GoldToken(_goldTokenAddress);
    }

    /**
     * @dev Mints new tokens after verifying a custodian's signature.
     * @param recipient The address to receive the new tokens.
     * @param amount The amount of tokens to mint (in wei, 18 decimals).
     * @param nonce A unique, single-use identifier for the attestation to prevent replay attacks.
     * @param signature The EIP-712 signature from a wallet with CUSTODIAN_ROLE.
     */
    function mintWithAttestation(
        address recipient,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external {
        require(!usedNonces[nonce], "CAM: Nonce already used");

        bytes32 structHash = keccak256(abi.encode(ATTESTATION_TYPEHASH, recipient, amount, nonce));
        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, signature);
        require(hasRole(CUSTODIAN_ROLE, signer), "CAM: Invalid custodian signature");

        usedNonces[nonce] = true;
        goldToken.mint(recipient, amount);

        emit AttestationMint(recipient, amount, nonce);
    }
}
