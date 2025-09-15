// SPDX-License-Identifier: MIT
// Use a specific, audited compiler version
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Import SafeERC20 for secure token transfers
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Import Pausable for emergency stops
import "@openzeppelin/contracts/security/Pausable.sol";
// Import ReentrancyGuard as a best practice
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BridgeAdapter
 * @author Based on a common template
 * @notice This contract facilitates the locking and unlocking of an ERC20 token for cross-chain bridging.
 * @dev A secure and updated placeholder for a cross-chain bridge adapter.
 * This contract locks tokens on this chain to be minted on another,
 * and unlocks tokens bridged from other chains.
 * It includes security features like pausability, re-entrancy guard, and safe token transfers.
 */
contract BridgeAdapter is AccessControl, Pausable, ReentrancyGuard {
    // Using SafeERC20 library for IERC20 interface
    using SafeERC20 for IERC20;

    // --- Roles ---
    /**
     * @dev Role for entities authorized to call the unlock function.
     */
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    /**
     * @dev Role for entities authorized to pause and unpause the contract.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- State Variables ---
    /**
     * @notice The ERC20 token that this bridge handles.
     */
    IERC20 public immutable token;

    // --- Events ---
    /**
     * @notice Emitted when tokens are locked for bridging to another chain.
     * @param user The address of the user who locked the tokens.
     * @param amount The amount of tokens locked.
     * @param destinationChainId The chain ID of the destination network.
     */
    event Locked(address indexed user, uint256 amount, uint256 destinationChainId);

    /**
     * @notice Emitted when tokens are unlocked after being bridged from another chain.
     * @param user The address of the recipient of the unlocked tokens.
     * @param amount The amount of tokens unlocked.
     * @param sourceChainId The chain ID of the source network.
     */
    event Unlocked(address indexed user, uint256 amount, uint256 sourceChainId);

    // --- Constructor ---
    /**
     * @notice Initializes the contract, setting the admin and token address.
     * @param admin The address that will receive admin, bridge, and pauser roles.
     * @param _tokenAddress The address of the ERC20 token this bridge will handle.
     * @dev For production, it's recommended to assign these roles to separate
     * multi-sig wallets or a governance contract for decentralization.
     */
    constructor(address admin, address _tokenAddress) {
        // Grant all initial roles to the admin address
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BRIDGE_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        
        token = IERC20(_tokenAddress);
    }

    // --- Public & External Functions ---

    /**
     * @notice Locks a specified amount of tokens for bridging to another chain.
     * @dev This function allows a user to lock their tokens in the contract. These tokens can then be represented on another blockchain. The user must first approve the contract to spend the specified amount of tokens.
     * @param _amount The amount of tokens to lock. Must be greater than zero.
     * @param _destinationChainId The identifier of the chain to which the tokens are being bridged.
     */
    function lock(uint256 _amount, uint256 _destinationChainId)
        external
        whenNotPaused // The function can be paused in emergencies
        nonReentrant // Protects against re-entrancy attacks
    {
        // Check for zero amount to prevent wasting gas
        require(_amount > 0, "Bridge: Amount must be greater than zero");

        // Use safeTransferFrom for secure token handling
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        emit Locked(msg.sender, _amount, _destinationChainId);
    }

    /**
     * @notice Unlocks tokens that have been bridged from another chain.
     * @dev This function is called by a trusted bridge entity to release tokens to a user on this chain. It's the counterpart to the `lock` function.
     * @param _to The recipient of the unlocked tokens. Cannot be the zero address.
     * @param _amount The amount of tokens to unlock. Must be greater than zero.
     * @param _sourceChainId The identifier of the chain from which the tokens were bridged.
     */
    function unlock(address _to, uint256 _amount, uint256 _sourceChainId)
        external
        onlyRole(BRIDGE_ROLE) // Only trusted bridge entities can call this
        nonReentrant // Protects against re-entrancy attacks
    {
        // Check for zero amount
        require(_amount > 0, "Bridge: Amount must be greater than zero");

        // Check if recipient is the zero address
        require(_to != address(0), "Bridge: Cannot unlock to the zero address");
        
        // Use safeTransfer for secure token handling
        token.safeTransfer(_to, _amount);
        
        emit Unlocked(_to, _amount, _sourceChainId);
    }

    // --- Administrative Functions ---

    /**
     * @notice Pauses the `lock` functionality in case of an emergency.
     * @dev This function is part of the Pausable pattern and can only be called by an address with the PAUSER_ROLE. It prevents new tokens from being locked.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the `lock` functionality when it's safe to resume operations.
     * @dev This function is part of the Pausable pattern and can only be called by an address with the PAUSER_ROLE. It allows the `lock` function to be used again.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
