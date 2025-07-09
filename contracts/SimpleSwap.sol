// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleSwap is ERC20 {
    constructor() ERC20("SimpleSwap", "SWP") {}

    /**
     * @notice Emitted when liquidity is added to the pool.
     * @param provider The address that provided the liquidity.
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @param amountA Amount of token A added.
     * @param amountB Amount of token B added.
     * @param liquidity Amount of liquidity tokens minted.
     */

    event LiquidityAdded(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @notice Emitted when liquidity is removed from the pool.
     * @param provider The address that removed the liquidity.
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @param amountA Amount of token A returned.
     * @param amountB Amount of token B returned.
     * @param liquidity Amount of liquidity tokens burned.
     */

    event LiquidityRemoved(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @notice Emitted when a swap is executed.
     * @param sender Address initiating the swap.
     * @param tokenIn Token sent to the pool.
     * @param tokenOut Token received from the pool.
     * @param amountIn Amount of input token swapped.
     * @param amountOut Amount of output token received.
     * @param recipient Address receiving the output tokens.
     */

    event TokenSwapped(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );

    /**
     * @notice Error for when a token amount is zero or less than the minimum required.
     * @param requested The minimum amount requested or expected.
     * @param available The actual available or provided amount.
     */

    error InsufficientAmount(uint256 requested, uint256 available);

    /**
     * @notice Error for when the liquidity is insufficient or zero.
     * @param liquidity The liquidity amount calculated or provided.
     */

    error InsufficientLiquidity(uint256 liquidity);

    /**
     * @notice Error for when the output amount from a swap is less than the minimum required.
     * @param requested The minimum output amount expected.
     * @param actual The actual output amount calculated.
     */

    error InsufficientOutputAmount(uint256 requested, uint256 actual);

    /**
     * @notice Error for when the swap path length is invalid (not equal to 2).
     * @param length The length of the provided path array.
     */

    error InvalidPathLength(uint256 length);

    /**
     * @notice Error for when a token transfer operation fails.
     * @param token The address of the token contract.
     * @param from The sender address of the tokens.
     * @param to The recipient address of the tokens.
     * @param amount The amount of tokens attempted to transfer.
     */

    error TransferFailed(
        address token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @notice Error for when the transaction deadline has expired.
     * @param currentTimestamp The current block timestamp.
     * @param deadline The deadline timestamp specified by the transaction.
     */

    error DeadlineExpired(uint256 currentTimestamp, uint256 deadline);

    /**
     * @notice Error for when liquidity reserves are zero, making calculations impossible.
     */

    error ZeroLiquidity();

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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "DEADLINE_EXPIRED");
        address _tokenA = tokenA;
        address _tokenB = tokenB;

        uint256 reserveA = ERC20(_tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(_tokenB).balanceOf(address(this));

        if (totalSupply() == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            uint256 inputRatioA = (amountADesired * 1e18) / reserveA;
            uint256 inputRatioB = (amountBDesired * 1e18) / reserveB;

            if (inputRatioA < inputRatioB) {
                amountA = amountADesired;
                amountB = (getPrice(_tokenA, _tokenB) * amountA) / 1e18;
                if (amountA < amountAMin)
                    revert InsufficientAmount(amountAMin, amountA);
            } else {
                amountB = amountBDesired;
                amountA = getPrice(_tokenB, _tokenA) * amountB;
                if (amountB < amountBMin)
                    revert InsufficientAmount(amountBMin, amountB);
            }
            liquidity = Math.min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        ERC20(_tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(_tokenB).transferFrom(msg.sender, address(this), amountB);

        _mint(to, liquidity);
        emit LiquidityAdded(
            msg.sender,
            _tokenA,
            _tokenB,
            amountA,
            amountB,
            liquidity
        );

        return (amountA, amountB, liquidity);
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
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "DEADLINE_EXPIRED");

        uint256 totalLiquidity = totalSupply();
        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));

        amountA = (liquidity * balanceA) / totalLiquidity;
        amountB = (liquidity * balanceB) / totalLiquidity;

        if (amountA < amountAMin)
            revert InsufficientAmount(amountAMin, amountA);
        if (amountB < amountBMin)
            revert InsufficientAmount(amountBMin, amountB);

        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);

        _burn(msg.sender, liquidity);
        emit LiquidityRemoved(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            liquidity
        );

        return (amountA, amountB);
    }

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible,
     * following the path of token addresses.
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
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "DEADLINE_EXPIRED");

        if (path.length != 2) revert InvalidPathLength(path.length);

        address tokenA = path[0];
        address tokenB = path[1];

        uint256 reserveA = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(tokenB).balanceOf(address(this));

        if (!ERC20(tokenA).transferFrom(msg.sender, address(this), amountIn)) {
            revert TransferFailed(tokenA, msg.sender, address(this), amountIn);
        }

        uint256 amountOut = getAmountOut(amountIn, reserveA, reserveB);
        if (amountOut < amountOutMin) {
            revert InsufficientOutputAmount(amountOutMin, amountOut);
        }

        if (!ERC20(tokenB).transfer(to, amountOut)) {
            revert TransferFailed(tokenB, address(this), to, amountOut);
        }

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokenSwapped(msg.sender, tokenA, tokenB, amountIn, amountOut, to);

        return amounts;
    }

    /**
     * @notice Returns the price of tokenA in terms of tokenB, scaled by 1e18.
     * @dev Assumes reserves are non-zero; reverts otherwise.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @return price The price of tokenA denominated in tokenB, multiplied by 10^18 for precision.
     */

    function getPrice(
        address tokenA,
        address tokenB
    ) public view returns (uint256 price) {
        uint256 reserveA = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(tokenB).balanceOf(address(this));
        if (reserveA == 0 || reserveB == 0) revert ZeroLiquidity();

        price = (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Calculates the amount of tokenB received for a given amountIn of tokenA.
     * @dev Uses current reserves to compute the output amount, assumes non-zero reserves.
     * @param amountIn The amount of input token to swap.
     * @return amountOut The calculated amount of output token that will be received.
     */

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        if (reserveIn == 0 || reserveOut == 0) revert ZeroLiquidity();
        if (amountIn == 0) revert InsufficientAmount(0, amountIn);

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
