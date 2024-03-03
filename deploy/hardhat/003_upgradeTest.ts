import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
import * as EdgelessDepositArtifact from "../../artifacts/src/EdgelessDeposit.sol/EdgelessDeposit.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (EdgelessDeposit) {
    await deploy("EdgelessDepositImpl", {
      contract: "EdgelessDeposit",
      from: deployer, // address that will perform the transaction.
      log: true,
    });
    const EdgelessDeposit = new ethers.Contract((await get("EdgelessDeposit")).address, EdgelessDepositArtifact.abi);
    const edgelessDepositData = EdgelessDeposit.interface.encodeFunctionData("initialize", [
      deployer,
      l1StandardBridge,
      (await get("StakingManager")).address,
    ]);
    await execute(
      "EdgelessDeposit",
      {
        from: deployer,
        log: true,
      },
      "upgradeToAndCall",
      (await get("EdgelessDepositImpl")).address,
      edgelessDepositData,
    );
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
};
export default func;
