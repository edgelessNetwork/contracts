// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { EdgelessDeposit } from "../../src/EdgelessDeposit.sol";
import { StakingManager } from "../../src/StakingManager.sol";
import { WrappedToken } from "../../src/WrappedToken.sol";
import { RenzoStrategy } from "../../src/strategies/RenzoStrategy.sol";

import { IWithdrawalQueueERC721 } from "../../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../../src/interfaces/IStakingStrategy.sol";

import { Permit, SigUtils } from "../Utils/SigUtils.sol";
import { DeploymentUtils } from "../Utils/DeploymentUtils.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract RenzoStrategyTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    StakingManager internal stakingManager;
    IStakingStrategy internal renzoStrategy;

    uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

    address public owner = makeAddr("Edgeless owner");
    address public depositor = makeAddr("Depositor");
    IERC20 ezETH = IERC20(0xbf5495Efe5DB9ce00f80364C8B423567e58d2110);

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://Eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth,) = deployContracts(owner);
        vm.startPrank(owner);
        address RenzoStrategyImpl = address(new RenzoStrategy());
        bytes memory RenzoStrategyData = abi.encodeCall(RenzoStrategy.initialize, (owner, address(stakingManager)));
        renzoStrategy = IStakingStrategy(payable(address(new ERC1967Proxy(RenzoStrategyImpl, RenzoStrategyData))));
        stakingManager.addStrategy(stakingManager.ETH_ADDRESS(), renzoStrategy);
        stakingManager.setActiveStrategy(stakingManager.ETH_ADDRESS(), 1);
        vm.stopPrank();
    }

    function test_DepositToRenzo(uint256 amount) external {
        amount = bound(amount, 1 ether, 100 ether);
        vm.prank(owner);
        renzoStrategy.setAutoStake(true);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        );
        assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped Eth");
        assertEq(address(renzoStrategy).balance, 0, "EthStrategy should have 0 Eth");
        assertTrue(
            isWithinPercentage(ezETH.balanceOf(address(renzoStrategy)), amount, 5), "EthStrategy should have 0 Eth"
        );
        vm.stopPrank();
    }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }
}
