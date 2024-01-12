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
      sepolia: "0x07F9ffb22e08E2BEba460C0987942A84F805D8fB",
      edgelessSepoliaTestnet: "0x07F9ffb22e08E2BEba460C0987942A84F805D8fB"
    },
    l1USD: {
      goerli: "",
      sepolia: "0xB861581E9842f4D9e4b324BA1F052f18b758b48E",
      edgelessSepoliaTestnet: "0xB861581E9842f4D9e4b324BA1F052f18b758b48E"
    },
    l2Eth: {
      goerli: "",
      sepolia: "0x7B4967b3d08a5fc7693d981dfc5bDC574399FAef",
      edgelessSepoliaTestnet: "0x7B4967b3d08a5fc7693d981dfc5bDC574399FAef"
    },
    l2USD: {
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
      edgelessSepoliaTestnet: "a"
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
