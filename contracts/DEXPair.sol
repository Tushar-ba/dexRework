// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract DEXPair {
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

    //  
    //  * @notice This function allows users to add liquidity to the token pair pool.
    //  * It calculates the amount of liquidity tokens to mint for the user based on the amount of token0 and token1 provided.
    //  * 
    //  * - First, it retrieves the current pool reserves and calculates how much of each token the user is adding.
    //  * - If it's the first time liquidity is being added to the pool, it uses the square root of the product of the token amounts to mint initial liquidity and locks a minimum amount (MINIMUM_LIQUIDITY).
    //  * - For subsequent liquidity additions, it calculates liquidity proportionally based on the user's input relative to the pool's reserves.
    //  * - It then mints the liquidity tokens to the user and updates the pool's reserves to reflect the new balances.
    //  * 
    //  * This ensures that liquidity is added in a balanced and fair way, maintaining the constant product invariant (x * y = k).
    //  

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



    // This function allows users to remove their liquidity from the token pair pool.
    //  * The user specifies the amount of liquidity to remove, and they receive back the corresponding amounts of token0 and token1.
    //  * - First, the function reduces the user's liquidity balance and the total supply of liquidity tokens.
    //  * - It then calculates the amounts of token0 and token1 that correspond to the withdrawn liquidity, ensuring proportional distribution based on the current pool balance.
    //  * - The function checks that the withdrawn amounts are valid and transfers token0 and token1 back to the user.
    //  * - Finally, it updates the pool's reserves to reflect the new balances and emits a `Burn` event to log the removal of liquidity.
    //  * This function ensures that liquidity is removed fairly and proportionally, maintaining the integrity of the pool's reserves and the constant product formula.

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


// This function facilitates the swapping of tokens between token0 and token1 in the pool.
//  * The user specifies the amount of tokens they want to withdraw (either amount0Out or amount1Out) and sends the corresponding amount of the other token.
//  * 
//  * - First, it ensures that the user is requesting a valid swap by checking that at least one output amount is greater than zero.
//  * - It retrieves the current pool reserves and checks that the user is not requesting more tokens than available in the reserves.
//  * - The function then calculates the new balances after the swap and verifies that the constant product (x * y = k) is maintained, ensuring the swap respects Uniswap's invariant.
//  * - After performing the checks, it updates the pool reserves, transfers the requested token amounts to the recipient, and emits a `Swap` event to log the transaction.
//  * 
//  * This function ensures that swaps are handled securely and in accordance with the constant product formula, preserving the pool's liquidity balance.
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

//  * This private function updates the pool's reserves with the new balances of token0 and token1.
//  * It is called after liquidity is added, removed, or a swap is executed.
//  * 
//  * - The function takes the new balances of token0 and token1 as inputs and updates the corresponding reserves (reserve0 and reserve1).
//  * - It then emits a `Sync` event to log the new state of the pool's reserves.
//  * 
//  * This function ensures that the pool's reserves are always in sync with the actual token balances in the contract, maintaining the accuracy of subsequent operations.
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }



//  * @notice This private internal function mints liquidity tokens for a specified address.
//  * It is used to create new liquidity tokens that represent a user's share of the liquidity pool.
//  * 
//  * - The function takes the recipient's address (`to`) and the amount of liquidity tokens to mint (`value`).
//  * - It increases the total supply of liquidity tokens by the specified value.
//  * - It also updates the balance of the recipient to reflect the newly minted tokens.
//  * 
//  * This function is called when liquidity is added to the pool, ensuring that users receive appropriate compensation for their contributions to the pool's liquidity.
    function _mint(address to, uint256 value) private {
        totalSupply += value;
        balanceOf[to] += value;
    }



//  * @notice This public view function retrieves the current reserves of token0 and token1 in the pool.
//  * It provides information about the amounts of each token held in the contract.
//  * 
//  * - The function returns the current reserves for token0 (`_reserve0`) and token1 (`_reserve1`).
//  * - It also returns the last block timestamp (`_blockTimestampLast`), which can be useful for tracking time-related events in the pool.
//  * - The block timestamp is wrapped to fit within a 32-bit unsigned integer to comply with certain data storage constraints.
//  * 
//  * This function is useful for external contracts and users who need to check the current state of the liquidity pool without modifying any state.
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = uint32(block.timestamp % 2**32);
    }

//  * @notice This internal pure function calculates the square root of a given non-negative integer.
//  * It implements the Newton-Raphson method for approximating square roots efficiently.
//  * 
//  * - If the input `y` is greater than 3, the function initializes `z` to `y` and uses an iterative approach to refine the estimate.
//  * - It continues updating `z` until it converges to a stable value, ensuring an accurate square root calculation.
//  * - If `y` is 0, the function returns 0; if `y` is a positive number less than or equal to 3, it returns 1.
//  * 
//  * This function is used in the liquidity calculation to determine the amount of liquidity tokens to mint when adding liquidity to the pool.
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
    

//  * @notice This internal pure function returns the minimum of two unsigned integers.
//  * It is a simple utility function used to compare two values and determine which one is smaller.
//  * 
//  * - The function takes two parameters, `x` and `y`, both of type `uint256`.
//  * - It evaluates whether `x` is less than `y` and returns `x` if true; otherwise, it returns `y`.
//  * 
//  * This function is often used in liquidity calculations and conditions where maintaining the lower of two values is necessary, such as when determining the amount of liquidity tokens to mint.
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}