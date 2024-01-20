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
    goerli: {
      deploy: ["./deploy/goerli/"],
      url: "https://eth-goerli.g.alchemy.com/v2/" + process.env.API_KEY_ALCHEMY,
      chainId: 5,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
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
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    owner: {
      hardhat: 0,
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    staker: {
      hardhat: 0,
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    l1StandardBridge: {
      hardhat: 0,
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0xfF591f2f96697F4D852C775B74830282d97D2c37",
      edgelessSepoliaTestnet: "0xfF591f2f96697F4D852C775B74830282d97D2c37"
    },
    l2StandardBridge: {
      hardhat: 0,
      goerli: "0x4200000000000000000000000000000000000010",
      sepolia: "0x4200000000000000000000000000000000000010",
      edgelessSepoliaTestnet: "0x4200000000000000000000000000000000000010"
    },
    l1Eth: {
      hardhat: 0,
      goerli: "",
      sepolia: "0x15353D8e704D218280E7A3F5563DF4E4149F040b",
      edgelessSepoliaTestnet: "0x15353D8e704D218280E7A3F5563DF4E4149F040b"
    },
    l1USD: {
      hardhat: 0,
      goerli: "",
      sepolia: "0xA17FC8B7F9A0F76aE16107DBaE091b49831B39ad",
      edgelessSepoliaTestnet: "0xA17FC8B7F9A0F76aE16107DBaE091b49831B39ad"
    },
    l2Eth: {
      hardhat: 0,
      goerli: "",
      sepolia: "0x0000000000000000000000000000000000000000",
      edgelessSepoliaTestnet: "0x0000000000000000000000000000000000000000"
    },
    l2USD: {
      hardhat: 0,
      goerli: "",
      sepolia: "0xeBD311957f4C974adf5E9D9a73E2D1bfC41e5fF2",
      edgelessSepoliaTestnet: "0xeBD311957f4C974adf5E9D9a73E2D1bfC41e5fF2"
    }
  },
  paths: {
    sources: "./src",
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY!,
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
