// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SimpleSwap is ERC20, Ownable {


    uint256 private reserveA;           // uses single storage slot, accessible via getReserves
    uint256 private reserveB;           // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves
    mapping(address account => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    mapping(address => uint256) public initializedTokens;         // track initialized tokens to avoid multiple initializations
    address[] public tokens;                 // List of initialized tokens. Updated through initialize()
    mapping(address => uint256) internal tokensOwned;     // track tokens owned by the contract,
    
    uint256 public priceACumulativeLast;
    uint256 public priceBCumulativeLast;
    uint256 public kLast; // reserveA * reserveB, as of immediately after the most recent liquidity event

     constructor(address initialOwner) ERC20("SimpleSwap", "SWP") Ownable(initialOwner){}
     
    
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Burn(address indexed sender, uint256 amountA, uint256 amountB, address indexed to);
    event Swap(address indexed sender, uint256[] amounts);
    event Sync(uint256 reserveA, uint256 reserveB);

    function initialize(address tokenA, address tokenB) external {
        assert(msg.sender != address(0));
        assert(tokenA != address(0) && tokenB != address(0));
        tokens = [tokenA ,tokenB];
        require(msg.sender == owner(), 'SimpleSwap: FORBIDDEN'); // sufficient check
    }

    function balanceOf(address account) override public view virtual returns (uint256) {
        return _balances[account];
    }

    function getReserves() public view returns (uint256 _reserveA, uint256 _reserveB, uint32 _blockTimestampLast) {
        _reserveA = reserveA;
        _reserveB = reserveB;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SimpleSwap: TRANSFER_FAILED');
    }

    function _updateReserves( address tokenA, address tokenB) internal {
        
        uint256 _balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 _balanceB = IERC20(tokenB).balanceOf(address(this));

        require(_balanceA <= type(uint256).max && _balanceB <= type(uint256).max, 'SimpleSwap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserveA = _balanceA;
        reserveB = _balanceB;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserveA, reserveB);
    }

    function getLiquidity( 
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _amountA,
        uint256 _amountB)
        internal view returns (uint256 liquidity){
            uint256 totalSupply = totalSupply();

            if (totalSupply == 0) {
                liquidity = Math.sqrt(_amountA * _amountB) - (MINIMUM_LIQUIDITY);
            }
            liquidity = totalSupply * 
            (Math.min(_amountA / _reserveA ,
                      _amountA  / _reserveB ));
        return liquidity;
    }

    function getPrice (address tokenA, address tokenB) internal view returns (uint256 price) {
        require(tokenA != tokenB, "Identical tokens");
        (uint256 _reserveA, uint256 _reserveB,) = getReserves(); // gas savings

        require(_reserveA != 0 && _reserveB != 0,'SimpleSwap: ZERO_RESERVE');
        uint256 amountIn = IERC20(tokenA).balanceOf(address(this));
        price = (amountIn) * (_reserveB) / (_reserveA + amountIn );
        return price;
    }
 
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
        ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        uint256 _amountADesired = amountADesired;
        uint256 _amountBDesired = amountBDesired;
             
        uint256 _amountA = amountA;
        uint256 _amountB = amountB;
   
        require(deadline >= block.timestamp, "SimpleSwap: EXPIRED");

        _updateReserves(tokenA, tokenB);
        (uint256 _reserveA, uint256 _reserveB,) = getReserves();
        require(_reserveA > 0 && _reserveB > 0, "Insufficient liquidity");

        uint256 _amountAOptimal = (_amountADesired * _reserveB / _reserveA);
        uint256 _amountBOptimal = (_amountBDesired  * _reserveA / _reserveB );

        // Select optimal amounts
        if(_amountAOptimal <= _amountADesired){
        require(amountAMin >=_amountAOptimal, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
            _amountA =  _amountADesired;
            _amountB= _amountBOptimal;
        }else if (_amountBOptimal <= _amountBDesired) {
            require(_amountBOptimal >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");
            amountA = _amountADesired;
            amountB = _amountBOptimal;

        }
 
        liquidity = getLiquidity(_reserveA,_reserveB,_amountA, _amountB);

        _mint (to, liquidity);
        emit Mint(msg.sender,_amountA, _amountB );
         return (_amountA, _amountB, liquidity);
}
     
 
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
        ) external returns (uint256 amountA, uint256 amountB){
        address _tokenA = tokenA;
        address _tokenB = tokenB;
        uint256 _amountA = amountA;
        uint256 _amountB = amountB;
        uint256 _liquidity = liquidity;

        require(block.timestamp > deadline, "SimpleSwap: EXPIRED");
        (uint256 _reserveA, uint256 _reserveB,) = getReserves(); // gas savings
        _totalSupply = totalSupply();

        _amountA = (_balances[to] * _reserveA) / _totalSupply;
        _amountB = (_balances[to] * _reserveB) / _totalSupply;
        liquidity = getLiquidity(_reserveA, _reserveB ,_amountA,_amountB);
        require(_liquidity > 0, "SimpleSwap: ZERO_LIQUIDITY");

        require(_amountA> 0 && _amountB > 0, 'SimpleSwapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        require(_amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
        require(_amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");

        _burn(to, _liquidity);

        IERC20(_tokenA).transfer(to, _amountA);
        IERC20(_tokenB).transfer(to, _amountB);
      
        _updateReserves( _tokenA, _tokenB);
 
        emit Burn(msg.sender, amountA, amountB, to);
        kLast = uint256(reserveA)  * (reserveB);
        return (amountA, amountB);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
        ) external returns  (uint256[] memory amounts){

        require(block.timestamp <= deadline, "SimpleSwap: EXPIRED");     
        require(IERC20(msg.sender).transferFrom(msg.sender, address(this), amountIn),"Transfer of tokenIn failed");

        uint256 _balanceA = IERC20(path[0]).balanceOf(address(this));
        uint256 _balanceB = IERC20(path[1]).balanceOf(address(this));


        (uint256 _reserveA, uint256 _reserveB,) = getReserves();
        require(_reserveA > 0 && _reserveB > 0, "Insufficient liquidity");
        uint256 amountOut = amountIn * _reserveB / _reserveA;
        require(amountOut >= amountOutMin, "Slippage limit exceeded");

        require(IERC20(path[1]).transferFrom(address(this), to, amountOut), "Transfer of tokenOut failed");

        amounts[0] = amountIn;
        amounts[1] = amountOut;

        _balanceA = balanceOf(path[0]);
        _balanceB = balanceOf(path[1]);

        emit Swap(msg.sender, amounts);
        return amounts;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut){
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid inputs");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn + amountIn);
        return amountOut ;
    }
}