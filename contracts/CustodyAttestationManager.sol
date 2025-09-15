// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GoldToken.sol";

/**
 * @title CustodyAttestationManager
 * @author Your Name
 * @notice This contract is the sole minter for the GoldToken. It mints new tokens only after verifying a valid EIP-712 signed attestation from a trusted custodian.
 * @dev This contract uses the EIP-712 standard to create a structured, signable message for minting, which prevents replay attacks across different contracts and chains. It holds the `MINTER_ROLE` for the associated `GoldToken` contract.
 */
contract CustodyAttestationManager is EIP712, AccessControl {
    /**
     * @dev Role for the custodian entity authorized to sign mint attestations.
     */
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    /**
     * @dev The EIP-712 type hash for the `MintAttestation` struct.
     */
    bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
        "MintAttestation(address recipient,uint256 amount,bytes32 nonce)"
    );

    /**
     * @notice The GoldToken contract instance that this manager can mint.
     */
    GoldToken public immutable goldToken;

    /**
     * @notice A mapping to track nonces that have already been used to prevent replay attacks.
     * @dev A nonce can only be used once.
     */
    mapping(bytes32 => bool) public usedNonces;

    /**
     * @notice Emitted when a successful mint occurs via a valid attestation.
     * @param recipient The address that received the newly minted tokens.
     * @param amount The amount of tokens minted.
     * @param nonce The unique nonce of the attestation used.
     */
    event AttestationMint(address indexed recipient, uint256 amount, bytes32 indexed nonce);

    /**
     * @notice Initializes the contract, setting the admin and the GoldToken address.
     * @param admin The address that will be granted the default admin role. The admin can then grant the `CUSTODIAN_ROLE` to the appropriate addresses.
     * @param _goldTokenAddress The address of the GoldToken contract this manager will control.
     * @dev The EIP-712 domain separator is initialized with the name "CustodyAttestation" and version "1".
     */
    constructor(address admin, address _goldTokenAddress) EIP712("CustodyAttestation", "1") {
        require(_goldTokenAddress != address(0), "CAM: Zero address for token");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // It's assumed that the admin will grant CUSTODIAN_ROLE to the custodian(s)
        // and grant MINTER_ROLE on the GoldToken to this contract.
        goldToken = GoldToken(_goldTokenAddress);
    }

    /**
     * @notice Mints new tokens for a recipient after verifying a valid EIP-712 signature from an authorized custodian.
     * @dev This function reconstructs the EIP-712 typed data hash for the mint attestation and uses `ECDSA.recover` to get the signer's address from the signature. It then checks if the signer has the `CUSTODIAN_ROLE`. It also ensures the nonce has not been used before to prevent replay attacks.
     * @param recipient The address to receive the new tokens.
     * @param amount The amount of tokens to mint (in wei, 18 decimals).
     * @param nonce A unique, single-use identifier for the attestation.
     * @param signature The EIP-712 signature from a wallet with `CUSTODIAN_ROLE`.
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
