// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract EthStrategy is IStakingStrategy, OwnableUpgradeable {
    error InsufficientFunds();

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
    }

    function deposit(uint256 amount) external payable {
        if (amount > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amount }(address(0));
        // emit EthStaked(amount);
    }

    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount) {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            withdrawnAmount = balance;
        } else {
            withdrawnAmount = amount;
        }
        payable(msg.sender).transfer(withdrawnAmount);
        // emit EthWithdrawn(withdrawnAmount);
        return withdrawnAmount;
    }

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
        // emit RequestedLidoWithdrawals(requestIds, amount);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external onlyOwner {
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        // emit ClaimedLidoWithdrawals(requestIds);
    }

    function underlyingAsset() external view returns (address) { }
    function underlyingAssetAmount() external view returns (uint256) { }
    function underlyingAssetAmountNoUpdate() external returns (uint256) { }
}
