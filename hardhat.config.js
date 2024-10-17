require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-web3");
// require('./task/test.js')
require('./task/user.js')
// require("@nomicfoundation/hardhat-chai-matchers");

require('./task/stake.js')
require('./task/rod.js')
const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent("http://127.0.0.1:7890");
setGlobalDispatcher(proxyAgent);
// task("balance", "Prints an account's balance")
//     .addParam("account", "The account's address")
//     .setAction(async taskArgs => {
//       const account = web3.utils.toChecksumAddress(taskArgs.account);
//       const balance = await web3.eth.getBalance(account);
//
//       console.log(web3.utils.fromWei(balance, "ether"), "ETH");
//     });

module.exports = {
  solidity: "0.8.24",
  settings: {
    optimizer: {
      enabled: true,
      runs: 20000
    },
    outputSelection: {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    },
    libraries: {}
  },
  networks: {
    BNB: {
      url: process.env.OPTIMISM_CHAIN_URL,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 56
    },
    Sepolia: {
      url: process.env.OPTIMISM_CHAIN_URL,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155111
    }
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY_SEPOLIA,
    }
  }

};