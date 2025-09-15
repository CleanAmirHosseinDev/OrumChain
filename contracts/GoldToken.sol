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
 * @author Your Name
 * @notice An ERC20 token representing tokenized gold, named "BourseChain Gold" (BCG).
 * @dev This contract implements an ERC20 token with additional features for security and regulatory compliance:
 * - `ERC20Permit`: Allows for gasless approvals via signatures.
 * - `AccessControl`: Manages permissions with several roles:
 *   - `MINTER_ROLE`: For creating new tokens (not implemented in this contract, intended for a separate minter contract).
 *   - `PAUSER_ROLE`: For halting token transfers in emergencies.
 *   - `KYC_ADMIN_ROLE`: For managing KYC-related settings.
 *   - `KYC_EXEMPT_ROLE`: For exempting addresses from KYC checks.
 *   - `FEE_MANAGER_ROLE`: For managing redemption fees.
 * - `Pausable`: Token transfers can be stopped and resumed.
 * - `ReentrancyGuard`: Protects against re-entrancy attacks in the `redeem` function.
 * - **KYC Enforcement**: Transfers can be restricted to KYC-verified addresses.
 * - **Redemption Mechanism**: Users can burn their tokens to redeem them, subject to a fee.
 */
contract GoldToken is
    ERC20,
    ERC20Permit,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    /** @dev Role for allowed minters. */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /** @dev Role for pausers. */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /** @dev Role for KYC administrators. */
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");
    /** @dev Role for addresses exempt from KYC. */
    bytes32 public constant KYC_EXEMPT_ROLE = keccak256("KYC_EXEMPT_ROLE");
    /** @dev Role for managing fees. */
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /** @notice The KYC registry contract used to verify user status. */
    IKYCRegistry public kycRegistry;
    /** @notice Flag to enable or disable the KYC check for transfers. */
    bool public kycCheckEnabled = false;

    /** @notice The redemption fee charged, in basis points (1/100th of a percent). */
    uint256 public redemptionFeeBps;
    /** @notice The address that collects redemption fees. */
    address public feeCollector;

    /** @notice Emitted when a user redeems tokens. */
    event Redemption(address indexed user, uint256 amount);
    /** @notice Emitted when the redemption fee is updated. */
    event RedemptionFeeUpdated(uint256 newFeeBps);
    /** @notice Emitted when the fee collector address is updated. */
    event FeeCollectorUpdated(address newCollector);
    /** @notice Emitted when the KYC registry address is updated. */
    event KYCRegistryUpdated(address indexed newRegistry);
    /** @notice Emitted when the KYC check is enabled or disabled. */
    event KYCCheckStatusChanged(bool enabled);

    /**
     * @notice Initializes the contract, setting up roles and the token name/symbol.
     * @param admin The address that will receive admin, pauser, KYC admin, fee manager, and KYC exempt roles.
     * @param initialMinter The address that will receive the initial minter role.
     */
    constructor(
        address admin,
        address initialMinter
    ) ERC20("BourseChain Gold", "BCG") ERC20Permit("BourseChain Gold") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(KYC_ADMIN_ROLE, admin);
        _grantRole(FEE_MANAGER_ROLE, admin);
        _grantRole(MINTER_ROLE, initialMinter);
        _grantRole(KYC_EXEMPT_ROLE, admin); // Admin is exempt by default
    }

    /** @notice Pauses all token transfers. Restricted to `PAUSER_ROLE`. */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /** @notice Resumes token transfers. Restricted to `PAUSER_ROLE`. */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Sets the redemption fee in basis points.
     * @dev The fee cannot exceed 100% (10,000 basis points). Restricted to `FEE_MANAGER_ROLE`.
     * @param _newFeeBps The new redemption fee in basis points.
     */
    function setRedemptionFee(
        uint256 _newFeeBps
    ) external onlyRole(FEE_MANAGER_ROLE) {
        require(_newFeeBps <= 10000, "GT: Fee cannot exceed 100%");
        redemptionFeeBps = _newFeeBps;
        emit RedemptionFeeUpdated(_newFeeBps);
    }

    /**
     * @notice Sets the address that will receive redemption fees.
     * @dev Restricted to `FEE_MANAGER_ROLE`.
     * @param _newCollector The new address for the fee collector.
     */
    function setFeeCollector(
        address _newCollector
    ) external onlyRole(FEE_MANAGER_ROLE) {
        require(_newCollector != address(0), "GT: Zero address");
        feeCollector = _newCollector;
        emit FeeCollectorUpdated(_newCollector);
    }

    /**
     * @notice Sets the KYC registry contract address.
     * @dev Restricted to `KYC_ADMIN_ROLE`.
     * @param _newRegistry The new address of the KYC registry contract.
     */
    function setKYCRegistry(
        IKYCRegistry _newRegistry
    ) external onlyRole(KYC_ADMIN_ROLE) {
        require(address(_newRegistry) != address(0), "GT: Zero address");
        kycRegistry = _newRegistry;
        emit KYCRegistryUpdated(address(_newRegistry));
    }

    /**
     * @notice Enables or disables the mandatory KYC check for transfers.
     * @dev Restricted to `KYC_ADMIN_ROLE`.
     * @param _enabled Boolean flag to enable (true) or disable (false) the check.
     */
    function setKYCCheck(bool _enabled) external onlyRole(KYC_ADMIN_ROLE) {
        kycCheckEnabled = _enabled;
        emit KYCCheckStatusChanged(_enabled);
    }

    /**
     * @notice Allows a user to redeem (burn) their tokens.
     * @dev A redemption fee is calculated and transferred to the `feeCollector`. The remaining amount is burned from the user's balance. The function is protected against re-entrancy.
     * @param amount The total amount of tokens the user wishes to redeem.
     */
    function redeem(uint256 amount) external nonReentrant {
        uint256 fee = (amount * redemptionFeeBps) / 10000;
        if (fee > 0) {
            require(feeCollector != address(0), "GT: Fee collector not set");
            // The fee transfer is subject to the same KYC checks as a regular transfer.
            _transfer(msg.sender, feeCollector, fee);
        }

        uint256 burnAmount = amount - fee;
        _burn(msg.sender, burnAmount);
        emit Redemption(msg.sender, burnAmount);
    }

    /**
     * @dev Internal hook that is called before any token transfer.
     * @dev It enforces that the contract is not paused. If `kycCheckEnabled` is true, it also verifies that both the sender and recipient are KYC-compliant, unless either address has the `KYC_EXEMPT_ROLE`. Minting (from address 0) and burning (to address 0) are not subject to KYC checks.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (kycCheckEnabled && from != address(0) && to != address(0)) {
            if (
                hasRole(KYC_EXEMPT_ROLE, from) || hasRole(KYC_EXEMPT_ROLE, to)
            ) {
                return;
            }
            require(
                address(kycRegistry) != address(0),
                "GT: KYC registry not set"
            );
            require(
                kycRegistry.isVerified(from),
                "GT: sender not KYC-verified"
            );
            require(
                kycRegistry.isVerified(to),
                "GT: recipient not KYC-verified"
            );
        }
    }
}
