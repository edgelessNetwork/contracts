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
import { EthStrategy } from "../src/strategies/EthStrategy.sol";
import { DaiStrategy } from "../src/strategies/DaiStrategy.sol";

import { IDAI } from "../src/interfaces/IDAI.sol";
import { IL1StandardBridge } from "../src/interfaces/IL1StandardBridge.sol";
import { ILido } from "../src/interfaces/ILido.sol";
import { IUSDT } from "../src/interfaces/IUSDT.sol";
import { IUSDC } from "../src/interfaces/IUSDC.sol";
import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../src/interfaces/IStakingStrategy.sol";

import { Permit, SigUtils } from "./SigUtils.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    WrappedToken internal wrappedUSD;
    IL1StandardBridge internal l1standardBridge;
    StakingManager internal stakingManager;
    IStakingStrategy internal ethStakingStrategy;
    IStakingStrategy internal daiStakingStrategy;

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
    uint256 public depositorKey = uint256(keccak256(abi.encodePacked("Depositor")));
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth, wrappedUSD, ethStakingStrategy, daiStakingStrategy) =
            deployContracts(owner, owner);

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
    function test_basicDeposit(uint64 amount) external {
        vm.prank(owner);
        stakingManager.setAutoStake(false);
        vm.assume(amount != 0);
        vm.startPrank(depositor);
        vm.deal(depositor, amount);
        vm.deal(address(edgelessDeposit), amount);

        edgelessDeposit.depositEth{ value: amount }(depositor);
        assertEq(wrappedEth.balanceOf(depositor), amount);
        assertEq(address(depositor).balance, 0 ether);
    }

    function test_DAIDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e18, 1e25);
        deal(address(DAI), depositor, amount);
        depositAndWithdrawDAI(depositor, address(DAI), amount);
    }

    function test_USDCDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e6, 1e9);
        deal(address(USDC), depositor, amount);
        // depositAndWithdrawUSDC(depositor, address(USDC), amount);
    }

    function test_USDTDepositAndWithdraw(uint256 amount) external {
        amount = bound(amount, 1e6, 1e9);
        deal(address(USDT), depositor, amount);
        // depositAndWithdrawUSDT(depositor, address(USDT), amount);
    }

    function test_EthDepositAndWithdraw(uint256 amount) external { }

    function test_USDCPermitDepositAndWithdraw(uint256 amount) external { }
    function test_DAIPermitDepositAndWithdraw(uint256 amount) external { }

    function test_DAIDepositAndWithdrawWithOverflow(uint256 amount) external { }

    function test_EthMint(uint256 amount) external { }
    function test_DAIMint(uint256 amount) external { }

    function test_EthMintWithDeposit(uint256 amount) external { }
    function test_DAIMintWithDeposit(uint256 amount) external { }
    function test_LidoRequestWithdrawal(uint64 amount) external { }
    function test_LidoClaimWithdrawal(uint64 amount) external { }
    function test_setStakerWithPermission() external { }
    function test_setStakerWithoutPermission() external { }
    function test_setL1StandardBridgeWithPermission() external { }
    function test_setL1StandardBridgeWithoutPermission() external { }
    function test_setAutoBridgeWithPermission() external { }
    function test_setAutoBridgeWithoutPermission() external { }
    function test_setActiveStrategyWithPermission() external { }
    function test_setActiveStrategyWithoutPermission() external { }
    function test_setAutoStakeWithPermission() external { }
    function test_setAutoStakeWithoutPermission() external { }
    function test_setL2EthAsOwner() external { }
    function test_setL2EthAsNonOwner() external { }
    function test_upgradability() external { }

    // TODO: Add more checks for all variables: sDAI balance, DAI balance, etc.
    function depositAndWithdrawDAI(address depositor, address asset, uint256 amount) internal {
        vm.startPrank(depositor);
        // Deposit DAI
        DAI.approve(address(edgelessDeposit), amount);
        edgelessDeposit.depositDAI(depositor, amount);

        // Withdraw DAI by burning wrapped stablecoin - sDAI rounds down, so you lose 2 wei worth of dai(not 2 dai)
        edgelessDeposit.withdrawUSD(depositor, amount - 2);
        assertAlmostEq(DAI.balanceOf(depositor), amount, 2, "Depositor should have `amount` of DAI afterwithdrawing");
        assertAlmostEq(
            wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
        );
        assertAlmostEq(DAI.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 DAI afterwithdrawing");
    }
}
