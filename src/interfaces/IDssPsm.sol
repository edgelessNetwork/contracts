// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IDssPsm {
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
    function dai() external view returns (address);
    function gemJoin() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
}
