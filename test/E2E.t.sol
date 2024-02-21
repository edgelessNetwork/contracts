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
import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../src/Constants.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessE2ETest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
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

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://Eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth, EthStakingStrategy) = deployContracts(owner);
    }

    function test_E2EWithoutStakingToLido(uint256 amount) external {
        amount = bound(amount, 1e18, 1e23);
        vm.prank(owner);
        EthStakingStrategy.setAutoStake(false);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        );

        edgelessDeposit.withdrawEth(depositor, amount);
        assertEq(address(depositor).balance, amount, "Depositor should have `amount` of Eth after withdrawing");
        assertEq(wrappedEth.balanceOf(depositor), 0, "Depositor should have 0 wrapped Eth after withdrawing");
        assertEq(address(edgelessDeposit).balance, 0, "EdgelessDeposit should have 0 Eth after withdrawing");
        assertEq(address(EthStakingStrategy).balance, 0, "EthStakingStrategy should have 0 Eth after withdrawing");
        assertEq(address(stakingManager).balance, 0, "StakingManager should have 0 Eth after withdrawing");
    }

    function test_E2EWithLido(uint256 amount) external {
        amount = bound(amount, 1e18, 1e20);
        vm.prank(owner);
        EthStakingStrategy.setAutoStake(true);
        vm.deal(depositor, amount);
        vm.prank(depositor);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        );
        assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped Eth");
        isWithinPercentage(LIDO.balanceOf(address(EthStakingStrategy)), amount, 1);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        vm.prank(owner);
        uint256[] memory requestIds = EthStrategy(payable(address(EthStakingStrategy))).requestLidoWithdrawal(amounts);
        address FINALIZE_ROLE = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        vm.prank(FINALIZE_ROLE);
        LIDO_WITHDRAWAL_ERC721.finalize(requestIds[requestIds.length - 1], 2e27);
        vm.prank(owner);
        EthStrategy(payable(address(EthStakingStrategy))).claimLidoWithdrawals(requestIds);
        console2.log(address(EthStakingStrategy).balance);
        vm.prank(depositor);
        edgelessDeposit.withdrawEth(depositor, amount);
        // assertEq(address(depositor).balance, amount, "Depositor should have `amount` of Eth after withdrawing");
        // assertEq(wrappedEth.balanceOf(depositor), 0, "Depositor should have 0 wrapped Eth after withdrawing");
    }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }
}
