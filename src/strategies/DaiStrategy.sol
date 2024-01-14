// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Dai, DSR_MANAGER, _RAY } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { IPot } from "../interfaces/IPot.sol";
import { MakerMath } from "../lib/MakerMath.sol";

contract DaiStrategy is IStakingStrategy, Ownable2StepUpgradeable {
    address public stakingManager;
    bool public autoStake;

    event DaiStaked(uint256 amount);
    event DaiWithdrawn(uint256 amount);
    event SetStakingManager(address stakingManager);
    event SetAutoStake(bool autoStake);

    error InsufficientFunds();

    function initialize(address _owner, address _stakingManager) external initializer {
        stakingManager = _stakingManager;
        autoStake = true;
        __Ownable_init(_owner);
    }

    modifier onlyStakingManager() {
        require(msg.sender == stakingManager, "DaiStrategy: Only staking manager");
        _;
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    function deposit(uint256 amount) external payable onlyStakingManager {
        if (!autoStake) {
            return;
        }
        Dai.transferFrom(msg.sender, address(this), amount);
        Dai.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit DaiStaked(amount);
    }

    function withdraw(uint256 amount) external onlyStakingManager returns (uint256 withdrawnAmount) {
        uint256 balanceBefore = Dai.balanceOf(address(this));
        if (balanceBefore < amount) DSR_MANAGER.exit(address(this), amount);
        uint256 balanceAfter = Dai.balanceOf(address(this));
        withdrawnAmount = balanceAfter - balanceBefore;
        Dai.transfer(stakingManager, withdrawnAmount);
        emit DaiWithdrawn(withdrawnAmount);
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function ownerDeposit(uint256 amount) external payable onlyOwner {
        Dai.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit DaiStaked(amount);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner returns (uint256 withdrawnAmount) {
        uint256 balanceBefore = Dai.balanceOf(address(this));
        if (balanceBefore < amount) DSR_MANAGER.exit(address(this), amount);
        uint256 balanceAfter = Dai.balanceOf(address(this));
        withdrawnAmount = balanceAfter - balanceBefore;
        Dai.transfer(stakingManager, withdrawnAmount);
        emit DaiWithdrawn(withdrawnAmount);
    }

    function setStakingManager(address _stakingManager) external onlyOwner {
        stakingManager = _stakingManager;
        emit SetStakingManager(_stakingManager);
    }

    function setAutoStake(bool _autoStake) external onlyOwner {
        autoStake = _autoStake;
        emit SetAutoStake(_autoStake);
    }

    /// --------------------------------- 🔎 View Functions 🔍 ---------------------------------
    function underlyingAsset() external pure returns (address) {
        return address(Dai);
    }

    function underlyingAssetAmountNoUpdate() external view returns (uint256) {
        IPot pot = DSR_MANAGER.pot();
        uint256 chi = MakerMath.rmul(MakerMath.rpow(pot.dsr(), block.timestamp - pot.rho(), _RAY), pot.chi());
        return Dai.balanceOf(address(this)) + MakerMath.rmul(DSR_MANAGER.pieOf(address(this)), chi);
    }

    function underlyingAssetAmount() external returns (uint256) {
        return Dai.balanceOf(address(this)) + DSR_MANAGER.daiBalance(address(this));
    }
}
