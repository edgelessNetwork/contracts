// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { EdgelessDeposit } from "../../src/EdgelessDeposit.sol";
import { StakingManager } from "../../src/StakingManager.sol";
import { WrappedToken } from "../../src/WrappedToken.sol";
import { EthStrategy } from "../../src/strategies/EthStrategy.sol";
import { DaiStrategy } from "../../src/strategies/DaiStrategy.sol";

import { IDai } from "../../src/interfaces/IDai.sol";
import { IL1StandardBridge } from "../../src/interfaces/IL1StandardBridge.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { IUsdt } from "../../src/interfaces/IUsdt.sol";
import { IUsdc } from "../../src/interfaces/IUsdc.sol";
import { IWithdrawalQueueERC721 } from "../../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../../src/interfaces/IStakingStrategy.sol";
import { Dai } from "../../src/Constants.sol";

import { Permit, SigUtils } from "./SigUtils.sol";

abstract contract DeploymentUtils is PRBTest {
    /**
     * @dev Deploy the staking manager, Edgeless Deposit, Eth Lido Strategy, and Dai Staking Strategy
     * This also sets the two staking strategies as active in the staking manager
     * autoStake is set to true, and autoBridge is set to false
     */
    function deployContracts(
        address owner,
        address staker
    )
        public
        returns (
            StakingManager stakingManager,
            EdgelessDeposit edgelessDeposit,
            WrappedToken wrappedEth,
            WrappedToken wrappedUSD,
            IStakingStrategy EthStakingStrategy,
            IStakingStrategy DaiStakingStrategy
        )
    {
        vm.startPrank(owner);
        address stakingManagerImpl = address(new StakingManager());
        bytes memory stakingManagerData = abi.encodeCall(StakingManager.initialize, (owner, staker));
        stakingManager = StakingManager(payable(address(new ERC1967Proxy(stakingManagerImpl, stakingManagerData))));

        address edgelessDepositImpl = address(new EdgelessDeposit());
        bytes memory edgelessDepositData =
            abi.encodeCall(EdgelessDeposit.initialize, (owner, staker, IL1StandardBridge(address(1)), stakingManager));
        edgelessDeposit = EdgelessDeposit(payable(address(new ERC1967Proxy(edgelessDepositImpl, edgelessDepositData))));

        stakingManager.setStaker(address(edgelessDeposit));
        stakingManager.setDepositor(address(edgelessDeposit));

        address EthStakingStrategyImpl = address(new EthStrategy());
        bytes memory EthStakingStrategyData = abi.encodeCall(EthStrategy.initialize, (owner, address(stakingManager)));
        EthStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(EthStakingStrategyImpl, EthStakingStrategyData))));
        stakingManager.addStrategy(stakingManager.ETH_ADDRESS(), EthStakingStrategy);
        stakingManager.setActiveStrategy(stakingManager.ETH_ADDRESS(), 0);

        address DaiStakingStrategyImpl = address(new DaiStrategy());
        bytes memory DaiStakingStrategyData = abi.encodeCall(DaiStrategy.initialize, (owner, address(stakingManager)));
        DaiStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(DaiStakingStrategyImpl, DaiStakingStrategyData))));
        stakingManager.addStrategy(address(Dai), DaiStakingStrategy);
        stakingManager.setActiveStrategy(address(Dai), 0);

        wrappedEth = edgelessDeposit.wrappedEth();
        wrappedUSD = edgelessDeposit.wrappedUSD();
        edgelessDeposit.setAutoBridge(false);
        vm.stopPrank();

        vm.label(address(wrappedEth), "wrappedEth");
        vm.label(address(wrappedUSD), "wrappedUSD");
        vm.label(address(edgelessDeposit), "edgelessDeposit");
    }
}
