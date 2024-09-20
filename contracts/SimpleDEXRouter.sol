// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SimpleDEXFactory.sol";
import "./SimpleDEXPair.sol";

contract SimpleDEXRouter {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    // Add liquidity function
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        // Ensure pair exists or create a new one
        address pair = SimpleDEXFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = SimpleDEXFactory(factory).createPair(tokenA, tokenB);
        }

        // Add liquidity to the pair
        SimpleDEXPair(pair).addLiquidity(amountA, amountB);
    }

    // Remove liquidity function
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidityAmount) external {
        address pair = SimpleDEXFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");

        // Remove liquidity from the pair
        SimpleDEXPair(pair).removeLiquidity(liquidityAmount);
    }

    // Swap function
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external {
        address pair = SimpleDEXFactory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), "Pair does not exist");

        // Perform the swap on the pair
        SimpleDEXPair(pair).swap(amountIn, tokenIn, tokenOut);
    }
}
