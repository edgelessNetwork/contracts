// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface ICurve3Pool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}
