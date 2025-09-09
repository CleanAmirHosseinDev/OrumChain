require("@nomicfoundation/hardhat-toolbox");
require("@matterlabs/hardhat-zksync-solc");
require("@matterlabs/hardhat-zksync-deploy");
require("@matterlabs/hardhat-zksync-verify");
require("dotenv").config();

const ZKSYNC_TESTNET_RPC_URL = process.env.ZKSYNC_TESTNET_RPC_URL;
const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  zksolc: {
    version: "1.3.17",
    compilerSource: "binary",
    settings: {
      isSystem: false,
      optimizer: {
        enabled: true,
        mode: 'z',
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // zksync: false is the default
    },
    zkSyncTestnet: {
      url: ZKSYNC_TESTNET_RPC_URL || "https://zksync2-testnet.zksync.dev",
      ethNetwork: "goerli",
      zksync: true,
      verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification',
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : [],
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
    deploy: "./scripts/deploy",
  },
};
