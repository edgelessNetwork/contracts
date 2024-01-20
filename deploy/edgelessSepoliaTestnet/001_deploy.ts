import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre
    const { deploy, get } = deployments
    const { deployer, l2StandardBridge, l1Eth, l1USD } = await getNamedAccounts()

    await deploy('Edgeless Wrapped USD', {
        contract: "OptimismMintableERC20",
        from: deployer,
        args: [l2StandardBridge, l1USD, "Edgeless Wrapped USD", "ewUSD"],
        log: true,
        skipIfAlreadyDeployed: true,
    });

    await hre.run("verify:verify", {
        address: (await get("Edgeless Wrapped ETH")).address,
        constructorArguments: [l2StandardBridge, l1Eth, "Edgeless Wrapped ETH", "ewETH"]
    });

    await hre.run("verify:verify", {
        address: (await get("Edgeless Wrapped USD")).address,
        constructorArguments: [l2StandardBridge, l1USD, "Edgeless Wrapped USD", "ewUSD"],
    });
};
export default func;
