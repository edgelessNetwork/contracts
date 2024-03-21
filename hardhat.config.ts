import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-verify";

import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100000,
      },
    },
  },
  networks: {
    hardhat: {
      deploy: ["./deploy/hardhat/"],
    },
    sepolia: {
      deploy: ["./deploy/sepolia/"],
      url: "https://eth-sepolia.g.alchemy.com/v2/" + process.env.API_KEY_ALCHEMY,
      chainId: 11155111,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
    edgelessSepoliaTestnet: {
      deploy: ["./deploy/edgelessSepoliaTestnet/"],
      url: "https://edgeless-testnet.rpc.caldera.xyz/http",
      chainId: 202,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      verify: {
        etherscan: {
          apiUrl: "https://edgeless-testnet.explorer.caldera.xyz/",
        },
      },
    },
    ethereum: {
      deploy: ["./deploy/ethereum/"],
      url: "https://eth-mainnet.g.alchemy.com/v2/" + process.env.API_KEY_ALCHEMY,
      chainId: 1,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    }
  },
  namedAccounts: {
    deployer: {
      hardhat: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      ethereum: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      sepolia: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      edgelessSepoliaTestnet: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
    },
    owner: {
      hardhat: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      ethereum: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      sepolia: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
      edgelessSepoliaTestnet: "0xcB58d1142e53e37aDE44E1F125248FbfAc99352A",
    },
  },
  paths: {
    sources: "./src",
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      edgelessSepoliaTestnet: "You can enter any api key here, it doesn't matter ",
    },
    customChains: [
      {
        network: "edgelessSepoliaTestnet",
        chainId: 202,
        urls: {
          apiURL: "https://edgeless-testnet.explorer.caldera.xyz/api/",
          browserURL: "https://edgeless-testnet.explorer.caldera.xyz/",
        },
      },
    ],
  },
};

export default config;
