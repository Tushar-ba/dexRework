// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DEXPair.sol";

contract DEXFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint256);

    // Function to create a new pair for two tokens
   function createPair(address tokenA, address tokenB) external returns (address pair) {
    require(tokenA != tokenB, "DEXFactory: IDENTICAL_ADDRESSES");
    require(tokenA != address(0) && tokenB != address(0), "DEXFactory: ZERO_ADDRESS");
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(getPair[token0][token1] == address(0), "DEXFactory: PAIR_EXISTS");

    // Deploy the pair contract
    pair = address(new DEXPair(token0, token1));
    getPair[token0][token1] = pair;  
    getPair[token1][token0] = pair;
    allPairs.push(pair);

    emit PairCreated(token0, token1, pair, allPairs.length);
}

    // Return total number of pairs created
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
