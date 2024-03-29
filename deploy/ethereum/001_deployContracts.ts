import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (!EdgelessDeposit) {
    await deploy("StakingManager", {
      from: deployer,
      log: true,
      proxy: {
        execute: {
          init: {
            methodName: "initialize",
            args: [deployer],
          },
        },
        proxyContract: "OpenZeppelinTransparentProxy",
      },
    });

    await deploy("EdgelessDeposit", {
      from: deployer,
      log: true,
      proxy: {
        execute: {
          init: {
            methodName: "initialize",
            args: [deployer, (await get("StakingManager")).address],
          },
        },
        proxyContract: "OpenZeppelinTransparentProxy",
      },
    });

    await save("Edgeless Wrapped ETH", {
      address: await read("EdgelessDeposit", "wrappedEth"),
      abi: WrappedTokenArtifact["abi"],
    });

    await execute("StakingManager", { from: deployer, log: true }, "setStaker", (await get("EdgelessDeposit")).address);

    await deploy("EthStrategy", {
      from: deployer,
      log: true,
      proxy: {
        execute: {
          init: {
            methodName: "initialize",
            args: [deployer, (await get("StakingManager")).address],
          },
        },
        proxyContract: "OpenZeppelinTransparentProxy",
      },
    });

    await execute(
      "StakingManager",
      { from: deployer, log: true },
      "addStrategy",
      await read("StakingManager", "ETH_ADDRESS"),
      (await get("EthStrategy")).address,
    );

    await execute(
      "StakingManager",
      { from: deployer, log: true },
      "setActiveStrategy",
      await read("StakingManager", "ETH_ADDRESS"),
      0,
    );
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
  await hre.run("etherscan-verify", {
    apiKey: process.env.ETHERSCAN_API_KEY,
  });

  await hre.run("verify:verify", {
    address: (await get("Edgeless Wrapped ETH")).address,
    constructorArguments: [
      (await get("EdgelessDeposit")).address,
      await read("Edgeless Wrapped ETH", "name"),
      await read("Edgeless Wrapped ETH", "symbol"),
    ],
  });
};
export default func;
