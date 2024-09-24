// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract SimpleDEXPair {
    address public token0;
    address public token1;

    uint256 public reserve0;  // Token0 reserve
    uint256 public reserve1;  // Token1 reserve
    uint256 public totalSupply;  // Total supply of liquidity tokens

    mapping(address => uint256) public balanceOf;  // Liquidity token balances

    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    // Function to add liquidity to the pair
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0In = balance0 - _reserve0;
        uint256 amount1In = balance1 - _reserve1;

        require(amount0In > 0 && amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");

        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0In * amount1In) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);  // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = min(
                (amount0In * _totalSupply) / _reserve0,
                (amount1In * _totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(msg.sender, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0In, amount1In);
        return liquidity;
    }

    // Function to remove liquidity from the pair
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        balanceOf[msg.sender] -= liquidity;  // Optimistically transfer liquidity tokens
        totalSupply -= liquidity;

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        amount0 = (liquidity * balance0) / totalSupply;  // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        _update(balance0 - amount0, balance1 - amount1);
        emit Burn(msg.sender, amount0, amount1, msg.sender);
    }

    // Swap function
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 _reserve0, uint256 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        require(balance0 * balance1 >= uint256(_reserve0) * uint256(_reserve1), "K");

        _update(balance0, balance1);
        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
        emit Swap(msg.sender, 0, 0, amount0Out, amount1Out, to);
    }

    // Internal function to update reserves and emit Sync event
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }

    // Internal function to mint liquidity tokens
    function _mint(address to, uint256 value) private {
        totalSupply += value;
        balanceOf[to] += value;
    }

    // Function to get current reserves
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = uint32(block.timestamp % 2**32);
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

    // Helper function to get minimum of two values
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}