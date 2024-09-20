// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract SimpleDEXPair {
    address public token0;
    address public token1;

    uint256 public reserve0;  // Token0 reserve
    uint256 public reserve1;  // Token1 reserve
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidity;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    // Modifier to ensure correct amounts
    modifier validAmounts(uint256 amount0, uint256 amount1) {
        require(amount0 > 0 && amount1 > 0, "Invalid token amounts");
        _;
    }

    // Function to add liquidity to the pair
    function addLiquidity(uint256 amount0, uint256 amount1) external validAmounts(amount0, amount1) {
        // Transfer tokens from the user to this contract
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint256 liquidityMinted = sqrt(amount0 * amount1);  // Calculate liquidity to mint
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }

    // Function to remove liquidity from the pair
    function removeLiquidity(uint256 liquidityAmount) external {
        require(liquidity[msg.sender] >= liquidityAmount, "Not enough liquidity");

        uint256 amount0 = (reserve0 * liquidityAmount) / totalLiquidity;
        uint256 amount1 = (reserve1 * liquidityAmount) / totalLiquidity;

        // Transfer tokens back to the user
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }

    // Swap function
    function swap(uint256 amountIn, address tokenIn, address tokenOut) external {
        require(tokenIn == token0 || tokenIn == token1, "Invalid input token");
        require(tokenOut == token0 || tokenOut == token1, "Invalid output token");

        uint256 reserveIn = tokenIn == token0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenIn == token0 ? reserve1 : reserve0;

        // Calculate output amount based on constant product formula (x * y = k)
        uint256 amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);

        // Transfer tokenIn from user and transfer tokenOut to user
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }

    // Helper function to calculate square root
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
        }
    }
}
