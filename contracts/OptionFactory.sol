// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./OptionToken.sol";
import "./interfaces/IOracle.sol";

/**
 * @title OptionFactory
 * @dev Creates new option series for the derivatives module.
 * This is a skeleton contract for future implementation.
 */
contract OptionFactory is AccessControl {
    bytes32 public constant FACTORY_ADMIN_ROLE = keccak256("FACTORY_ADMIN_ROLE");

    OptionToken public optionToken;
    IOracle public priceOracle;
    address public clearingHouse;

    struct OptionSeries {
        address underlying;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    mapping(bytes32 => OptionSeries) public series;

    event SeriesCreated(bytes32 indexed seriesId, address underlying, uint256 strikePrice, uint256 expiry, bool isPut);

    constructor(address admin, address _optionToken, address _priceOracle, address _clearingHouse) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FACTORY_ADMIN_ROLE, admin);
        optionToken = OptionToken(_optionToken);
        priceOracle = IOracle(_priceOracle);
        clearingHouse = _clearingHouse;
    }

    /**
     * @dev Creates a new European, cash-settled option series.
     * In a full implementation, this might have more checks (e.g., expiry > now, valid strike).
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
