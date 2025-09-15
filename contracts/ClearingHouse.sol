// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IOracle.sol";
import "./OptionToken.sol";
import "./OptionFactory.sol";

/**
 * @title ClearingHouse
 * @author Your Name
 * @notice Manages collateral, settlement, and liquidation for the options module.
 * @dev This contract is responsible for holding user collateral, settling expired options, and liquidating under-collateralized positions.
 * This is currently a skeleton contract and the core logic is yet to be implemented.
 */
contract ClearingHouse is AccessControl, ReentrancyGuard {
    /**
     * @dev Role for administrators of the clearing house, with powers to change settings.
     */
    bytes32 public constant CLEARING_ADMIN_ROLE = keccak256("CLEARING_ADMIN_ROLE");
    /**
     * @dev Role for entities authorized to trigger liquidations.
     */
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    /**
     * @notice The factory contract for creating new option series.
     */
    OptionFactory public optionFactory;
    /**
     * @notice The ERC1155 token contract representing the options.
     */
    OptionToken public optionToken;
    /**
     * @notice The price oracle for getting settlement prices.
     */
    IOracle public priceOracle;

    /**
     * @notice Mapping from a user's address to their collateral balance for a specific collateral token.
     * @dev `mapping(userAddress => mapping(collateralTokenAddress => amount))`
     */
    mapping(address => mapping(address => uint256)) public collateral;

    // TODO: Add data structures for user positions (e.g., mapping user => seriesId => position size).

    /**
     * @notice Initializes the ClearingHouse with necessary contract addresses and roles.
     * @param admin The address that will be granted the default admin, clearing admin, and liquidator roles.
     * @param _factory The address of the OptionFactory contract.
     * @param _token The address of the OptionToken contract.
     * @param _oracle The address of the price oracle contract.
     */
    constructor(address admin, address _factory, address _token, address _oracle) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CLEARING_ADMIN_ROLE, admin);
        _grantRole(LIQUIDATOR_ROLE, admin); // Admin can liquidate initially.
        optionFactory = OptionFactory(_factory);
        optionToken = OptionToken(_token);
        priceOracle = IOracle(_oracle);
    }

    /**
     * @notice Allows a user to deposit collateral to back their option positions.
     * @dev The implementation is pending. It should handle the transfer of a specified ERC20 token from the user to this contract and update the user's collateral balance.
     * @param _collateralToken The address of the ERC20 token to be used as collateral.
     * @param _amount The amount of the token to deposit.
     */
    function depositCollateral(address _collateralToken, uint256 _amount) external nonReentrant {
        // TODO: Implementation
        // 1. Check if _collateralToken is a valid collateral type.
        // 2. Transfer the token from the user to this contract.
        // 3. Update the user's collateral balance.
        IERC20(_collateralToken).transferFrom(msg.sender, address(this), _amount);
        collateral[msg.sender][_collateralToken] += _amount;
    }

    /**
     * @notice Settles an option series after it has expired.
     * @dev The implementation is pending. It should calculate the payout for an expired option series based on the settlement price from the oracle, and then distribute the collateral accordingly to the holders of the long and short positions. Anyone should be able to call this function after the option's expiry.
     * @param _seriesId The unique identifier for the option series to be settled.
     */
    function settleExpiredOption(bytes32 _seriesId) external nonReentrant {
        // TODO: Implementation
        // 1. Get series details from OptionFactory.
        // 2. Check that series.expiry < block.timestamp.
        // 3. Get the settlement price from the priceOracle.
        // 4. Calculate the payout per option (e.g., max(0, settlementPrice - strikePrice) for a call).
        // 5. For each position holder (long and short):
        //    a. Burn their option tokens (long and short).
        //    b. Settle the cash value by adjusting their collateral balances.
    }

    /**
     * @notice Liquidates an under-collateralized position.
     * @dev The implementation is pending. It should check if a user's position is sufficiently collateralized according to the current mark price from the oracle. If not, a liquidator can call this function to close the position and seize the collateral.
     * @param _user The address of the user whose position is being liquidated.
     * @param _seriesId The unique identifier for the option series of the position being liquidated.
     */
    function liquidatePosition(address _user, bytes32 _seriesId) external nonReentrant onlyRole(LIQUIDATOR_ROLE) {
        // TODO: Implementation
        // 1. Check the user's position and current margin requirements.
        // 2. Use the oracle price to value the position.
        // 3. If under-collateralized, close the position and seize collateral.
        // 4. A portion of the seized collateral may go to the liquidator as a fee.
    }
}
