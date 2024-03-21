// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { EdgelessDeposit } from "../../src/EdgelessDeposit.sol";
import { StakingManager } from "../../src/StakingManager.sol";
import { WrappedToken } from "../../src/WrappedToken.sol";
import { EthStrategy } from "../../src/strategies/EthStrategy.sol";

import { IWithdrawalQueueERC721 } from "../../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../../src/interfaces/IStakingStrategy.sol";
import { LIDO } from "../../src/Constants.sol";

import { Permit, SigUtils } from "../Utils/SigUtils.sol";
import { DeploymentUtils } from "../Utils/DeploymentUtils.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract AdminFunctionalityTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    StakingManager internal stakingManager;
    IStakingStrategy internal EthStakingStrategy;

    uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

    address public owner = makeAddr("Edgeless owner");
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        (stakingManager, edgelessDeposit, wrappedEth, EthStakingStrategy) = deployContracts(owner);
    }

    // ----------- Edgeless Deposit ------------

    // ----------- Staking Manager ------------
    function test_stake(uint256 amount, address randomUser) external {
        forkMainnetAndDeploy();

        amount = bound(amount, 1e18, 1e23);
        address EthAddress = stakingManager.ETH_ADDRESS();
        vm.deal(address(edgelessDeposit), amount);

        vm.prank(address(edgelessDeposit));
        stakingManager.stake{ value: amount }(EthAddress, amount);

        vm.deal(randomUser, amount);
        vm.expectRevert();
        vm.prank(randomUser);
        stakingManager.stake{ value: amount }(EthAddress, amount);
    }

    function test_withdraw(address randomUser) external {
        vm.prank(address(edgelessDeposit));
        stakingManager.withdraw(0);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.withdraw(0);
    }

    function test_setStaker(address randomStaker, address randomUser) external {
        vm.prank(owner);
        stakingManager.setStaker(randomStaker);
        assertEq(stakingManager.staker(), randomStaker);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.setStaker(randomStaker);
    }


    function test_addStrategy(IStakingStrategy strategy, address randomUser) external {
        address asset = stakingManager.ETH_ADDRESS();
        vm.prank(owner);
        stakingManager.addStrategy(asset, strategy);
        assertEq(address(stakingManager.strategies(asset, 1)), address(strategy));

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.addStrategy(asset, strategy);
    }

    function test_setActiveStrategy(IStakingStrategy strategy,address randomUser) external {
        address asset = stakingManager.ETH_ADDRESS();
        uint256 index = 0;
        vm.startPrank(owner);
        stakingManager.addStrategy(asset, strategy);
        stakingManager.setActiveStrategy(asset, index);
        assertEq(stakingManager.activeStrategyIndex(asset), index);
        vm.stopPrank();
    }

    function test_removeStrategy(IStakingStrategy stakingStrategy, address randomUser) external {
        forkMainnetAndDeploy();

        vm.startPrank(owner);
        address asset = stakingManager.ETH_ADDRESS();
        stakingManager.addStrategy(asset, stakingStrategy);
        assertEq(address(stakingManager.strategies(asset, 1)), address(stakingStrategy));

        stakingManager.removeStrategy(asset, 0, 0);
        assertEq(address(stakingManager.strategies(asset, 0)), address(stakingStrategy));

        stakingManager.addStrategy(asset, EthStakingStrategy);
        assertEq(address(stakingManager.strategies(asset, 1)), address(EthStakingStrategy));

        vm.stopPrank();
        vm.startPrank(randomUser);
        vm.expectRevert();
        stakingManager.removeStrategy(asset, 0, 0);
    }

    // ----------- Eth Strategy ------------
    function test_ownerDepositEth(uint256 amount, address randomAddress) external {
        amount = bound(amount, 1e18, 1e23);
        forkMainnetAndDeploy();
        vm.deal(owner, amount);
        vm.prank(owner);
        EthStakingStrategy.ownerDeposit{ value: amount }(amount);
        assertAlmostEq(LIDO.balanceOf(address(EthStakingStrategy)), amount, 2);

        vm.deal(randomAddress, amount);
        vm.expectRevert();
        vm.prank(randomAddress);
        EthStakingStrategy.ownerDeposit{ value: amount }(amount);
    }

    function test_ownerWithdrawEth(address randomAddress) external {
        vm.prank(owner);
        EthStakingStrategy.ownerWithdraw(0);

        vm.prank(randomAddress);
        vm.expectRevert();
        EthStakingStrategy.ownerWithdraw(0);
    }

    function test_requestLidoWithdrawal(address randomAddress) external {
        forkMainnetAndDeploy();
        vm.prank(owner);
        uint256[] memory amounts;
        EthStrategy(payable(address(EthStakingStrategy))).requestLidoWithdrawal(amounts);

        vm.prank(randomAddress);
        vm.expectRevert();
        EthStrategy(payable(address(EthStakingStrategy))).requestLidoWithdrawal(amounts);
    }

    function test_claimLidoWithdrawals(address randomAddress) external {
        forkMainnetAndDeploy();
        uint256[] memory requestIds = new uint256[](2);
        requestIds[0] = 1;
        requestIds[1] = 2;

        vm.prank(randomAddress);
        vm.expectRevert();
        EthStrategy(payable(address(EthStakingStrategy))).claimLidoWithdrawals(requestIds);
    }

    function test_setStakingManagerEth(address newStakingManager, address randomUser) external {
        vm.prank(owner);
        EthStakingStrategy.setStakingManager(newStakingManager);
        assertEq(EthStakingStrategy.stakingManager(), newStakingManager);

        vm.prank(randomUser);
        vm.expectRevert();
        EthStakingStrategy.setStakingManager(address(newStakingManager));
    }

    function test_setAutoStakeEth(bool autoStake, address randomUser) external {
        vm.prank(owner);
        EthStakingStrategy.setAutoStake(autoStake);
        assertEq(EthStakingStrategy.autoStake(), autoStake);

        vm.prank(randomUser);
        vm.expectRevert();
        EthStakingStrategy.setAutoStake(autoStake);
    }

    function forkMainnetAndDeploy() internal {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://Eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });
        (stakingManager, edgelessDeposit, wrappedEth, EthStakingStrategy) = deployContracts(owner);
    }
}
