// SPDX-License-Identifier: MIT
// SettleMint.com

pragma solidity ^0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title GenericToken
 * @notice This contract is a generic token adhering to the ERC20 standard,
 *  using the OpenZeppelin template libary for battletested functionality.
 *
 *  It incorporates the standard ERC20 functions, enhanced with Minting
 *  and Burning, Pausable in case of emergencies and AccessControl for locking
 *  down the administrative functions.
 *
 *  For demonstrative purposes, 1 million GT tokens are pre-mined to the address
 *  deploying this contract.
 */
contract GenericToken is ERC20, ERC20Burnable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     *
     * Emits a Transfer event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     *
     * @param amount       The amount of tokens to burn from the sender of the transaction, denominated by the
     * decimals() function
     */
    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
    }
}
