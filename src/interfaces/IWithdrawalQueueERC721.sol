// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

/// @notice output format struct for `_getWithdrawalStatus()` mEthod
struct WithdrawalRequestStatus {
    /// @notice stEth token amount that was locked on withdrawal queue for this request
    uint256 amountOfStEth;
    /// @notice amount of stEth shares locked on withdrawal queue for this request
    uint256 amountOfShares;
    /// @notice address that can claim or transfer this request
    address owner;
    /// @notice timestamp of when the request was created, in seconds
    uint256 timestamp;
    /// @notice true, if request is finalized
    bool isFinalized;
    /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
    bool isClaimed;
}

interface IWithdrawalQueueERC721 {
    function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external;
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    )
        external
        view
        returns (uint256[] memory hintIds);
    function finalize(uint256 _lastRequestIdToBeFinalized, uint256 _maxShareRate) external payable;
    function getLastCheckpointIndex() external view returns (uint256);
    function getWithdrawalStatus(uint256[] calldata _requestIds)
        external
        view
        returns (WithdrawalRequestStatus[] memory statuses);
    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    )
        external
        returns (uint256[] memory requestIds);
}
