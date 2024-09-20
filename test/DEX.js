const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleDEXRouter", function () {
  let dexRouter, dexFactory, tokenA, tokenB, owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // Deploy MockERC20 for tokenA
    const TokenA = await ethers.getContractFactory("MockERC20");
    tokenA = await TokenA.deploy("TokenA", "TKA", 18, ethers.parseUnits("1000000", 18));

    // Deploy MockERC20 for tokenB
    const TokenB = await ethers.getContractFactory("MockERC20");
    tokenB = await TokenB.deploy("TokenB", "TKB", 18, ethers.parseUnits("1000000", 18));

    // Deploy the SimpleDEXFactory
    const DEXFactory = await ethers.getContractFactory("SimpleDEXFactory");
    dexFactory = await DEXFactory.deploy();

    // Deploy the SimpleDEXRouter with the factory address
    const DEXRouter = await ethers.getContractFactory("SimpleDEXRouter");
    dexRouter = await DEXRouter.deploy(await dexFactory.getAddress());
  });

  async function addInitialLiquidity(amountA, amountB) {
    const tokenAAddress = await tokenA.getAddress();
    const tokenBAddress = await tokenB.getAddress();
    const routerAddress = await dexRouter.getAddress();

    console.log("Creating pair...");
    await dexRouter.addLiquidity(tokenAAddress, tokenBAddress, amountA, amountB);
    
    console.log("Pair created, getting pair address...");
    const pairAddress = await dexFactory.getPair(tokenAAddress, tokenBAddress);
    console.log("Pair address:", pairAddress);

    console.log("Approving tokens for pair...");
    
    // Approve the pair to spend tokenA and tokenB
    await tokenA.approve(pairAddress, amountA);
    await tokenB.approve(pairAddress, amountB);

    const SimpleDEXPair = await ethers.getContractFactory("SimpleDEXPair");
    const pair = SimpleDEXPair.attach(pairAddress);

    console.log("Adding liquidity to pair...");
    
    // Ensure this call happens after approval
    await pair.addLiquidity(amountA, amountB);

    return pair;
}

 it("Should add liquidity", async function () {
    const amountA = ethers.parseUnits("1000", 18);
    const amountB = ethers.parseUnits("500", 18);

    const pair = await addInitialLiquidity(amountA, amountB);

    // Check allowances
    const allowanceA = await tokenA.allowance(owner.address, pair.getAddress());
    const allowanceB = await tokenB.allowance(owner.address, pair.getAddress());
    console.log(`Allowance for Token A: ${allowanceA.toString()}`);
    console.log(`Allowance for Token B: ${allowanceB.toString()}`);

    // Proceed with adding liquidity
    await pair.addLiquidity(amountA, amountB);

    const reserve0 = await pair.reserve0();
    const reserve1 = await pair.reserve1();

    expect(reserve0).to.equal(amountA);
    expect(reserve1).to.equal(amountB);
});

  it("Should remove liquidity", async function () {
    const amountA = ethers.parseUnits("1000", 18);
    const amountB = ethers.parseUnits("500", 18);

    const pair = await addInitialLiquidity(amountA, amountB);

    const liquidityBalance = await pair.liquidity(owner.address);
    console.log("Liquidity balance:", liquidityBalance.toString());
    
    console.log("Removing liquidity...");
    await pair.removeLiquidity(liquidityBalance);

    const finalReserve0 = await pair.reserve0();
    const finalReserve1 = await pair.reserve1();

    console.log("Final Reserve0:", finalReserve0.toString());
    console.log("Final Reserve1:", finalReserve1.toString());

    expect(finalReserve0).to.equal(0);
    expect(finalReserve1).to.equal(0);
  });

  it("Should swap tokens", async function () {
    const amountA = ethers.parseUnits("1000", 18);
    const amountB = ethers.parseUnits("500", 18);

    const pair = await addInitialLiquidity(amountA, amountB);

    const swapAmount = ethers.parseUnits("10", 18);
    const tokenAAddress = await tokenA.getAddress();
    const tokenBAddress = await tokenB.getAddress();

    console.log("Approving tokens for swap...");
    await tokenA.approve(pair.getAddress(), swapAmount);

    const initialBalanceB = await tokenB.balanceOf(owner.address);
    console.log("Initial balance B:", initialBalanceB.toString());

    console.log("Swapping tokens...");
    await pair.swap(swapAmount, tokenAAddress, tokenBAddress);

    const finalBalanceB = await tokenB.balanceOf(owner.address);
    console.log("Final balance B:", finalBalanceB.toString());

    expect(finalBalanceB).to.be.gt(initialBalanceB);
  });
});