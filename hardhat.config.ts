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
    }
  },
  namedAccounts: {
    deployer: {
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    owner: {
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    staker: {
      goerli: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      sepolia: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44",
      edgelessSepoliaTestnet: "0x08C6fBA53BF2Ae19DBdC330E258B510c1C148e44"
    },
    l1StandardBridge: {
      goerli: "",
      sepolia: "0x2aff8fd3f9d46C3Cf4993CcD7259021b0F898A04",
      edgelessSepoliaTestnet: "0x2aff8fd3f9d46C3Cf4993CcD7259021b0F898A04"
    },
    l2StandardBridge: {
      goerli: "0x4200000000000000000000000000000000000010",
      sepolia: "0x4200000000000000000000000000000000000010",
      edgelessSepoliaTestnet: "0x4200000000000000000000000000000000000010"
    },
    l1Eth: {
      goerli: "",
      sepolia: "0x73Cb27e3c1a15860b4a6BD1BB4a133c9B3dE9598",
      edgelessSepoliaTestnet: "0x73Cb27e3c1a15860b4a6BD1BB4a133c9B3dE9598"
    },
    l1USD: {
      goerli: "",
      sepolia: "0x68F67eA08ce0E82E572Cee45123Aa7bB91576B7B",
      edgelessSepoliaTestnet: "0x68F67eA08ce0E82E572Cee45123Aa7bB91576B7B"
    },
    l2Eth: {

    },
    l2USD: {

    }
  },
  paths: {
    sources: "./src",
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY!
    }
  }
};

export default config;
