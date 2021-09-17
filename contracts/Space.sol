/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// File: node_modules\@openzeppelin\contracts-upgradeable\token\ERC20\IERC20Upgradeable.sol

// SPDX-License-Identifier: MIT

/**
*This is the official contract of Spacelens and its SPACE token https://spacelens.com

*The world of shopping and commerce must be managed and governed by its participants.

*You must possess your data, privacy and control over your funds.

*Sellers must control their listings, products, services, inventions, creations, designs, stories, stores.
 
*Consumers must be able shop with privacy, freedom and trustworthy information. 

*You’re not a product anymore. We are developing advanced solutions to improve commerce and the economy at large.
 */

pragma solidity  0.5.16 < 0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract SimpleToken is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("Space", "SPACE", 18) {
        _mint(msg.sender, 10000 * (10 ** uint256(decimals())));
    }
}