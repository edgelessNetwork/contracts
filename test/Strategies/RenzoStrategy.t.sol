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
import { UpgradedEdgelessDeposit } from "../../src/upgrade-tests/UpgradedEdgelessDeposit.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract RenzoStrategyTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit = EdgelessDeposit(payable(0x7E0bc314535f430122caFEF18eAbd508d62934bf));
    WrappedToken internal wrappedEth = WrappedToken(0xcD0aa40948c662dEDd9F157085fd6369A255F2f7);
    StakingManager internal stakingManager = StakingManager(payable(0x1e6d08769be5Dc83d38C64C5776305Ad6F01c227));
    RenzoStrategy internal ethStakingStrategy = RenzoStrategy(payable(0xbD95aa0f68B95e6C01d02F1a36D8fde29C6C8e7b));
    IStakingStrategy internal renzoStrategy;

    uint32 public constant FORK_BLOCK_NUMBER = 19_722_752;

    address public owner = 0xcB58d1142e53e37aDE44E1F125248FbfAc99352A;
    address public depositor = makeAddr("Depositor");
    IERC20 ezETH = IERC20(0xbf5495Efe5DB9ce00f80364C8B423567e58d2110);

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://Eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        // Upgrade contracts
        vm.startPrank(owner);
        address edgelessDepositImpl = address(new EdgelessDeposit());
        bytes memory edgelessDepositData = abi.encodeCall(EdgelessDeposit.upgrade, ());
        edgelessDeposit.upgradeToAndCall(edgelessDepositImpl, edgelessDepositData);

        address stakingManagerImpl = address(new StakingManager());
        bytes memory stakingManagerData =
            abi.encodeCall(StakingManager.setEzETH, (0xbf5495Efe5DB9ce00f80364C8B423567e58d2110));
        stakingManager.upgradeToAndCall(stakingManagerImpl, stakingManagerData);

        address renzoStrategyImpl = address(new RenzoStrategy());
        bytes memory renzoStrategyData = abi.encodeCall(RenzoStrategy.setConstants, ());
        ethStakingStrategy.upgradeToAndCall(renzoStrategyImpl, renzoStrategyData);

        vm.stopPrank();
    }

    function test_DepositToRenzo(uint256 amount) external {
        // amount = bound(amount, 1 ether, 100 ether);
        // vm.prank(owner);
        // renzoStrategy.setAutoStake(true);
        // vm.startPrank(depositor);
        // vm.deal(depositor, amount);

        // // Deposit Eth
        // edgelessDeposit.depositEth{ value: amount }(depositor);
        // assertEq(
        //     address(depositor).balance,
        //     0,
        //     "Deposit should have 0 Eth since all Eth was sent to the edgeless edgelessDeposit contract"
        // );
        // assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped Eth");
        // assertEq(address(renzoStrategy).balance, 0, "EthStrategy should have 0 Eth");
        // assertTrue(
        //     isWithinPercentage(ezETH.balanceOf(address(renzoStrategy)), amount, 5), "EthStrategy should have 0 Eth"
        // );
        // vm.stopPrank();
    }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }
}
