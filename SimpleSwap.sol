// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleSwap is ERC20{

/**
* @notice Reserve of token A in the pool.
* @dev Updated during liquidity events and used for pricing and swaps.
*/
    uint256 private reserveA;

/**
* @notice Reserve of token B in the pool.
* @dev Updated during liquidity events and used for pricing and swaps.
*/
    uint256 private reserveB;

/**
* @notice Last block timestamp when reserves were updated.
* @dev Useful for price oracle or TWAP (time-weighted average price) calculations.
*/
    uint32 private blockTimestampLast;

/**
* @notice Minimum liquidity that must remain locked in the pool.
* @dev This is permanently locked to avoid division-by-zero and zero-liquidity edge cases.
*/
    uint private constant MINIMUM_LIQUIDITY = 10**3;

/**
* @notice Address where permanently locked tokens are sent.
* @dev Common burn address used to make tokens unrecoverable.
*/

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("SimpleSwap", "SWP"){}
     
/**
* @notice Emitted when liquidity tokens are minted.
* @param sender The address that added liquidity.
* @param amountA Amount of token A added.
* @param amountB Amount of token B added.
*/

    event Mint(address indexed sender, uint256 amountA, uint256 amountB);

/**
* @notice Emitted when liquidity tokens are burned and underlying tokens withdrawn.
* @param sender The address that removed liquidity.
* @param amountA Amount of token A withdrawn.
* @param amountB Amount of token B withdrawn.
* @param to The address receiving the withdrawn tokens.
*/

    event Burn(address indexed sender, uint256 amountA, uint256 amountB, address indexed to);

/**
* @notice Emitted when a swap between token A and token B occurs.
* @param sender The address that initiated the swap.
* @param amounts Array containing input and output amounts of the swap.
*/

    event Swap(address indexed sender, uint256[] amounts);

/**
* @notice Emitted when reserves of token A and token B are updated.
* @param reserveA Current reserve of token A.
* @param reserveB Current reserve of token B.
*/

    event Sync(uint256 reserveA, uint256 reserveB);

/**
* @notice Generic event to log uint values with a label.
* @param label Description label for the logged value.
* @param value The uint value being logged.
*/

    event LogUint(string label, uint256 value);

/**
* @notice Emitted when liquidity is minted.
* @param liquidity Amount of liquidity tokens minted.
*/

    event Liquidity(uint256 liquidity);

/**
* @notice Emitted to report the total supply of liquidity tokens.
* @param totalSupply Current total supply of liquidity tokens.
*/

    event TotalSupply(uint256 totalSupply);

/**
* @notice Updates the internal token reserves with the current balances.
* @dev This function should be called after any token transfer that affects reserves.
* @param balanceA The new balance of token A in the contract.
* @param balanceB The new balance of token B in the contract.
*/

    function _updateReserves(uint256 balanceA, uint256 balanceB) internal {
        reserveA = balanceA;
        reserveB = balanceB;
        emit Sync(reserveA, reserveB);
    }

/**
* @notice Calculates the optimal amounts of token A and token B to be added as liquidity,
* while respecting the current pool reserves and the minimum constraints.
* @dev Returns the adjusted amounts of tokenA and tokenB to preserve the pool ratio.
* Reverts if neither amount meets the minimum required.
* @param amountADesired The desired amount of token A to add.
* @param amountBDesired The desired amount of token B to add.
* @param amountAMin The minimum amount of token A to accept (to prevent slippage).
* @param amountBMin The minimum amount of token B to accept (to prevent slippage).
* @return amountA The final amount of token A to add.
* @return amountB The final amount of token B to add.
*/

    function getAmounts(
        uint256 amountADesired, 
        uint256 amountBDesired, 
        uint256 amountAMin,     
        uint256 amountBMin     
        ) internal view returns (uint256 amountA, uint256 amountB) {
            
        require(amountADesired > 0 && amountBDesired > 0, "INSUFFICIENT_AMOUNT");

        if (totalSupply() == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_AMOUNT");
                return (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_AMOUNT");
                return (amountAOptimal, amountBDesired);
            }
        }
    }
    
/**
* @notice Returns the price of tokenA in terms of tokenB, scaled by 1e18.
* @dev Assumes reserves are non-zero; reverts otherwise.
* @param tokenA The address of token A.
* @param tokenB The address of token B.
* @return price The price of tokenA denominated in tokenB, multiplied by 10^18 for precision.
*/

    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        require(reserveA > 0 && reserveB > 0, "NO_LIQUIDITY");

        if (tokenA < tokenB) {
            price = (reserveB * 1e18) / reserveA;
        } else {
            price = (reserveA * 1e18) / reserveB;
        }
    }

/**
* @notice Calculates the amount of tokenB received for a given amountIn of tokenA.
* @dev Uses current reserves to compute the output amount, assumes non-zero reserves.
* @param tokenA The address of the input token.
* @param tokenB The address of the output token.
* @param amountIn The amount of input token to swap.
* @return amountOut The calculated amount of output token that will be received.
*/
  
    function getAmountOut(address tokenA, address tokenB, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "NO_AMOUNT");

        uint256 _reserveIn;
        uint256 _reserveOut;

        if (tokenA < tokenB) {
            _reserveIn = reserveA;
            _reserveOut = reserveB;
        } else {
            _reserveIn = reserveB;
            _reserveOut = reserveA;
        }

        require(_reserveIn > 0 && _reserveOut > 0, "NO_LIQUIDITY");

        amountOut = (amountIn * _reserveOut) / (_reserveIn + amountIn);
    }

/**
* @notice Adds liquidity to the pool for tokenA and tokenB.
* @dev Transfers tokens from the caller and mints liquidity tokens to `to`.
* Respects minimum amounts to avoid front-running.
* @param tokenA The address of token A.
* @param tokenB The address of token B.
* @param amountADesired The desired amount of token A to add.
* @param amountBDesired The desired amount of token B to add.
* @param amountAMin The minimum amount of token A to add (slippage protection).
* @param amountBMin The minimum amount of token B to add (slippage protection).
* @param to The recipient address of liquidity tokens.
* @param deadline The timestamp by which the transaction must be confirmed.
* @return amountA The actual amount of token A added.
* @return amountB The actual amount of token B added.
* @return liquidity The amount of liquidity tokens minted.
*/

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
        )external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        uint256 _amountA = amountA;
        uint256 _amountB = amountB;
        address _tokenA = tokenA;
        address _tokenB = tokenB;
        uint256 _totalLiquidity = totalSupply();

        require(deadline >= block.timestamp, "TIME_EXPIRED");
              
        (_amountA, _amountB) = getAmounts(amountADesired, amountBDesired, amountAMin, amountBMin);  
        
       if (_totalLiquidity == 0) {
            _amountA = amountADesired;
            _amountB = amountBDesired;
            liquidity = Math.sqrt(_amountA * _amountB) - MINIMUM_LIQUIDITY;
            _mint(BURN_ADDRESS, MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY token
        } else {
            liquidity = Math.min(_amountA / reserveA , _amountB / reserveB) * _totalLiquidity;
        }
        emit Liquidity(liquidity);

        ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        ERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);
        require(liquidity > 0, "NO_LIQUIDITY");
       
        _mint (to, liquidity);
        emit Mint(to,_amountA, _amountB );

        uint256 balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(_tokenB).balanceOf(address(this));
        
        _updateReserves(balanceA, balanceB);

        return (_amountA, _amountB, liquidity);
    }

/**
 * @notice Removes liquidity from the pool and returns the underlying tokens to the user.
 * @dev Burns the specified amount of liquidity tokens and transfers tokenA and tokenB back to `to`.
 * Ensures minimum amounts to protect against front-running.
 * @param tokenA The address of token A.
 * @param tokenB The address of token B.
 * @param liquidity The amount of liquidity tokens to burn.
 * @param amountAMin The minimum amount of token A to receive (slippage protection).
 * @param amountBMin The minimum amount of token B to receive (slippage protection).
 * @param to The recipient address of the underlying tokens.
 * @param deadline The timestamp by which the transaction must be confirmed.
 * @return amountA The amount of token A returned.
 * @return amountB The amount of token B returned.
 */

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
        ) external returns (uint256 amountA, uint256 amountB){
        uint256 _amountA = amountA;
        uint256 _amountB = amountB;
        address _tokenA = tokenA;
        address _tokenB = tokenB;
        uint256 _totalLiquidity = totalSupply();

        require(block.timestamp <= deadline, "TIME_EXPIRED");

        _amountA = (liquidity * reserveA) / _totalLiquidity;
        _amountB = (liquidity * reserveB) / _totalLiquidity;

        ERC20(_tokenA).transfer(to, _amountA);
        ERC20(_tokenB).transfer(to, _amountB);

        require(_amountA > 0 && _amountB > 0, "NO_LIQUIDITY");
        require(_amountA >= amountAMin, "INSUFFICIENT_AMOUNT");
        require(_amountB >= amountBMin, "INSUFFICIENT_AMOUNT");

        _burn(to, liquidity);
        
        emit Burn(msg.sender, _amountA, _amountB, to);
        
        uint256 _balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint256 _balanceB = ERC20(_tokenB).balanceOf(address(this));
       
        _updateReserves(_balanceA, _balanceB);

        return (_amountA, _amountB);
    }

/**
 * @notice Swaps an exact amount of input tokens for as many output tokens as possible,
 *         following the path of token addresses.
 * @param amountIn The exact amount of input tokens to swap.
 * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
 * @param path An array of token addresses representing the swap path. Must have length 2.
 * @param to The address that will receive the output tokens.
 * @param deadline The timestamp by which the transaction must be confirmed.
 * @return amounts An array containing input and output amounts for the swap.
 */
 
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
        ) external returns  (uint256[] memory amounts){
        uint256 _amountIn = amountIn;

        require(block.timestamp <= deadline, "TIME_EXPIRED");     
        require(path.length == 2, "INVALID_PATH");

        address _tokenA = path[0];
        address _tokenB = path[1];

        uint256 _amountOut = getAmountOut(_tokenA, _tokenB, _amountIn) ;
        require(_amountOut >= amountOutMin, "LIMITE_EXCEEDED");
        
        require(ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountIn),"TRANSFER_FAILED");
        require(ERC20(_tokenB).transfer( to, _amountOut), "TRANFFER_FAILED");
       
        amounts = new uint256[](2);
        amounts[0] = _amountIn;
        amounts[1] = _amountOut;
        
        uint256 _balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint256 _balanceB = ERC20(_tokenB).balanceOf(address(this));
        _updateReserves(_balanceA, _balanceB);
       
        emit Swap(to, amounts);
        return amounts;
    }
}
