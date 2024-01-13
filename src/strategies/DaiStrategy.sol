// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { DAI, DSR_MANAGER, _RAY } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IPot } from "../interfaces/IPot.sol";
import { MakerMath } from "../lib/MakerMath.sol";
import { console2 } from "forge-std/src/console2.sol";

contract DaiStrategy is IStakingStrategy, OwnableUpgradeable {
    error InsufficientFunds();

    event DaiStaked(uint256 amount);
    event DaiWithdrawn(uint256 amount);

    address public stakingManager;
    bool public autoStake;

    function initialize(address _owner, address _stakingManager) external initializer {
        stakingManager = _stakingManager;
        autoStake = true;
        __Ownable_init(_owner);
    }

    function deposit(uint256 amount) external payable {
        if (!autoStake) {
            return;
        }
        DAI.transferFrom(msg.sender, address(this), amount);
        DAI.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit DaiStaked(amount);
    }

    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount) {
        uint256 balanceBefore = DAI.balanceOf(address(this));
        DSR_MANAGER.exit(address(this), amount);
        uint256 balanceAfter = DAI.balanceOf(address(this));
        withdrawnAmount = balanceAfter - balanceBefore;
        DAI.transfer(stakingManager, withdrawnAmount);
        emit DaiWithdrawn(withdrawnAmount);
    }

    function ownerDeposit(uint256 amount) external payable onlyOwner {
        DAI.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit DaiStaked(amount);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner returns (uint256 withdrawnAmount) {
        uint256 balanceBefore = DAI.balanceOf(address(this));
        DSR_MANAGER.exit(address(this), amount);
        uint256 balanceAfter = DAI.balanceOf(address(this));
        emit DaiWithdrawn(balanceAfter - balanceBefore);
        return balanceAfter - balanceBefore;
    }

    function underlyingAsset() external pure returns (address) {
        return address(DAI);
    }

    function underlyingAssetAmountNoUpdate() external view returns (uint256) {
        IPot pot = DSR_MANAGER.pot();
        uint256 chi = MakerMath.rmul(MakerMath.rpow(pot.dsr(), block.timestamp - pot.rho(), _RAY), pot.chi());
        return DAI.balanceOf(address(this)) + MakerMath.rmul(DSR_MANAGER.pieOf(address(this)), chi);
    }

    function underlyingAssetAmount() external returns (uint256) {
        return DAI.balanceOf(address(this)) + DSR_MANAGER.daiBalance(address(this));
    }

    function setStakingManager(address _stakingManager) external onlyOwner {
        stakingManager = _stakingManager;
    }

    function setAutoStake(bool _autoStake) external onlyOwner {
        autoStake = _autoStake;
    }
}
