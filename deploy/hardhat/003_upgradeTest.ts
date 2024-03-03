import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
import * as StakingManagerArtifact from "../../artifacts/src/StakingManager.sol/StakingManager.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  await deploy("s", {
    contract: "StakingManager",
    from: deployer, // address that will perform the transaction.
    log: true,
  });
  const StakingManager = new ethers.Contract((await get("StakingManager")).address, StakingManagerArtifact.abi);
  const stakingManagerData = StakingManager.interface.encodeFunctionData("initialize", [deployer]);
  console.log(stakingManagerData)
  await execute(
    "StakingManager",
    {
      from: deployer,
      log: true,
    },
    "upgradeToAndCall",
    (await get("s")).address,
    stakingManagerData,
  );
};
export default func;
