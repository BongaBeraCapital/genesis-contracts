// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "openzeppelin-contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

// import "./interfaces/Uniswap.sol";

contract TestUniswapOptimal {
    using SafeMath for uint256;

    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // import "@uniswap/lib/contracts/libraries/Babylonian.sol";
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        } else {
            z = 0;
        }
    }

    /*
  s = optimal swap amount
  r = amount of reserve for token a
  a = amount of token a the user currently has (not added to reserve yet)
  f = swap fee percent
  s = (sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r) / (2(1 - f))
  */
    function getSwapAmount(
        uint256 r,
        uint256 a,
        uint256 f
    ) public pure returns (uint256) {
        return (sqrt(((2 - f) * r) ^ (2 + 4 * (1 - f) * a * r)) - (2 - f) * r) / (2 * (1 - f));
    }

    /* optimal one-sided supply
  1. swap optimal amount from token A to token B
  2. add liquidity
  */
    function zap(
        address _tokenA,
        address _tokenB,
        uint256 _amountA
    ) external {
        require(_tokenA == WETH || _tokenB == WETH, "!weth");

        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);

        // address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
        // (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();

        // uint swapAmount;
        // if (IUniswapV2Pair(pair).token0() == _tokenA) {
        //   // swap from token0 to token1
        //   swapAmount = getSwapAmount(reserve0, _amountA);
        // } else {
        //   // swap from token1 to token0
        //   swapAmount = getSwapAmount(reserve1, _amountA);
        // }

        // _swap(_tokenA, _tokenB, swapAmount);
        // _addLiquidity(_tokenA, _tokenB);
    }

    function _swap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_from).approve(ROUTER, _amount);

        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        // IUniswapV2Router(ROUTER).swapExactTokensForTokens(
        //   _amount,
        //   1,
        //   path,
        //   address(this),
        //   block.timestamp
        // );
    }

    function _addLiquidity(address _tokenA, address _tokenB) internal {
        uint256 balA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balB = IERC20(_tokenB).balanceOf(address(this));
        IERC20(_tokenA).approve(ROUTER, balA);
        IERC20(_tokenB).approve(ROUTER, balB);

        // IUniswapV2Router(ROUTER).addLiquidity(
        //   _tokenA,
        //   _tokenB,
        //   balA,
        //   balB,
        //   0,
        //   0,
        //   address(this),
        //   block.timestamp
        // );
    }

    function getPair(address _tokenA, address _tokenB) external view returns (address) {
        return address(0); //IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
    }
}
