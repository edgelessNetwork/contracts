import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre
    const { deploy, read, save } = deployments
    const { deployer, owner, staker, l1StandardBridge, l2Eth, l2USD } = await getNamedAccounts()

    await deploy('EdgelessDeposit', {
        from: deployer,
        proxy: {
            proxyContract: 'UUPS',
            execute: {
                init: {
                    methodName: 'initialize',
                    args: [
                        owner,
                        staker,
                        l1StandardBridge
                    ],
                },
            },
        },
        skipIfAlreadyDeployed: true,
    });

    await save("Edgeless Wrapped ETH", {
        address: await read("EdgelessDeposit", "wrappedEth"),
        abi: WrappedTokenArtifact["abi"]
    });

    await save("Edgeless Wrapped USD", {
        address: await read("EdgelessDeposit", "wrappedUSD"),
        abi: WrappedTokenArtifact["abi"]
    });

    await hre.run("etherscan-verify", {
        apiKey: process.env.ETHERSCAN_API_KEY,
    })
};
export default func;
