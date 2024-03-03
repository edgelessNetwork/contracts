import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
import * as EdgelessDepositArtifact from "../../artifacts/src/EdgelessDeposit.sol/EdgelessDeposit.json";
import * as StakingManagerArtifact from "../../artifacts/src/StakingManager.sol/StakingManager.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (EdgelessDeposit) {
    await deploy("StakingManagerImpl", {
      contract: "StakingManager",
      from: deployer, // address that will perform the transaction.
      log: true,
    });
    const provider = new ethers.providers.JsonRpcProvider(
      "https://eth-sepolia.g.alchemy.com/v2/" + process.env.API_KEY_ALCHEMY,
    );
    const signer = new ethers.Wallet("0x9fca6851974a3d725b3a53ef514149dd183857267d464bedede8dd8700a115c1", provider);
    const StakingManager = new ethers.Contract(
      (await get("StakingManager")).address,
      StakingManagerArtifact.abi,
      signer,
    );
    console.log(signer.address, deployer);
    const stakingManagerData = StakingManager.interface.encodeFunctionData("initialize", [deployer]);
    await StakingManager.connect(signer).upgradeToAndCall(
      (await get("StakingManagerImpl")).address,
      stakingManagerData,
    );
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
  await hre.run("etherscan-verify", {
    apiKey: process.env.ETHERSCAN_API_KEY,
  });
};
export default func;
