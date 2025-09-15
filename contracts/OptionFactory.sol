// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./OptionToken.sol";
import "./interfaces/IOracle.sol";

/**
 * @title OptionFactory
 * @author Your Name
 * @notice Creates new option series for the derivatives module.
 * @dev This is a skeleton contract for creating and managing option series. The core logic is intended for future implementation. It allows an admin to define new option series, which would then correspond to tokens in the `OptionToken` contract.
 */
contract OptionFactory is AccessControl {
    /**
     * @dev Role for administrators who can create new option series.
     */
    bytes32 public constant FACTORY_ADMIN_ROLE = keccak256("FACTORY_ADMIN_ROLE");

    /** @notice The `OptionToken` contract where option tokens (ERC1155) are managed. */
    OptionToken public optionToken;
    /** @notice The oracle used for getting asset prices for settlement. */
    IOracle public priceOracle;
    /** @notice The `ClearingHouse` contract for collateral and settlement. */
    address public clearingHouse;

    /**
     * @notice Represents the parameters of a single option series.
     * @param underlying The address of the underlying asset.
     * @param strikePrice The strike price of the option.
     * @param expiry The UNIX timestamp of the option's expiration.
     * @param isPut A boolean indicating if the option is a put (`true`) or a call (`false`).
     */
    struct OptionSeries {
        address underlying;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    /**
     * @notice Mapping from a series ID to the corresponding OptionSeries struct.
     */
    mapping(bytes32 => OptionSeries) public series;

    /**
     * @notice Emitted when a new option series is created.
     * @param seriesId The unique ID of the new series.
     * @param underlying The underlying asset.
     * @param strikePrice The strike price.
     * @param expiry The expiry timestamp.
     * @param isPut True if the option is a put, false otherwise.
     */
    event SeriesCreated(bytes32 indexed seriesId, address underlying, uint256 strikePrice, uint256 expiry, bool isPut);

    /**
     * @notice Initializes the factory with key contract addresses and admin roles.
     * @param admin The address that will be granted the default admin and factory admin roles.
     * @param _optionToken The address of the `OptionToken` contract.
     * @param _priceOracle The address of the price oracle contract.
     * @param _clearingHouse The address of the clearing house contract.
     */
    constructor(address admin, address _optionToken, address _priceOracle, address _clearingHouse) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FACTORY_ADMIN_ROLE, admin);
        optionToken = OptionToken(_optionToken);
        priceOracle = IOracle(_priceOracle);
        clearingHouse = _clearingHouse;
    }

    /**
     * @notice Creates a new European, cash-settled option series.
     * @dev This is a placeholder function. A full implementation would require more checks and interactions with the `OptionToken` contract. It generates a unique ID for the series and stores its details.
     * @param _underlying The underlying asset for the option.
     * @param _strikePrice The strike price for the option.
     * @param _expiry The expiration timestamp for the option.
     * @param _isPut True if the option is a put, false if it is a call.
     * @return seriesId The unique identifier for the newly created series.
     */
    function createOptionSeries(
        address _underlying,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external onlyRole(FACTORY_ADMIN_ROLE) returns (bytes32 seriesId) {
        // TODO: Implementation details
        // 1. Generate a unique ID for the series.
        seriesId = keccak256(abi.encodePacked(_underlying, _strikePrice, _expiry, _isPut));

        // 2. Store the series details.
        require(series[seriesId].expiry == 0, "OF: Series already exists");
        series[seriesId] = OptionSeries(_underlying, _strikePrice, _expiry, _isPut);

        // 3. The OptionToken (ERC1155) would have corresponding token IDs for the long and short side.
        //    e.g., uint256 longTokenId = uint256(seriesId);
        //    e.g., uint256 shortTokenId = uint256(seriesId) + 1;
        //    The OptionToken contract would need to be aware of these new valid tokens.

        emit SeriesCreated(seriesId, _underlying, _strikePrice, _expiry, _isPut);
    }
}
