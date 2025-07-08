// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Constructor that mints the initial supply of tokens to the deployer.
 * @dev Initializes the ERC20 token with a name and symbol.
 */
contract MyToken is ERC20{
    constructor() ERC20("TokenARG", "TPS")

/**
 * @notice Mints the initial supply of tokens to the message sender.
 * @param msg.sender The address receiving the minted tokens.
 * @dev Mints 1000 tokens adjusted by the token's decimals.
 */
    {
        _mint(msg.sender, 1000 * 10 ** decimals());q
    
}
}
