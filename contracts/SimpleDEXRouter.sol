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

    // In SimpleDEXRouter.sol
event TokensTransferred(address token, address to, uint256 amount);
event LiquidityAddAttempt(address tokenA, address tokenB, uint256 amountA, uint256 amountB);
event PairCreationAttempt(address tokenA, address tokenB);

// Inside addLiquidity function
function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
    emit LiquidityAddAttempt(tokenA, tokenB, amountA, amountB);

    // Ensure the pair exists or create a new one
    address pair = SimpleDEXFactory(factory).getPair(tokenA, tokenB);
    if (pair == address(0)) {
        emit PairCreationAttempt(tokenA, tokenB);
        pair = SimpleDEXFactory(factory).createPair(tokenA, tokenB);
    }

    // Transfer tokens to the pair
    bool transferA = IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
    emit TokensTransferred(tokenA, pair, amountA);

    bool transferB = IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
    emit TokensTransferred(tokenB, pair, amountB);
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
