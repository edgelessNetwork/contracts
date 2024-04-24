// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { IRenzo } from "../interfaces/IRenzo.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LIDO } from "../Constants.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract NewRenzoStrategy is IStakingStrategy, Ownable2StepUpgradeable, UUPSUpgradeable {
    address public stakingManager;
    bool public autoStake;
    uint256 public ethUnderWithdrawal;
    IRenzo public renzo;
    IERC20 public ezETH;
    IERC20 public WETH;
    uint24 public EZETH_WETH_POOL_FEE;
    uint24 public STETH_WETH_POOL_FEE;
    ISwapRouter public swapRouter;
    uint256[48] private __gap;

    event EthStaked(uint256 amount, uint256 sharesGenerated);
    event EzEthWithdrawn(uint256 amount);
    event SetStakingManager(address stakingManager);
    event SetAutoStake(bool autoStake);

    error InsufficientFunds();
    error TransferFailed(bytes data);
    error OnlyStakingManager(address sender);
    error RequestIdsMustBeSorted();

    modifier onlyStakingManager() {
        if (msg.sender != stakingManager) revert OnlyStakingManager(msg.sender);
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _stakingManager) external initializer {
        stakingManager = _stakingManager;
        autoStake = true;
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        _transferOwnership(_owner);
        renzo = IRenzo(0x74a09653A083691711cF8215a6ab074BB4e99ef5);
        ezETH = IERC20(0xbf5495Efe5DB9ce00f80364C8B423567e58d2110);
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        EZETH_WETH_POOL_FEE = 100;
        STETH_WETH_POOL_FEE = 10_000;
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    function deposit(uint256 amount) external payable override onlyStakingManager {
        if (!autoStake) return;
        _deposit(amount);
    }

    function depositEzETH(uint256 amount) external payable onlyStakingManager {
        ezETH.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external override onlyStakingManager returns (uint256 withdrawnAmount) {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            withdrawnAmount = balance;
        } else {
            withdrawnAmount = amount;
        }
        return _withdraw(withdrawnAmount);
    }

    /// --------------------------------- 🛠️ Internal Functions 🛠️ ---------------------------------
    function _deposit(uint256 amount) internal {
        if (amount > address(this).balance) revert InsufficientFunds();
        uint256 sharesGenerated = LIDO.submit{ value: amount }(address(0));
        emit EthStaked(amount, sharesGenerated);
    }

    function _withdraw(uint256 withdrawnAmount) internal returns (uint256) {
        ezETH.transfer(address(stakingManager), withdrawnAmount);
        emit EzEthWithdrawn(withdrawnAmount);
        return withdrawnAmount;
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function ownerDeposit(uint256 amount) external payable override onlyOwner {
        _deposit(amount);
    }

    function ownerDepositEzEth(uint256 amount) external payable onlyOwner {
        ezETH.transferFrom(msg.sender, address(this), amount);
    }

    function ownerWithdraw(uint256 amount) external override onlyOwner returns (uint256 withdrawnAmount) {
        return _withdraw(amount);
    }

    function setStakingManager(address _stakingManager) external override onlyOwner {
        stakingManager = _stakingManager;
        emit SetStakingManager(_stakingManager);
    }

    function setAutoStake(bool _autoStake) external override onlyOwner {
        autoStake = _autoStake;
        emit SetAutoStake(_autoStake);
    }

    function swapStethToEzEth() external onlyOwner returns (uint256 amountOut) {
        // Approve the router to spend DAI.
        uint256 amountIn = LIDO.balanceOf(address(this));
        TransferHelper.safeApprove(address(LIDO), address(swapRouter), amountIn);

        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(address(LIDO), STETH_WETH_POOL_FEE, address(WETH), EZETH_WETH_POOL_FEE, address(ezETH)),
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountIn * 90 / 100
        });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInput(params);
        return amountOut;
    }

    /// --------------------------------- 🔎 View Functions 🔍 ---------------------------------
    function underlyingAssetAmount() external view override returns (uint256) {
        return address(this).balance + ezETH.balanceOf(address(this));
    }

    receive() external payable { }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
