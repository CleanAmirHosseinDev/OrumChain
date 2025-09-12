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
 * @dev A secure and updated placeholder for a cross-chain bridge adapter.
 * This contract locks tokens on this chain to be minted on another,
 * and unlocks tokens bridged from other chains.
 * It includes security features like pausability, re-entrancy guard, and safe token transfers.
 */
contract BridgeAdapter is AccessControl, Pausable, ReentrancyGuard {
    // Using SafeERC20 library for IERC20 interface
    using SafeERC20 for IERC20;

    // --- Roles ---
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- State Variables ---
    IERC20 public immutable token;

    // --- Events ---
    event Locked(address indexed user, uint256 amount, uint256 destinationChainId);
    event Unlocked(address indexed user, uint256 amount, uint256 sourceChainId);

    // --- Constructor ---
    /**
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
     * @dev Locks tokens in the adapter contract to be minted on a destination chain.
     * The contract must be approved to spend the user's tokens beforehand.
     * @param _amount The amount of tokens to lock.
     * @param _destinationChainId The chain ID of the destination network.
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
     * @dev Unlocks tokens that have been bridged from another chain.
     * Only callable by an address with the BRIDGE_ROLE.
     * @param _to The recipient of the unlocked tokens.
     * @param _amount The amount of tokens to unlock.
     * @param _sourceChainId The chain ID of the source network.
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
     * @dev Pauses the lock functionality.
     * Only callable by an address with the PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the lock functionality.
     * Only callable by an address with the PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
