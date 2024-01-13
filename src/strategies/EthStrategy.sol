// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract EthStrategy is IStakingStrategy, OwnableUpgradeable {
    error InsufficientFunds();
    error TransferFailed(bytes data);

    address public stakingManager;
    bool public autoStake;

    event EthStaked(uint256 amount);
    event EthWithdrawn(uint256 amount);
    event RequestedLidoWithdrawals(uint256[] requestIds, uint256[] amounts);
    event ClaimedLidoWithdrawals(uint256[] requestIds);

    function initialize(address _owner, address _stakingManager) external initializer {
        stakingManager = _stakingManager;
        autoStake = true;
        __Ownable_init(_owner);
    }

    function deposit(uint256 amount) external payable {
        if (!autoStake) {
            return;
        }
        if (amount > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amount }(address(0));
        emit EthStaked(amount);
    }

    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount) {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            withdrawnAmount = balance;
        } else {
            withdrawnAmount = amount;
        }
        (bool success, bytes memory data) = stakingManager.call{ value: withdrawnAmount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit EthWithdrawn(withdrawnAmount);
        return withdrawnAmount;
    }

    function ownerDeposit(uint256 amount) external payable onlyOwner {
        if (amount > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amount }(address(0));
        emit EthStaked(amount);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool success, bytes memory data) = stakingManager.call{ value: amount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit EthWithdrawn(amount);
    }

    function underlyingAsset() external pure returns (address) {
        return address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function underlyingAssetAmountNoUpdate() public view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }

    function underlyingAssetAmount() external view returns (uint256) {
        return underlyingAssetAmountNoUpdate();
    }

    // ------------- Withdrawal helper functions -------------
    function requestLidoWithdrawal(uint256[] calldata amount)
        external
        onlyOwner
        returns (uint256[] memory requestIds)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        LIDO.approve(address(LIDO_WITHDRAWAL_ERC721), total);
        requestIds = LIDO_WITHDRAWAL_ERC721.requestWithdrawals(amount, address(this));
        emit RequestedLidoWithdrawals(requestIds, amount);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external onlyOwner {
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        emit ClaimedLidoWithdrawals(requestIds);
    }

    function setStakingManager(address _stakingManager) external onlyOwner {
        stakingManager = _stakingManager;
    }

    function setAutoStake(bool _autoStake) external onlyOwner {
        autoStake = _autoStake;
    }
}
