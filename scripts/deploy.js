const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy MockERC20 for TokenA
    const TokenA = await ethers.getContractFactory("MockERC20");
    const tokenA = await TokenA.deploy("TokenA", "TKA", 18, ethers.utils.parseUnits("1000000", 18));
    await tokenA.deployed();
    console.log("TokenA deployed to:", tokenA.address);

    // Deploy MockERC20 for TokenB
    const TokenB = await ethers.getContractFactory("MockERC20");
    const tokenB = await TokenB.deploy("TokenB", "TKB", 18, ethers.utils.parseUnits("1000000", 18));
    await tokenB.deployed();
    console.log("TokenB deployed to:", tokenB.address);

    // Deploy SimpleDEXFactory
    const DEXFactory = await ethers.getContractFactory("contracts/SimpleDEXFactory.sol:SimpleDEXFactory");
    const dexFactory = await DEXFactory.deploy();
    await dexFactory.deployed();
    console.log("SimpleDEXFactory deployed to:", dexFactory.address);

    // Deploy SimpleDEXRouter
    const DEXRouter = await ethers.getContractFactory("SimpleDEXRouter");
    const dexRouter = await DEXRouter.deploy(dexFactory.address);
    await dexRouter.deployed();
    console.log("SimpleDEXRouter deployed to:", dexRouter.address);

    // Set allowances for the router to spend tokens on behalf of the deployer
    await tokenA.approve(dexRouter.address, ethers.utils.parseUnits("1000000", 18));
    await tokenB.approve(dexRouter.address, ethers.utils.parseUnits("1000000", 18));
    
    console.log("Approvals set for DEXRouter to spend TokenA and TokenB.");

    // Create a pair for TokenA and TokenB
    const tx = await dexFactory.createPair(tokenA.address, tokenB.address);
    const receipt = await tx.wait(); // Wait for the transaction to be mined

    // Get the Pair contract address from the event emitted
    const pairAddress = receipt.events.find(event => event.event === "PairCreated").args.pair;
    console.log("Pair created at:", pairAddress);
}

// Run the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
