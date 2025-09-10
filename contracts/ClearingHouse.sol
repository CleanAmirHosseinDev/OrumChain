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
 * @dev Manages collateral, settlement, and liquidation for the options module.
 * This is a skeleton contract for future implementation.
 */
contract ClearingHouse is AccessControl, ReentrancyGuard {
    bytes32 public constant CLEARING_ADMIN_ROLE = keccak256("CLEARING_ADMIN_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    OptionFactory public optionFactory;
    OptionToken public optionToken;
    IOracle public priceOracle;

    // Mapping from user to their collateral balance for a specific collateral type.
    mapping(address => mapping(address => uint256)) public collateral;

    // TODO: Add data structures for user positions (e.g., mapping user => seriesId => position size).

    constructor(address admin, address _factory, address _token, address _oracle) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CLEARING_ADMIN_ROLE, admin);
        _grantRole(LIQUIDATOR_ROLE, admin); // Admin can liquidate initially.
        optionFactory = OptionFactory(_factory);
        optionToken = OptionToken(_token);
        priceOracle = IOracle(_oracle);
    }

    /**
     * @dev User deposits collateral to back their positions.
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
     * @dev Settles an expired option series.
     * Anyone can call this after the expiry timestamp.
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
     * @dev Liquidates an under-collateralized position.
     * Only callable by an address with LIQUIDATOR_ROLE.
     */
    function liquidatePosition(address _user, bytes32 _seriesId) external nonReentrant onlyRole(LIQUIDATOR_ROLE) {
        // TODO: Implementation
        // 1. Check the user's position and current margin requirements.
        // 2. Use the oracle price to value the position.
        // 3. If under-collateralized, close the position and seize collateral.
        // 4. A portion of the seized collateral may go to the liquidator as a fee.
    }
}
