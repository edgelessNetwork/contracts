// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IStakingStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount);

    function underlyingAsset() external view returns (address);
    function underlyingAssetAmount() external view returns (uint256);
    function underlyingAssetAmountNoUpdate() external returns (uint256);
}
