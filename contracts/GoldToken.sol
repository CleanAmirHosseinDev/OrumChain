// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IKYCRegistry.sol";

/**
 * @title GoldToken
 * @dev An ERC20 token for tokenized gold, with KYC enforcement and role-based access control.
 * Based on 1 gram of 999.9 gold, with 18 decimals.
 * Symbol: BCG (BourseChain Gold)
 */
contract GoldToken is ERC20, ERC20Permit, AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");
    bytes32 public constant KYC_EXEMPT_ROLE = keccak256("KYC_EXEMPT_ROLE");

    IKYCRegistry public kycRegistry;
    bool public kycCheckEnabled = false;

    event Redemption(address indexed user, uint256 amount);
    event KYCRegistryUpdated(address indexed newRegistry);
    event KYCCheckStatusChanged(bool enabled);

    constructor(
        address admin,
        address initialMinter
    ) ERC20("BourseChain Gold", "BCG") ERC20Permit("BourseChain Gold") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(KYC_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, initialMinter);
        _grantRole(KYC_EXEMPT_ROLE, admin); // Admin is exempt by default
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setKYCRegistry(IKYCRegistry _newRegistry) external onlyRole(KYC_ADMIN_ROLE) {
        require(address(_newRegistry) != address(0), "GT: Zero address");
        kycRegistry = _newRegistry;
        emit KYCRegistryUpdated(address(_newRegistry));
    }

    function setKYCCheck(bool _enabled) external onlyRole(KYC_ADMIN_ROLE) {
        kycCheckEnabled = _enabled;
        emit KYCCheckStatusChanged(_enabled);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function redeem(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
        emit Redemption(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (kycCheckEnabled && from != address(0) && to != address(0)) {
            if(hasRole(KYC_EXEMPT_ROLE, from) || hasRole(KYC_EXEMPT_ROLE, to)) {
                return;
            }
            require(address(kycRegistry) != address(0), "GT: KYC registry not set");
            require(kycRegistry.isVerified(from), "GT: sender not KYC-verified");
            require(kycRegistry.isVerified(to), "GT: recipient not KYC-verified");
        }
    }
}
