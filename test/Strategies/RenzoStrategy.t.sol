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
    RenzoStrategy internal ethStakingStrategy;
    IStakingStrategy internal renzoStrategy;

    uint32 public constant FORK_BLOCK_NUMBER = 19_722_752;

    address public owner = 0xcB58d1142e53e37aDE44E1F125248FbfAc99352A;
    address public depositor = 0x22162DbBa43fE0477cdC5234E248264eC7C6EA7c;
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
        (stakingManager, edgelessDeposit, wrappedEth, ) = deployContracts(owner);
        address EthStakingStrategyImpl = address(new RenzoStrategy());
        bytes memory EthStakingStrategyData = abi.encodeCall(RenzoStrategy.initialize, (owner, address(stakingManager)));
        ethStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(EthStakingStrategyImpl, EthStakingStrategyData))));
        stakingManager.addStrategy(stakingManager.ETH_ADDRESS(), address(ethStakingStrategy));
        stakingManager.setActiveStrategy(stakingManager.ETH_ADDRESS(), 1);
        vm.stopPrank();
    }

    function test_EzEthDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e18, 1e40);
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

        // edgelessDeposit.withdrawEth(depositor, amount);
        assertGt(ezETH.balanceOf(ethStakingStrategy), amount, "Depositor should have `amount` of Eth after withdrawing");
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
