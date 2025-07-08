🧪 Final Project Module 3: Implementation of SimpleSwap
🎯 Objective
Create a smart contract called SimpleSwap that allows users to:

Add and remove liquidity.
Swap tokens.
Get prices and calculate output amounts.
The contract replicates the basic functionality of Uniswap without relying on its protocol.

📢 Requirements
1️⃣ Add Liquidity (addLiquidity)
Description:
Allows users to add liquidity to a token pair in an ERC-20 pool.

Interface:

function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
Tasks:

Transfer tokens from the user to the contract.
Calculate and assign liquidity according to reserves.
Mint liquidity tokens to the user.
Parameters:

tokenA, tokenB: Token addresses.
amountADesired, amountBDesired: Desired token amounts.
amountAMin, amountBMin: Minimum acceptable amounts.
to: Recipient address.
deadline: Transaction deadline.
Returns:

amountA, amountB, liquidity: Actual amounts and liquidity minted.
2️⃣ Remove Liquidity (removeLiquidity)
Description:
Allows users to withdraw liquidity from an ERC-20 pool.

Interface:

function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB);
Tasks:

Burn the user’s liquidity tokens.
Calculate and return token A and B amounts.
Parameters:

tokenA, tokenB: Token addresses.
liquidity: Amount of liquidity tokens to remove.
amountAMin, amountBMin: Minimum acceptable amounts.
to: Recipient address.
deadline: Transaction deadline.
Returns:

amountA, amountB: Amounts received after liquidity removal.
3️⃣ Swap Tokens (swapExactTokensForTokens)
Description:
Allows swapping an exact amount of one token for as many output tokens as possible.

Interface:

function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns (uint[] memory amounts);
Tasks:

Transfer input tokens from the user to the contract.
Calculate the swap according to reserves.
Transfer output tokens to the user.
Parameters:

amountIn: Input token amount.
amountOutMin: Minimum acceptable output amount.
path: Array of token addresses (input → output).
to: Recipient address.
deadline: Transaction deadline.
Returns:

amounts: Array with input and output amounts.
4️⃣ Get Price (getPrice)
Description:
Gets the price of one token in terms of another.

Interface:

function getPrice(
    address tokenA,
    address tokenB
) external view returns (uint price);
Tasks:

Retrieve the reserves of both tokens.
Calculate and return the price.
Parameters:

tokenA, tokenB: Token addresses.
Return:

price: Price of tokenA denominated in tokenB.
5️⃣ Calculate Output Amount (getAmountOut)
Description:
Calculates how many output tokens will be received for a swap.

Interface:

function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) external pure returns (uint amountOut);
Tasks:

Calculate and return the output amount.
Parameters:

amountIn: Input token amount.
reserveIn, reserveOut: Current reserves in the contract.
Return:

amountOut: Output token amount.
