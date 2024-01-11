// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { EdgelessDeposit } from "../src/EdgelessDeposit.sol";
import { StakingManager } from "../src/StakingManager.sol";
import { WrappedToken } from "../src/WrappedToken.sol";

import { IDAI } from "../src/interfaces/IDAI.sol";
import { IL1StandardBridge } from "../src/interfaces/IL1StandardBridge.sol";
import { ILido } from "../src/interfaces/ILido.sol";
import { IUSDT } from "../src/interfaces/IUSDT.sol";
import { IUSDC } from "../src/interfaces/IUSDC.sol";
import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils {
    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    WrappedToken internal wrappedUSD;
    IL1StandardBridge internal l1standardBridge;

    IUSDC public constant USDC = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUSDT public constant USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IDAI public constant DAI = IDAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ILido public constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IWithdrawalQueueERC721 public constant LIDO_WITHDRAWAL_ERC721 =
        IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

    address public constant STETH_WHALE = 0x5F6AE08B8AeB7078cf2F96AFb089D7c9f51DA47d; // Blast Deposits

    uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

    address public constant LIDO_FINALIZE_ROLE_ADDRESS = address(LIDO);

    address public owner = makeAddr("Edgeless owner");
    address public depositor = makeAddr("Depositor");
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        vm.startPrank(owner);

        address implementation = address(new EdgelessDeposit());
        bytes memory data = abi.encodeCall(
            EdgelessDeposit.initialize, (owner, staker, IL1StandardBridge(address(1)), address(2), address(3))
        );
        console2.logBytes(data);
        address payable proxy = payable(address(new ERC1967Proxy(implementation, data)));
        edgelessDeposit = EdgelessDeposit(proxy);

        wrappedEth = edgelessDeposit.wrappedEth();
        wrappedUSD = edgelessDeposit.wrappedUSD();

        vm.label(address(wrappedEth), "wrappedEth");
        vm.label(address(wrappedUSD), "wrappedUSD");
        vm.label(address(edgelessDeposit), "edgelessDeposit");
        vm.label(owner, "owner");
        vm.label(depositor, "depositor");
        vm.stopPrank();
    }

    function mintStETH(address to, uint256 amount) internal {
        vm.startPrank(STETH_WHALE);
        LIDO.transfer(to, amount);
        vm.stopPrank();
    }

    /**
     * @dev Test that depositing and withdrawing will result in receiving
     * the same amount of eth.
     * @param amount The amount of eth to edgelessDeposit and withdraw.
     * Since this is a fuzz test, this amount is randomly generated.
     */
    function test_basicDepositAndWithdraw(uint64 amount) external {
        vm.assume(amount != 0);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(wrappedEth.balanceOf(depositor), amount);
        assertEq(address(depositor).balance, 0 ether);

        edgelessDeposit.withdrawEth(depositor, amount);
        assertEq(wrappedEth.balanceOf(depositor), 0 ether);
        assertEq(address(depositor).balance, amount);
    }

    /**
     * @dev Test that depositing and withdrawing will result in receiving back all eth
     */
    function test_EthInit(uint64 amount) external {
        vm.assume(amount != 0);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        uint256 depositorInitialEthBalance = address(depositor).balance;
        uint256 edgelessInitialLidoBalance = LIDO.balanceOf(address(edgelessDeposit));
        uint256 depositorInitialWrappedEthBalance = wrappedEth.balanceOf(depositor);
        assertEq(depositorInitialEthBalance, amount, "Depositor should have `amount` of eth");
        assertEq(edgelessInitialLidoBalance, 0, "Edgeless should start with 0 steth");
        assertEq(depositorInitialWrappedEthBalance, 0, "Depositor should start with 0 wrapped eth");
    }

    function test_EthDepositAndWithdraw(uint64 amount) external {
        vm.assume(amount > 1 gwei);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(
            address(depositor).balance,
            0,
            "Deposit should have 0 eth since all eth was sent to the edgeless edgelessDeposit contract"
        );

        assertAlmostEq(LIDO.balanceOf(address(edgelessDeposit)), amount, 10, "Edgeless should have `amount` of steth");
        assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped eth");

        edgelessDeposit.withdrawEth(depositor, amount);
        assertEq(address(depositor).balance, amount, "Depositor should have `amount` of eth after withdrawing");
        assertEq(wrappedEth.balanceOf(depositor), 0, "Depositor should have 0 wrapped eth after withdrawing");
    }

    function test_StEthDepositAndWithdraw(uint64 amount) external {
        vm.assume(amount > 1 gwei);
        mintStETH(depositor, amount);
        vm.startPrank(depositor);

        // Deposit Eth
        LIDO.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositStEth(depositor, amount);

        assertAlmostEq(LIDO.balanceOf(address(edgelessDeposit)), amount, 2, "Edgeless should have `amount` of steth");
        assertEq(wrappedEth.balanceOf(depositor), amount, "Depositor should have `amount` of wrapped eth");

        edgelessDeposit.withdrawStEth(depositor, amount);
        assertAlmostEq(
            LIDO.balanceOf(depositor), amount, 2, "Depositor should have `amount` of steth after withdrawing"
        );
        assertEq(wrappedEth.balanceOf(depositor), 0, "Depositor should have 0 wrapped eth after withdrawing");
    }

    function test_USDCDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e6, 1e13);
        deal(address(USDC), depositor, amount);
        vm.startPrank(depositor);

        // Deposit USDC
        USDC.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositUSDC(depositor, amount);

        // Withdraw DAI by burning wrapped stablecoin - sDAI rounds down, so you lose 2 wei worth of dai(not 2 dai)
        edgelessDeposit.withdrawUSD(depositor, wrappedUSD.balanceOf(depositor) - 2);
        assertAlmostEq(
            DAI.balanceOf(depositor),
            amount * 10 ** 12,
            2,
            "Depositor should have `amount` of DAI after withdrawing - account for USDC <> DAI decimals"
        );
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(USDC.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 usdc after withdrawing");
        assertAlmostEq(DAI.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 DAI after withdrawing");
    }

    function test_USDTDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e6, 1e13);
        deal(address(USDT), depositor, amount);
        vm.startPrank(depositor);
        // Deposit USDT
        uint256 depositorInitialUSDTBalance = USDT.balanceOf(depositor);
        uint256 edgelessInitialUSDTBalance = USDT.balanceOf(address(edgelessDeposit));
        uint256 depositorInitialWrappedStablecoinBalance = wrappedUSD.balanceOf(depositor);
        assertEq(depositorInitialUSDTBalance, amount, "Depositor should have `amount` of usdt");
        assertEq(edgelessInitialUSDTBalance, 0, "Edgeless should start with 0 USDT");
        assertEq(depositorInitialWrappedStablecoinBalance, 0, "Depositor should start with 0 wrapped stablecoin");
        USDT.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositUSDT(depositor, amount, amount);

        // Withdraw DAI by burning wrapped stablecoin
        wrappedUSD.approve(address(edgelessDeposit), amount);
        edgelessDeposit.withdrawUSD(depositor, wrappedUSD.balanceOf(depositor) - 2);
        assertTrue(
            isWithinPercentage(amount * 10 ** 12, DAI.balanceOf(depositor), 1),
            "Depositor should have `amount` of DAI after withdrawing - account for USDT <> DAI decimals"
        );
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(USDT.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 usdt after withdrawing");
        assertAlmostEq(DAI.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 DAI after withdrawing");
    }

    function test_DAIDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e18, 1e25);
        deal(address(DAI), depositor, amount);
        vm.startPrank(depositor);

        // Deposit DAI
        DAI.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositDAI(depositor, amount);

        // Withdraw DAI by burning wrapped stablecoin - sDAI rounds down, so you lose 2 wei worth of dai(not 2 dai)
        edgelessDeposit.withdrawUSD(depositor, amount - 2);
        assertAlmostEq(DAI.balanceOf(depositor), amount, 2, "Depositor should have `amount` of DAI after withdrawing");
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(DAI.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 DAI after withdrawing");
    }

    function test_DAIDepositAndWithdrawWithOverflow(uint256 amount) external {
        vm.assume(amount > (type(uint256).max >> 10));
        deal(address(DAI), depositor, amount);
        vm.startPrank(depositor);

        // Deposit DAI
        DAI.approve(address(edgelessDeposit), amount);
        // expect overflow
        vm.expectRevert();
        edgelessDeposit.depositDAI(depositor, amount);
    }

    function test_DepositAndWithdrawAmount(uint64 amount, uint8 timesToCall) external {
        // Test that repeatedly depositing and withdrawing does not
        // allow the user to withdraw more than they deposited
        vm.assume(amount != 0 && timesToCall != 0);

        vm.startPrank(staker);
        edgelessDeposit.setAutoStake(false);
        vm.stopPrank();

        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), 10 ether);

        vm.startPrank(depositor);
        for (uint256 i = 0; i < timesToCall; i++) {
            edgelessDeposit.depositEth{ value: amount }(depositor);
            edgelessDeposit.withdrawEth(depositor, amount);
        }
        assertEq(
            address(depositor).balance,
            amount,
            "Depositor should have `amount` of eth after withdrawing, no more, no less"
        );
        vm.expectRevert();
        edgelessDeposit.withdrawEth(depositor, amount);
    }

    function test_MintingOnlyLido(uint64 amount) external {
        vm.assume(amount != 0);
        mintStETH(address(edgelessDeposit), amount);

        vm.startPrank(owner);
        edgelessDeposit.mintEthBasedOnStakedAmount(owner, amount);
        assertEq(wrappedEth.balanceOf(owner), amount);
    }

    function test_MintingOnlyETH(uint64 amount) external {
        vm.assume(amount != 0);

        vm.deal(address(edgelessDeposit), amount);

        vm.startPrank(owner);
        edgelessDeposit.mintEthBasedOnStakedAmount(owner, amount);
        assertEq(wrappedEth.balanceOf(owner), amount);
    }

    function test_MintingETHAndLido(uint64 ethAmount, uint64 lidoAmount) external {
        vm.assume(ethAmount != 0 && lidoAmount != 0);

        uint96 total = uint96(ethAmount) + uint96(lidoAmount);

        vm.deal(address(edgelessDeposit), ethAmount);
        mintStETH(address(edgelessDeposit), lidoAmount);

        vm.startPrank(owner);
        edgelessDeposit.mintEthBasedOnStakedAmount(owner, total);
        assertEq(wrappedEth.balanceOf(owner), total);
    }

    function test_MintingETHAndLidoWithExistingDeposits(
        uint64 ethAmount,
        uint64 depositorAmount,
        uint64 lidoAmount
    )
        external
    {
        vm.assume(ethAmount != 0 && lidoAmount != 0 && depositorAmount != 0);

        uint96 total = uint96(ethAmount) + uint96(lidoAmount);

        vm.deal(depositor, depositorAmount);
        vm.deal(address(edgelessDeposit), ethAmount);
        mintStETH(address(edgelessDeposit), lidoAmount);

        vm.startPrank(depositor);
        edgelessDeposit.depositEth{ value: depositorAmount }(depositor);
        vm.stopPrank();

        vm.startPrank(owner);
        edgelessDeposit.mintEthBasedOnStakedAmount(owner, total);
        assertEq(wrappedEth.balanceOf(owner), total);
        assertEq(wrappedEth.balanceOf(depositor), depositorAmount);
    }

    function test_LidoRequestWithdrawal(uint64 amount) external {
        vm.assume(amount > 1 gwei);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        // Deposit Eth
        edgelessDeposit.depositEth{ value: amount }(depositor);
        vm.stopPrank();

        vm.startPrank(staker);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        vm.expectEmit(false, false, false, false, address(edgelessDeposit));
        emit StakingManager.RequestedLidoWithdrawals(amounts, amounts);
        edgelessDeposit.requestLidoWithdrawal(amounts);
    }

    function test_LidoClaimWithdrawal(uint64 amount) external {
        vm.assume(amount > 1 gwei);
        vm.deal(depositor, amount);
        vm.deal(LIDO_FINALIZE_ROLE_ADDRESS, amount);

        // Deposit Eth
        vm.startPrank(depositor);
        edgelessDeposit.depositEth{ value: amount }(depositor);
        vm.stopPrank();

        vm.startPrank(staker);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory requestIds = edgelessDeposit.requestLidoWithdrawal(amounts);
        vm.stopPrank();

        vm.startPrank(LIDO_FINALIZE_ROLE_ADDRESS);
        LIDO_WITHDRAWAL_ERC721.finalize{ value: amount }(requestIds[0], 1e28);
        vm.stopPrank();

        vm.startPrank(staker);
        vm.expectEmit();
        emit StakingManager.ClaimedLidoWithdrawals(requestIds);
        edgelessDeposit.claimLidoWithdrawals(requestIds);
        assertEq(address(edgelessDeposit).balance, amount, "Edgeless should have `amount` of eth after withdrawing");
        assertEq(LIDO.balanceOf(address(edgelessDeposit)), 0, "Edgeless should have `amount` of eth after withdrawing");
    }

    function test_Ownership() external { }

    function test_Upgradability() external { }

    function isWithinPercentage(uint256 value1, uint256 value2, uint8 percentage) internal pure returns (bool) {
        require(percentage > 0 && percentage <= 100, "Percentage must be between 1 and 100");

        // Calculate the margin of error
        uint256 margin = (value1 * percentage) / 100;

        // Check if value2 is within the acceptable range
        return value2 >= value1 - margin && value2 <= value1 + margin;
    }
}
