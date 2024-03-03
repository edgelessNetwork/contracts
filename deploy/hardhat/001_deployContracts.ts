import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json";
import { ethers } from "ethers";
import * as EdgelessDepositArtifact from "../../artifacts/src/EdgelessDeposit.sol/EdgelessDeposit.json";
import * as StakingManagerArtifact from "../../artifacts/src/StakingManager.sol/StakingManager.json";
import * as EthStrategyArtifact from "../../artifacts/src/strategies/EthStrategy.sol/EthStrategy.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer, l1StandardBridge } = await getNamedAccounts();

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (!EdgelessDeposit) {
    await deploy("StakingManagerImpl", { from: deployer, log: true, contract: "StakingManager" });
    const StakingManager = new ethers.Contract((await get("StakingManagerImpl")).address, StakingManagerArtifact.abi);
    const stakingManagerData = StakingManager.interface.encodeFunctionData("initialize", [deployer]);
    await deploy("StakingManager", {
      from: deployer,
      log: true,
      contract: "ERC1967Proxy",
      args: [(await get("StakingManagerImpl")).address, stakingManagerData],
    });
    await save("StakingManager", {
      address: (await get("StakingManager")).address,
      abi: StakingManagerArtifact["abi"],
    });

    await deploy("EdgelessDepositImpl", { from: deployer, log: true, contract: "EdgelessDeposit" });
    const EdgelessDeposit = new ethers.Contract(
      (await get("EdgelessDepositImpl")).address,
      EdgelessDepositArtifact.abi,
    );
    const edgelessDepositData = EdgelessDeposit.interface.encodeFunctionData("initialize", [
      deployer,
      l1StandardBridge,
      (await get("StakingManager")).address,
    ]);
    await deploy("EdgelessDeposit", {
      from: deployer,
      log: true,
      contract: "ERC1967Proxy",
      args: [(await get("EdgelessDepositImpl")).address, edgelessDepositData],
    });
    await save("EdgelessDeposit", {
      address: (await get("EdgelessDeposit")).address,
      abi: EdgelessDepositArtifact["abi"],
    });

    await save("Edgeless Wrapped ETH", {
      address: await read("EdgelessDeposit", "wrappedEth"),
      abi: WrappedTokenArtifact["abi"],
    });

    await execute("StakingManager", { from: deployer, log: true }, "setStaker", (await get("EdgelessDeposit")).address);

    await deploy("EthStrategyImpl", { from: deployer, log: true, contract: "EthStrategy" });
    const EthStrategy = new ethers.Contract((await get("EthStrategyImpl")).address, EthStrategyArtifact.abi);
    const ethStrategyData = EthStrategy.interface.encodeFunctionData("initialize", [
      deployer,
      (await get("StakingManager")).address,
    ]);
    await deploy("EthStrategy", {
      from: deployer,
      log: true,
      contract: "ERC1967Proxy",
      args: [(await get("EthStrategyImpl")).address, ethStrategyData],
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
