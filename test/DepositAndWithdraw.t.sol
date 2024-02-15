// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { EdgelessDeposit } from "../src/EdgelessDeposit.sol";
import { StakingManager } from "../src/StakingManager.sol";
import { WrappedToken } from "../src/WrappedToken.sol";
import { EthStrategy } from "../src/strategies/EthStrategy.sol";

import { IL1ERC20Bridge } from "../src/interfaces/IL1ERC20Bridge.sol";
import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../src/interfaces/IStakingStrategy.sol";

import { Permit, SigUtils } from "./Utils/SigUtils.sol";
import { DeploymentUtils } from "./Utils/DeploymentUtils.sol";
import { LIDO } from "../src/Constants.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    IL1ERC20Bridge internal l1standardBridge;
    StakingManager internal stakingManager;
    IStakingStrategy internal EthStakingStrategy;

    uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

    address public constant LIDO_FINALIZE_ROLE_ADDRESS = address(LIDO);
    address public constant OPTIMISM_GATEWAY_BRIDGE = address(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);

    address public owner = makeAddr("Edgeless owner");
    address public depositor = makeAddr("Depositor");
    uint256 public depositorKey = uint256(keccak256(abi.encodePacked("Depositor")));
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://Eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth, EthStakingStrategy) = deployContracts(owner, owner);
    }

    function test_EthDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e18, 1e40);
        vm.prank(owner);
        EthStakingStrategy.setAutoStake(false);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        );
        assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped Eth");

        edgelessDeposit.withdrawEth(depositor, amount);
        assertEq(address(depositor).balance, amount, "Depositor should have `amount` of Eth after withdrawing");
        assertEq(wrappedEth.balanceOf(depositor), 0, "Depositor should have 0 wrapped Eth after withdrawing");
    }

    function test_EthDepositAndWithdrawToOptimismBridge(uint256 amount) external {
        vm.startPrank(owner);
        amount = bound(amount, 1e18, 1e40);
        address stakingManagerImpl = address(new StakingManager());
        bytes memory stakingManagerData = abi.encodeCall(StakingManager.initialize, (owner, staker));
        stakingManager = StakingManager(payable(address(new ERC1967Proxy(stakingManagerImpl, stakingManagerData))));

        address edgelessDepositImpl = address(new EdgelessDeposit());
        bytes memory edgelessDepositData = abi.encodeCall(
            EdgelessDeposit.initialize,
            (owner, staker, IL1ERC20Bridge(OPTIMISM_GATEWAY_BRIDGE), stakingManager)
        );
        edgelessDeposit = EdgelessDeposit(payable(address(new ERC1967Proxy(edgelessDepositImpl, edgelessDepositData))));

        stakingManager.setStaker(address(edgelessDeposit));
        stakingManager.setDepositor(address(edgelessDeposit));

        address EthStakingStrategyImpl = address(new EthStrategy());
        bytes memory EthStakingStrategyData = abi.encodeCall(EthStrategy.initialize, (owner, address(stakingManager)));
        EthStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(EthStakingStrategyImpl, EthStakingStrategyData))));
        stakingManager.addStrategy(stakingManager.ETH_ADDRESS(), EthStakingStrategy);
        stakingManager.setActiveStrategy(stakingManager.ETH_ADDRESS(), 0);

        wrappedEth = edgelessDeposit.wrappedEth();
        edgelessDeposit.setAutoBridge(true);
        EthStakingStrategy.setAutoStake(false);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        );
        assertEq(
            wrappedEth.balanceOf(OPTIMISM_GATEWAY_BRIDGE),
            amount,
            "Bridge should have `amount` of wrapped Eth"
        );
    }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }
}
