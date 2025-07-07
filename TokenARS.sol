// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20 Token Contract
/// @notice Basic ERC20 token with mint, buy, and sell functions
contract Token is ERC20 {

    /**
     * @notice Constructor that mints initial supply to recipient
     * @param recipient Address to receive the initial tokens
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(address recipient, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(recipient, 100000 * 10 ** decimals());
    }

    /**
     * @notice Mint tokens to a specified address
     * @param to Address to mint tokens to
     * @param amount Number of tokens to mint
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /**
     * @notice Buy tokens by sending Ether
     * @dev Mints tokens equal to the amount of Ether sent
     */
    function buy() public payable {
        _mint(msg.sender, msg.value);
    }

    /**
     * @notice Sell tokens in exchange for Ether
     * @param amount Amount of tokens to sell
     * @dev Transfers tokens to the contract and sends back Ether 1:1
     */
    function sell(uint256 amount) public payable {
        _transfer(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }
}
