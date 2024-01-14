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
import { DaiStrategy } from "../src/strategies/DaiStrategy.sol";

import { IDai } from "../src/interfaces/IDai.sol";
import { IL1StandardBridge } from "../src/interfaces/IL1StandardBridge.sol";
import { ILido } from "../src/interfaces/ILido.sol";
import { IUsdt } from "../src/interfaces/IUsdt.sol";
import { IUsdc } from "../src/interfaces/IUsdc.sol";
import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../src/interfaces/IStakingStrategy.sol";

import { Permit, SigUtils } from "./SigUtils.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";
import { LIDO, Dai, Usdc, Usdt } from "../src/Constants.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    WrappedToken internal wrappedUSD;
    IL1StandardBridge internal l1standardBridge;
    StakingManager internal stakingManager;
    IStakingStrategy internal EthStakingStrategy;
    IStakingStrategy internal DaiStakingStrategy;

    address public constant STEth_WHALE = 0x5F6AE08B8AeB7078cf2F96AFb089D7c9f51DA47d; // Blast Deposits

    uint32 public constant FORK_BLOCK_NUMBER = 10_371_521;

    address public constant LIDO_FINALIZE_ROLE_ADDRESS = address(LIDO);

    address public owner = makeAddr("Edgeless owner");
    address public depositor = makeAddr("Depositor");
    uint256 public depositorKey = uint256(keccak256(abi.encodePacked("Depositor")));
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        console2.log(string(abi.encodePacked("https://eth-goerli.g.alchemy.com/v2/", alchemyApiKey)));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://eth-goerli.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth, wrappedUSD, EthStakingStrategy, DaiStakingStrategy) =
            deployContracts(owner, owner);
    }

    function test_goerliDaiDepositAndWithdraw(uint256 amount) external {
        if (!isRightNetwork()) return;
        amount = bound(amount, 1e18, 1e25);
        deal(address(Dai), depositor, amount);
        depositAndWithdrawDai(depositor, address(Dai), amount);
    }

    function test_goerliUsdcDepositAndWithdraw(uint256 amount) external {
        if (!isRightNetwork()) return;
        amount = bound(amount, 1e6, 1e10);
        deal(address(Usdc), depositor, amount);
        depositAndWithdrawUsdc(depositor, amount);
    }

    function test_goerliEthDepositAndWithdraw(uint256 amount) external {
        if (!isRightNetwork()) return;
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

    function test_goerliDaiPermitDepositAndWithdraw(uint256 amount) external {
        if (!isRightNetwork()) return;
        amount = bound(amount, 1e18, 1e25);
        deal(address(Dai), depositor, amount);
        vm.startPrank(depositor);
        // Deposit Dai
        Permit memory permit = Permit({
            owner: depositor,
            spender: address(edgelessDeposit),
            value: amount,
            nonce: Dai.nonces(depositor),
            deadline: type(uint256).max,
            allowed: true
        });
        bytes32 digest = permit.getTypedDaiDataHashWithPermitTypeHash(Dai.DOMAIN_SEPARATOR(), Dai.PERMIT_TYPEHASH());
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorKey, digest);
        edgelessDeposit.depositDaiWithPermit(permit.owner, permit.value, permit.nonce, permit.deadline, v, r, s);

        // Withdraw Dai by burning wrapped stablecoin - sDai rounds down, so you lose 2 wei worth of Dai(not 2 Dai)
        edgelessDeposit.withdrawUSD(depositor, amount - 2);
        assertAlmostEq(Dai.balanceOf(depositor), amount, 2, "Depositor should have `amount` of Dai afterwithdrawing");
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(Dai.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Dai afterwithdrawing");
    }

    // TODO: Add more checks for all variables: sDai balance, Dai balance, etc.
    function depositAndWithdrawDai(address depositor, address asset, uint256 amount) internal {
        vm.startPrank(depositor);
        // Deposit Dai
        Dai.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositDai(depositor, amount);

        // Withdraw Dai by burning wrapped stablecoin - sDai rounds down, so you lose 2 wei worth of Dai(not 2 Dai)
        edgelessDeposit.withdrawUSD(depositor, amount - 2);
        assertAlmostEq(Dai.balanceOf(depositor), amount, 2, "Depositor should have `amount` of Dai afterwithdrawing");
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(Dai.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Dai afterwithdrawing");
    }

    function depositAndWithdrawUsdc(address depositor, uint256 amount) internal {
        vm.startPrank(depositor);
        // Deposit Dai
        Usdc.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositUsdc(depositor, amount);

        // Withdraw Dai by burning wrapped stablecoin - sDai rounds down, so you lose 2 wei worth of Dai(not 2 Dai)
        edgelessDeposit.withdrawUSD(depositor, wrappedUSD.balanceOf(depositor) - 2);
        assertAlmostEq(
            Dai.balanceOf(depositor),
            amount * 10 ** 12,
            2,
            "Depositor should have `amount` of Dai after withdrawing - account for Usdc <> Dai decimals"
        );
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(Usdc.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Usdc after withdrawing");
        assertAlmostEq(Dai.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Dai after withdrawing");
    }

    function depositAndWithdrawUsdt(address depositor, uint256 amount) internal {
        vm.startPrank(depositor);
        // Deposit Dai
        Usdt.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositUsdt(depositor, amount, amount);

        // Withdraw Dai by burning wrapped stablecoin - sDai rounds down, so you lose 2 wei worth of Dai(not 2 Dai)
        edgelessDeposit.withdrawUSD(depositor, wrappedUSD.balanceOf(depositor) - 2);
        assertTrue(
            isWithinPercentage(amount * 10 ** 12, Dai.balanceOf(depositor), 1),
            "Depositor should have `amount` of Dai after withdrawing - account for Usdt <> Dai decimals"
        );
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(Usdc.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Usdc after withdrawing");
        assertAlmostEq(Dai.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 Dai after withdrawing");
    }

    function mintStEth(address to, uint256 amount) internal {
        vm.startPrank(STEth_WHALE);
        LIDO.transfer(to, amount);
        vm.stopPrank();
    }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }

    function isRightNetwork() internal view returns (bool) {
        return address(Dai) == address(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
    }
}
