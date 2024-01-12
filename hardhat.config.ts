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
      sepolia: "0x2f43f89AbBaFB18BB96C54e331F6621254a1a3D2",
      edgelessSepoliaTestnet: "0x2f43f89AbBaFB18BB96C54e331F6621254a1a3D2"
    },
    l1USD: {
      goerli: "",
      sepolia: "0xF6980515A5d2AEab2d56F499Ac1a78F68f8b73e7",
      edgelessSepoliaTestnet: "0xF6980515A5d2AEab2d56F499Ac1a78F68f8b73e7"
    },
    l2Eth: {
      goerli: "",
      sepolia: "0x61b2b6Dd094272844c793E63B5aC3094Fe807C62",
      edgelessSepoliaTestnet: "0x61b2b6Dd094272844c793E63B5aC3094Fe807C62"
    },
    l2USD: {
      goerli: "",
      sepolia: "0x0c28a1EF0ccdD15cFd82C291bb0873a283F86da1",
      edgelessSepoliaTestnet: "0x0c28a1EF0ccdD15cFd82C291bb0873a283F86da1"
    }
  },
  paths: {
    sources: "./src",
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY!,
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
