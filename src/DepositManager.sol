// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

/**
 * @title DepositManager
 * @notice DepositManager is a library of functions that take in an amount of Eth and calculates how much of the
 * corresponding wrapped token to mint.
 */
contract DepositManager {
    error ZeroDeposit();

    /**
     * @notice Deposit Eth to the Eth pool
     * @dev Amount is msg.value
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositEth(uint256 amount) internal pure returns (uint256 mintAmount) {
        if (amount == 0) {
            revert ZeroDeposit();
        }
        return amount;
    }
}
