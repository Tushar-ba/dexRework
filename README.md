#  DEX README

## Installation and other process
- clone the repo and `npm install` <br/>
- `npx hardhat compile` to compile the project  <br/>
- add <br/> 
  POLYGON_API_KEY= <br/>
  PRIVATE_KEY= <br/>
  in a .env file <br/>
- `npx hardhat run scripts/depoly.js --network mumbai`    to deploy the contract

## Overview

The DEX (Decentralized Exchange) is a Solidity smart contract implementation that facilitates the swapping of ERC20 tokens and allows users to provide liquidity to token pairs. This contract leverages a constant product market maker mechanism, ensuring efficient and fair trades while maintaining liquidity.

## Components

### 1. **DEXRouter**
The `DEXRouter` contract is responsible for managing liquidity and facilitating token swaps. It interacts with the `DEXFactory` and `DEXPair` contracts to perform the following operations:

- **Add Liquidity**: Users can add liquidity to a token pair.
- **Remove Liquidity**: Users can withdraw their liquidity from a token pair.
- **Token Swaps**: Users can swap an exact amount of one token for another.

### 2. **DEXFactory**
The `DEXFactory` contract creates and manages token pairs. It allows the creation of new liquidity pools for any two ERC20 tokens and keeps track of all pairs created.

### 3. **DEXPair**
The `DEXPair` contract holds the reserves for two tokens, handles the minting and burning of liquidity tokens, and facilitates swaps between the two tokens.

## Mechanism

### Constant Product Formula
The  DEX uses the constant product formula \(x * y = k\) to maintain liquidity and pricing for token swaps. Here, \(x\) and \(y\) represent the reserves of the two tokens in a pair, and \(k\) is a constant that must remain unchanged after every swap or liquidity addition/removal. This ensures that the product of the reserves remains constant, providing a predictable pricing mechanism for trades.

### Adding Liquidity
When liquidity is added through the `addLiquidity` function, the contract calculates the optimal amounts of both tokens to be added based on the current reserves. The following mathematical logic is applied:

- If the pool is empty, the user adds the desired amounts directly.
- If the liquidity pool already has reserves, the function calculates the optimal amount of the second token required for the added amount of the first token using the following formula:

`amountBOptimal=quote(amountADesired,reserveA,reserveB)`
Where:

amountADesired
amountADesired is the amount of the first token you want to add.
reserveA
reserveA is the current reserve of the first token in the pool.
reserveB
reserveB is the current reserve of the second token in the pool.
The quote function typically determines the amount of token B that corresponds to the desired amount of token A, maintaining the constant product invariant of the AMM, ensuring that the prices between the two tokens remain balanced according to their reserves.

### Removing Liquidity
When removing liquidity with the `removeLiquidity` function, the contract calculates the amounts of tokens to return based on the user's share of the total liquidity. This ensures that withdrawals are proportionate to the user's contribution to the pool.

### Swapping Tokens
For token swaps, the `swapExactTokensForTokens` function calculates how many output tokens the user will receive for a given input amount using the following logic:

- It uses the `getAmountsOut` function, which calculates the output amounts based on current reserves and the desired input amount:
  `amountOut = getAmountOut(amountIn, reserveIn, reserveOut)`
  
- The fee for swaps is applied, reducing the effective amount received by the recipient.

### Example Calculations

1. **Adding Liquidity Example**:
   - If a user wants to add 100 Token A and the current reserves are 200 Token A and 300 Token B, the optimal amount of Token B to be added can be calculated as:
   \[
   \text{amountBOptimal} = \frac{100 \times 300}{200} = 150
   \]
   - If the user only wants to add 140 Token B, the contract will adjust the amounts accordingly to maintain the balance.

2. **Swapping Example**:
   - If a user swaps 10 Token A and the current reserves are 500 Token A and 800 Token B, the output amount can be calculated as follows:
   \[
   \text{amountOut} = \frac{10 \times 997 \times 800}{(500 \times 1000) + (10 \times 997)} = \text{Calculated Amount}
   \]

## Events
The contract emits several events to log actions such as adding or removing liquidity, executing swaps, and creating new pairs. This provides transparency and traceability for all operations within the DEX.

### Conclusion
The  DEX implementation is a robust decentralized exchange solution that leverages automated market-making principles to enable seamless token swaps and liquidity management. The design is modular, allowing easy integration and customization for various token pairs and ERC20 tokens. 

For more detailed technical specifications, please refer to the individual contracts: `DEXRouter`, `DEXFactory`, and `DEXPair`.



MINIMUM_LIQUIDITY
The contract permanently locks a small amount of liquidity (set as 10^3 tokens) when the first liquidity is added. This ensures that the pool always has some liquidity and can’t be completely drained.

Below is the contract address of Factory and Router verified on the polyscan amoy 

           

TokenA deployed to: 0xa9d4b4f1AE414aDF72136A6aA4beb6CE466ADEB0 <br/>
TokenB deployed to: 0xBffa111F747430E84c742204a92AC199e6Be89b5 <br/>
DEXFactory deployed to: 0x2aCEE593a577a5FeDC84917DF981D6d93961331a <br/>
DEXRouter deployed to: 0x2258Db39FCdAB899661fBA6a1246Cc7a0F4E9ff0 <br/>
Approvals set for DEXRouter to spend TokenA and TokenB. <br/>
Pair created at: 0x3E5C2Cb2F42c91F13F96Ad12aB2956626f2be591



# Verified contract link 
## Factory 
https://amoy.polygonscan.com/address/0x2aCEE593a577a5FeDC84917DF981D6d93961331a#code    

## Router
https://amoy.polygonscan.com/address/0x2258Db39FCdAB899661fBA6a1246Cc7a0F4E9ff0#code
