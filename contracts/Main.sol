// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.0 <0.9.0;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

import "./SimpleSwap.sol";
contract Main{

    SimpleSwap public swap;
constructor () {
  swap = new SimpleSwap();
}
}
