import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (!EdgelessDeposit) {
    await deploy("StakingManager", {
      from: deployer, // address that will perform the transaction.
      log: true,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy", // default to "EIP173Proxy"
        execute: {
          methodName: "initialize",
          args: [deployer],
        },
      },
    });

    await deploy("EdgelessDeposit", {
      from: deployer, // address that will perform the transaction.
      log: true,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy", // default to "EIP173Proxy"
        execute: {
          methodName: "initialize",
          args: [deployer, l1StandardBridge, (await get("StakingManager")).address],
        },
      },
      skipIfAlreadyDeployed: true,
    });

    await save("Edgeless Wrapped ETH", {
      address: await read("EdgelessDeposit", "wrappedEth"),
      abi: WrappedTokenArtifact["abi"],
    });

    await execute("StakingManager", { from: deployer, log: true }, "setStaker", (await get("EdgelessDeposit")).address);

    await deploy("EthStrategy", {
      from: deployer,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",
        execute: {
          init: {
            methodName: "initialize",
            args: [deployer, (await get("StakingManager")).address],
          },
        },
      },
      skipIfAlreadyDeployed: true,
      log: true,
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
};
export default func;
