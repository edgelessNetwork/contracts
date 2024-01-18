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
      url: "https://edgeless-op.rpc.caldera.xyz/http",
      chainId: 2067124,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      verify: {
        etherscan: {
          apiUrl: "https://edgeless-op.explorer.caldera.xyz/"
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
      sepolia: "0x2aff8fd3f9d46C3Cf4993CcD7259021b0F898A04",
      edgelessSepoliaTestnet: "0x2aff8fd3f9d46C3Cf4993CcD7259021b0F898A04"
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
      sepolia: "0x62b4B558971b6C6054C195602Fc32ae5939bF471",
      edgelessSepoliaTestnet: "0x62b4B558971b6C6054C195602Fc32ae5939bF471"
    },
    l1USD: {
      hardhat: 0,
      goerli: "",
      sepolia: "0x5EFaC893A67E167a64AfA71209ab5A86765A3feA",
      edgelessSepoliaTestnet: "0x5EFaC893A67E167a64AfA71209ab5A86765A3feA"
    },
    l2Eth: {
      hardhat: 0,
      goerli: "",
      sepolia: "0x2305C316529e4c97510E72B18673168e1C22a927",
      edgelessSepoliaTestnet: "0x2305C316529e4c97510E72B18673168e1C22a927"
    },
    l2USD: {
      hardhat: 0,
      goerli: "",
      sepolia: "0x1a38fd27562b98313C2fAeCFb5bD0dFC3F7Ebcb2",
      edgelessSepoliaTestnet: "0x1a38fd27562b98313C2fAeCFb5bD0dFC3F7Ebcb2"
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
        chainId: 2067124,
        urls: {
          apiURL: "https://edgeless-op.explorer.caldera.xyz/api/",
          browserURL: "https://edgeless-op.explorer.caldera.xyz/"
        }
      }
    ]

  }
};

export default config;
