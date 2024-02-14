// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IStakingStrategy {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount);
    function ownerDeposit(uint256 amount) external payable;
    function ownerWithdraw(uint256 amount) external returns (uint256 withdrawnAmount);
    function setStakingManager(address _stakingManager) external;
    function setAutoStake(bool _autoStake) external;

    function underlyingAssetAmount() external view returns (uint256);
    function autoStake() external view returns (bool);
    function stakingManager() external view returns (address);
}
