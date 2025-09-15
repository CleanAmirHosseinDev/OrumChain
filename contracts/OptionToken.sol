// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title OptionToken
 * @author Your Name
 * @notice An ERC1155 contract to represent long and short positions in various option series.
 * @dev This is a skeleton contract for a fully featured options system. It is intended to be controlled by a `ClearingHouse` contract, which would have the `MINTER_ROLE` to mint and burn tokens as users open and close positions. The `OptionFactory` would be responsible for defining which token IDs are valid.
 */
contract OptionToken is ERC1155, AccessControl {
    /**
     * @dev Role for the entity (e.g., the ClearingHouse) authorized to mint and burn tokens.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Initializes the contract, setting up roles and the metadata URI.
     * @dev The URI is a template that allows ERC1155-compatible wallets and marketplaces to fetch metadata for each token ID.
     * @param admin The address that will receive the default admin role.
     * @param initialMinter The address that will be granted the `MINTER_ROLE` (e.g., the ClearingHouse).
     */
    constructor(
        address admin,
        address initialMinter
    ) ERC1155("https://api.boursechain.com/options/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, initialMinter);
    }

    /**
     * @notice Mints new option tokens.
     * @dev This function should be called by the `ClearingHouse` when a user opens a new position. It is restricted to addresses with the `MINTER_ROLE`.
     * @param to The address to receive the new tokens.
     * @param id The token ID, representing a specific side of an option series.
     * @param amount The number of tokens to mint.
     * @param data Additional data, which can be passed to the recipient.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    /**
     * @notice Burns option tokens.
     * @dev This function should be called by the `ClearingHouse` upon settlement or when a position is closed. The current implementation restricts this to the `MINTER_ROLE` as a proxy for the `ClearingHouse`.
     * @param from The address whose tokens will be burned.
     * @param id The token ID to burn.
     * @param amount The number of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) external {
        // In a full implementation, only the ClearingHouse should be able to trigger burns.
        // Using MINTER_ROLE as a proxy for the ClearingHouse/privileged contract.
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "OT: Caller is not authorized to burn"
        );
        _burn(from, id, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
