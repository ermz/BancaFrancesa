require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config()

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1
    },
    localhost: {
      chainId: 31337
    },
    goerli: {
      chainId: 5,
      blockConfirmations: 6,
      url: GOERLI_RPC_URL,
      accounts: [PRIVATE_KEY]
    }
  },
  solidity: "0.8.17",
  namedAccounts: {
    deployer: {
      defaults: 0,
    },
    playerOne: {
      default: 1
    },
    playerTwo: {
      default: 2
    },
    playerThree: {
      default: 3
    }
  }
};
