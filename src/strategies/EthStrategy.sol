// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract EthStrategy is IStakingStrategy, Ownable2StepUpgradeable {
    address public stakingManager;
    bool public autoStake;

    event EthStaked(uint256 amounts);
    event EthWithdrawn(uint256 amounts);
    event RequestedLidoWithdrawals(uint256[] requestIds, uint256[] amounts);
    event ClaimedLidoWithdrawals(uint256[] requestIds);
    event SetStakingManager(address stakingManager);
    event SetAutoStake(bool autoStake);

    error InsufficientFunds();
    error TransferFailed(bytes data);
    error OnlyStakingManager(address sender);

    modifier onlyStakingManager() {
        if (msg.sender != stakingManager) revert OnlyStakingManager(msg.sender);
        _;
    }

    function initialize(address _owner, address _stakingManager) external initializer {
        stakingManager = _stakingManager;
        autoStake = true;
        __Ownable_init(_owner);
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    function deposit(uint256 amounts) external payable onlyStakingManager {
        if (!autoStake) {
            return;
        }
        if (amounts > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amounts }(address(0));
        emit EthStaked(amounts);
    }

    function withdraw(uint256 amounts) external onlyStakingManager returns (uint256 withdrawnAmount) {
        uint256 balance = address(this).balance;
        if (amounts > balance) {
            withdrawnAmount = balance;
        } else {
            withdrawnAmount = amounts;
        }
        (bool success, bytes memory data) = stakingManager.call{ value: withdrawnAmount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit EthWithdrawn(withdrawnAmount);
        return withdrawnAmount;
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function ownerDeposit(uint256 amount) external payable onlyOwner {
        if (amount > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amount }(address(0));
        emit EthStaked(amount);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner returns (uint256 withdrawnAmount) {
        (bool success, bytes memory data) = stakingManager.call{ value: amount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit EthWithdrawn(amount);
        return amount;
    }

    function requestLidoWithdrawal(uint256[] calldata amounts)
        external
        onlyOwner
        returns (uint256[] memory requestIds)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        LIDO.approve(address(LIDO_WITHDRAWAL_ERC721), total);
        requestIds = LIDO_WITHDRAWAL_ERC721.requestWithdrawals(amounts, address(this));
        emit RequestedLidoWithdrawals(requestIds, amounts);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external onlyOwner {
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        emit ClaimedLidoWithdrawals(requestIds);
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
        return address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function underlyingAssetAmountNoUpdate() public view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }

    function underlyingAssetAmount() external view returns (uint256) {
        return underlyingAssetAmountNoUpdate();
    }
}
