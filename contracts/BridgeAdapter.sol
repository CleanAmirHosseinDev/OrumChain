// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BridgeAdapter
 * @dev A placeholder contract for future integration with a cross-chain bridge.
 * This contract would hold the logic for locking tokens on this chain to be minted
 * on another chain, and for unlocking tokens that were bridged from another chain.
 * The implementation details would be highly specific to the chosen bridge protocol.
 */
contract BridgeAdapter is AccessControl {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    IERC20 public immutable token;

    event Locked(address indexed user, uint256 amount, uint256 destinationChainId);
    event Unlocked(address indexed user, uint256 amount, uint256 sourceChainId);

    constructor(address admin, address _tokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // The BRIDGE_ROLE would be held by the bridge's trusted validator/oracle system.
        _grantRole(BRIDGE_ROLE, admin);
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Locks tokens in the adapter contract to be minted on a destination chain.
     */
    function lock(uint256 _amount, uint256 _destinationChainId) external {
        // In a real implementation, this would likely emit an event that a bridge
        // validator network would listen for.
        token.transferFrom(msg.sender, address(this), _amount);
        emit Locked(msg.sender, _amount, _destinationChainId);
    }

    /**
     * @dev Unlocks tokens that have been bridged from another chain.
     * Only a trusted bridge entity can call this function.
     */
    function unlock(address _to, uint256 _amount, uint256 _sourceChainId) external onlyRole(BRIDGE_ROLE) {
        // The bridge validator network would call this function after confirming
        // a corresponding lock event on the source chain.
        token.transfer(_to, _amount);
        emit Unlocked(_to, _amount, _sourceChainId);
    }
}
