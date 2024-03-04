import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (EdgelessDeposit) {
    await execute("EdgelessDeposit", { from: deployer, log: true }, "setL1StandardBridge", l1StandardBridge);
    await execute("EdgelessDeposit", { from: deployer, log: true }, "setAutoBridge", true);
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
};
export default func;
