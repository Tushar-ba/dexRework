// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./DEXFactory.sol";
import "./DEXPair.sol";


//  * @title DEXRouter
//  * @notice This contract provides functions to add/remove liquidity and swap tokens in a decentralized exchange.
//  * It interacts with the factory and pair contracts to facilitate these operations.
//  */

contract DEXRouter {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

 
    //  * @notice Adds liquidity to a token pair.
    //  * @param tokenA The address of the first token.
    //  * @param tokenB The address of the second token.
    //  * @param amountADesired The desired amount of token A.
    //  * @param amountBDesired The desired amount of token B.
    //  * @param amountAMin The minimum amount of token A to add.
    //  * @param amountBMin The minimum amount of token B to add.
    //  * @return amountA The actual amount of token A added.
    //  * @return amountB The actual amount of token B added.
    //  * @return liquidity The amount of liquidity tokens minted.
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        address pair = DEXFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = DEXFactory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB,) = DEXPair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
        liquidity = DEXPair(pair).addLiquidity(amountA, amountB);
        return (amountA, amountB, liquidity);
    }


 
    //  * @notice Removes liquidity from a token pair.
    //  * @param tokenA The address of the first token.
    //  * @param tokenB The address of the second token.
    //  * @param liquidity The amount of liquidity tokens to burn.
    //  * @param amountAMin The minimum amount of token A to receive.
    //  * @param amountBMin The minimum amount of token B to receive.
    //  * @return amountA The actual amount of token A received.
    //  * @return amountB The actual amount of token B received.
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = DEXFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "PAIR_DOES_NOT_EXIST");

        (amountA, amountB) = DEXPair(pair).removeLiquidity(liquidity);

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        return (amountA, amountB);
    }

 
    //  * @notice Swaps an exact amount of tokens for another token.
    //  * @param amountIn The amount of input tokens.
    //  * @param amountOutMin The minimum amount of output tokens.
    //  * @param path The sequence of token addresses to swap through.
    //  * @param to The address to send the output tokens to.
    //  * @return amounts The amounts of tokens received after the swap.
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(path[0]).transferFrom(msg.sender, DEXFactory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
        return amounts;
    }


 
    //  * @notice Internal function to execute the token swap across pairs.
    //  * @param amounts The amounts of tokens for each step in the swap.
    //  * @param path The sequence of token addresses to swap through.
    //  * @param _to The address to send the final output tokens to.
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? DEXFactory(factory).getPair(output, path[i + 2]) : _to;
            DEXPair(DEXFactory(factory).getPair(input, output)).swap(amount0Out, amount1Out, to);
        }
    }

 
    //  * @notice Calculates the equivalent amount of token B for a given amount of token A based on reserves.
    //  * @param amountA The amount of token A.
    //  * @param reserveA The current reserve of token A.
    //  * @param reserveB The current reserve of token B.
    //  * @return amountB The calculated amount of token B.
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }



 
    //  * @notice Gets the amounts of tokens received for a given input amount along a swap path.
    //  * @param amountIn The amount of input tokens.
    //  * @param path The sequence of token addresses.
    //  * @return amounts The amounts of tokens for each step in the path.
    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut,) = DEXPair(DEXFactory(factory).getPair(path[i], path[i + 1])).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


  
    //  * @notice Calculates the amount of output tokens for a given input amount based on reserves.
    //  * @param amountIn The amount of input tokens.
    //  * @param reserveIn The current reserve of input tokens.
    //  * @param reserveOut The current reserve of output tokens.
    //  * @return amountOut The calculated amount of output tokens.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }



    
    //  * @notice Sorts token addresses in ascending order.
    //  * @param tokenA The first token address.
    //  * @param tokenB The second token address.
    //  * @return token0 The address of the first token.
    //  * @return token1 The address of the second token.
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}