// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { EdgelessDeposit } from "../../src/EdgelessDeposit.sol";
import { UpgradedEdgelessDeposit } from "../../src/upgrade-tests/UpgradedEdgelessDeposit.sol";
import { StakingManager } from "../../src/StakingManager.sol";
import { UpgradedStakingManager } from "../../src/upgrade-tests/UpgradedStakingManager.sol";
import { WrappedToken } from "../../src/WrappedToken.sol";
import { EthStrategy } from "../../src/strategies/EthStrategy.sol";
import { UpgradedEthStrategy } from "../../src/upgrade-tests/UpgradedEthStrategy.sol";

import { IERC20Inbox } from "../../src/interfaces/IERC20Inbox.sol";
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
    function test_upgradeEdgelessDeposit() public {
        // deploy
        vm.startPrank(owner);
        address edgelessDepositImpl = address(new UpgradedEdgelessDeposit());

        bytes memory edgelessDepositData = abi.encodeCall(UpgradedEdgelessDeposit.doNothing, ());
        edgelessDeposit.upgradeToAndCall(edgelessDepositImpl, edgelessDepositData);
    }

    function test_upgradeStakingManager() public {
        // deploy
        vm.startPrank(owner);
        address stakingManagerImpl = address(new UpgradedStakingManager());

        bytes memory stakingManagerData = abi.encodeCall(UpgradedStakingManager.doNothing, ());
        stakingManager.upgradeToAndCall(stakingManagerImpl, stakingManagerData);
    }

    function test_upgradeEthStakingStrategy() public {
        // deploy
        vm.startPrank(owner);
        address EthStakingStrategyImpl = address(new UpgradedEthStrategy());

        bytes memory EthStakingStrategyData = abi.encodeCall(UpgradedEthStrategy.doNothing, ());
        stakingManager.upgradeToAndCall(EthStakingStrategyImpl, EthStakingStrategyData);
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
