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
    const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    const signer = new ethers.Wallet("0xf2f48ee19680706196e2e339e5da3491186e0c4c5030670656b0e0164837257d", provider);
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
    // await execute(
    //   "StakingManager",
    //   {
    //     from: deployer,
    //     log: true,
    //   },
    //   "upgradeToAndCall",
    //   (await get("StakingManagerImpl")).address,
    //   stakingManagerData,
    // );
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
};
export default func;
