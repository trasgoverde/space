//SPDX-License-Identifier: Unlicensed 

pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

contract Space is Context, ERC20, ERC20Detailed {
    constructor (
        string memory name
    ) {}
}    