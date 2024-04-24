import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (!EdgelessDeposit) {
    await deploy("RenzoStrategy", {
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
      1,
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
