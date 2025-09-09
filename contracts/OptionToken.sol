// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title OptionToken
 * @dev An ERC1155 contract to represent long and short positions in various option series.
 * This is a skeleton contract for future implementation.
 * The OptionFactory will be responsible for defining which token IDs are valid.
 */
contract OptionToken is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // The URI in an ERC1155 contract points to a JSON file that describes the token's metadata.
    constructor(address admin, address initialMinter) ERC1155("https://api.boursechain.com/options/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, initialMinter); // The ClearingHouse would likely be the minter.
    }

    /**
     * @dev Mints new option tokens. Typically called by the ClearingHouse when a user
     * opens a new position (e.g., sells a call and deposits collateral).
     * For each option series, there could be two token IDs: one for the long side (the buyer's token)
     * and one for the short side (the seller's token).
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Burns option tokens. Typically called by the ClearingHouse upon settlement or
     * when a position is closed.
     */
    function burn(address from, uint256 id, uint256 amount) external {
        // In a full implementation, only the ClearingHouse should be able to trigger burns.
        // This would require an additional access control check.
        require(hasRole(MINTER_ROLE, msg.sender), "OT: Caller is not the clearing house");
        _burn(from, id, amount);
    }
}
