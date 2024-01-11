import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts, ethers } = hre
    const { deploy, getOrNull, log, read, save } = deployments
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
                        l1StandardBridge,
                        l2Eth,
                        l2USD
                    ],
                },
            },
        },
        skipIfAlreadyDeployed: true,
    });

};
export default func;
