import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
import * as StakingManagerArtifact from "../../artifacts/src/StakingManager.sol/StakingManager.json";
import * as EdgelessDepositArtifact from "../../artifacts/src/EdgelessDeposit.sol/EdgelessDeposit.json";
import * as EthStakingArtifact from "../../artifacts/src/strategies/EthStrategy.sol/EthStrategy.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  await deploy("NewStakingManagerImpl", {
    contract: "StakingManager",
    from: deployer, // address that will perform the transaction.
    log: true,
  });
  const StakingManager = new ethers.Contract((await get("StakingManager")).address, StakingManagerArtifact.abi);
  const stakingManagerData = StakingManager.interface.encodeFunctionData("setAutoStake", [false]);
  await execute(
    "StakingManager",
    {
      from: deployer,
      log: true,
    },
    "upgradeToAndCall",
    (await get("NewStakingManagerImpl")).address,
    stakingManagerData,
  );

  await deploy("NewEdgelessDepositImpl", {
    contract: "EdgelessDeposit",
    from: deployer, // address that will perform the transaction.
    log: true,
  });
  const EdgelessDeposit = new ethers.Contract((await get("EdgelessDeposit")).address, EdgelessDepositArtifact.abi);
  const edgelessDepositData = EdgelessDeposit.interface.encodeFunctionData("setAutoBridge", [false]);
  await execute(
    "EdgelessDeposit",
    {
      from: deployer,
      log: true,
    },
    "upgradeToAndCall",
    (await get("NewEdgelessDepositImpl")).address,
    edgelessDepositData,
  );

  await deploy("NewEthStrategyImpl", {
    contract: "EthStrategy",
    from: deployer, // address that will perform the transaction.
    log: true,
  });
  const EthStrategy = new ethers.Contract((await get("EthStrategy")).address, EthStakingArtifact.abi);
  const ethStrategyData = EthStrategy.interface.encodeFunctionData("setAutoStake", [false]);
  await execute(
    "EthStrategy",
    {
      from: deployer,
      log: true,
    },
    "upgradeToAndCall",
    (await get("NewEthStrategyImpl")).address,
    ethStrategyData,
  );
};
export default func;
