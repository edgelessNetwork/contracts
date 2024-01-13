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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils {
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

        vm.startPrank(owner);

        address stakingManagerImpl = address(new StakingManager());
        bytes memory stakingManagerData = abi.encodeCall(StakingManager.initialize, (owner, staker));
        stakingManager = StakingManager(payable(address(new ERC1967Proxy(stakingManagerImpl, stakingManagerData))));

        address edgelessDepositImpl = address(new EdgelessDeposit());
        bytes memory edgelessDepositData =
            abi.encodeCall(EdgelessDeposit.initialize, (owner, staker, IL1StandardBridge(address(1)), stakingManager));
        edgelessDeposit = EdgelessDeposit(payable(address(new ERC1967Proxy(edgelessDepositImpl, edgelessDepositData))));

        stakingManager.setStaker(address(edgelessDeposit));
        stakingManager.setDepositor(address(edgelessDeposit));
        address ethStakingStrategyImpl = address(new EthStrategy());
        bytes memory ethStakingStrategyData = abi.encodeCall(EthStrategy.initialize, (owner, address(stakingManager)));
        ethStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(ethStakingStrategyImpl, ethStakingStrategyData))));
        stakingManager.addStrategy(stakingManager.ETH_ADDRESS(), ethStakingStrategy);
        stakingManager.setActiveStrategy(stakingManager.ETH_ADDRESS(), 0);

        address daiStakingStrategyImpl = address(new DaiStrategy());
        bytes memory daiStakingStrategyData = abi.encodeCall(DaiStrategy.initialize, (owner, address(stakingManager)));
        daiStakingStrategy =
            IStakingStrategy(payable(address(new ERC1967Proxy(daiStakingStrategyImpl, daiStakingStrategyData))));
        stakingManager.addStrategy(address(DAI), daiStakingStrategy);
        stakingManager.setActiveStrategy(address(DAI), 0);

        wrappedEth = edgelessDeposit.wrappedEth();
        wrappedUSD = edgelessDeposit.wrappedUSD();
        edgelessDeposit.setAutoBridge(false);
        vm.stopPrank();
        vm.prank(staker);

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
        depositAndWithdrawUSD(depositor, address(DAI), amount);
    }

    // TODO: Add more checks for all variables: sDAI balance, DAI balance, etc.
    function depositAndWithdrawUSD(address depositor, address asset, uint256 amount) internal {
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
