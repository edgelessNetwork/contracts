import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre
    const { deploy } = deployments
    const { deployer, l2StandardBridge, l1Eth, l1USD } = await getNamedAccounts()

    await deploy('Edgeless Wrapped ETH', {
        contract: "OptimismMintableERC20",
        from: deployer,
        args: [l2StandardBridge, l1Eth, "Edgeless Wrapped ETH", "ewETH"],
        skipIfAlreadyDeployed: true,
    });

    await deploy('Edgeless Wrapped USD', {
        contract: "OptimismMintableERC20",
        from: deployer,
        args: [l2StandardBridge, l1USD, "Edgeless Wrapped USD", "ewUSD"],
        skipIfAlreadyDeployed: true,
    });

    await hre.run("etherscan-verify", {
        apiKey: process.env.ETHERSCAN_API_KEY,
    })
};
export default func;
