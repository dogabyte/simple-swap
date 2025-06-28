// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Token is ERC20 {
  

    constructor(address recipient, string memory _name, string memory _symbol)
        ERC20( _name, _symbol)
    
    {
        _mint(recipient, 100000 * 10 ** decimals());

    }

    function mint(address to, uint256 amount) public{
        _mint(to, amount);
    }

       function buy() public payable {
        _mint(msg.sender, msg.value);
    }

    function sell(uint256 amount) public payable {
        _transfer(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }


}