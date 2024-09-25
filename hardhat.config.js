require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
require("@nomicfoundation/hardhat-verify");
require('dotenv').config();

module.exports = {
    solidity: {
        version: '0.8.20',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        mumbai: {
            url: "https://rpc-amoy.polygon.technology/",
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            chainId: 80002,
        },
    },
    polyscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: `${process.env.POLYGON_API}`
      },
};
