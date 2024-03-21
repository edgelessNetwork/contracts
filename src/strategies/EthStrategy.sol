// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

contract EthStrategy is IStakingStrategy, Ownable2StepUpgradeable, UUPSUpgradeable {
    address public stakingManager;
    bool public autoStake;
    uint256 public ethUnderWithdrawal;
    uint256[50] private __gap;

    event EthStaked(uint256 amount, uint256 sharesGenerated);
    event EthWithdrawn(uint256 amount);
    event RequestedLidoWithdrawals(uint256[] requestIds, uint256[] amounts);
    event ClaimedLidoWithdrawals(uint256[] requestIds);
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
        __Ownable_init(_owner);
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    function deposit(uint256 amount) external payable override onlyStakingManager {
        if (!autoStake) return;
        _deposit(amount);
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
        (bool success, bytes memory data) = stakingManager.call{ value: withdrawnAmount }("");
        if (!success) revert TransferFailed(data);
        emit EthWithdrawn(withdrawnAmount);
        return withdrawnAmount;
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function ownerDeposit(uint256 amount) external payable override onlyOwner {
        _deposit(amount);
    }

    function ownerWithdraw(uint256 amount) external override onlyOwner returns (uint256 withdrawnAmount) {
        return _withdraw(amount);
    }

    function requestLidoWithdrawal(uint256[] calldata amounts)
        external
        onlyOwner
        returns (uint256[] memory requestIds)
    {
        require(ethUnderWithdrawal == 0, "EthStrategy: Withdrawal already in progress");
        uint256 total;
        for (uint256 i; i < amounts.length; ++i) {
            total += amounts[i];
        }
        require(LIDO.approve(address(LIDO_WITHDRAWAL_ERC721), total), "approve failed");
        requestIds = LIDO_WITHDRAWAL_ERC721.requestWithdrawals(amounts, address(this));
        ethUnderWithdrawal += total;
        emit RequestedLidoWithdrawals(requestIds, amounts);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external onlyOwner {
        // Check if requestIds is sorted
        for (uint256 i = 0; i < requestIds.length - 1; i++) {
            if (requestIds[i] > requestIds[i + 1]) revert RequestIdsMustBeSorted();
        }
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        ethUnderWithdrawal = 0;
        emit ClaimedLidoWithdrawals(requestIds);
    }

    function setStakingManager(address _stakingManager) external override onlyOwner {
        stakingManager = _stakingManager;
        emit SetStakingManager(_stakingManager);
    }

    function setAutoStake(bool _autoStake) external override onlyOwner {
        autoStake = _autoStake;
        emit SetAutoStake(_autoStake);
    }

    /// --------------------------------- 🔎 View Functions 🔍 ---------------------------------
    function underlyingAssetAmount() external view override returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this)) + ethUnderWithdrawal;
    }

    receive() external payable { }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
