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
        runs: 1,
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
          apiUrl: "https://edgeless-testnet.explorer.caldera.xyz/"
        }
      }
    }
  },
  namedAccounts: {
    deployer: {
      hardhat: 0,
      sepolia: "0x45389224caF19e6d4c5424d6Aa441D5119b501Df",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    owner: {
      hardhat: 0,
      sepolia: "0x45389224caF19e6d4c5424d6Aa441D5119b501Df",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    l1StandardBridge: {
      hardhat: 0,
      sepolia: "0xfF591f2f96697F4D852C775B74830282d97D2c37",
      edgelessSepoliaTestnet: "0xfF591f2f96697F4D852C775B74830282d97D2c37"
    },
    l2Eth: {
      hardhat: 0,
      sepolia: "0x0000000000000000000000000000000000000000",
      edgelessSepoliaTestnet: "0x0000000000000000000000000000000000000000"
    }
  },
  paths: {
    sources: "./src",
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY!,
      edgelessSepoliaTestnet: "You can enter any api key here, it doesn't matter "
    },
    customChains: [
      {
        network: "edgelessSepoliaTestnet",
        chainId: 202,
        urls: {
          apiURL: "https://edgeless-testnet.explorer.caldera.xyz/api/",
          browserURL: "https://edgeless-testnet.explorer.caldera.xyz/"
        }
      }
    ]

  }
};

export default config;
