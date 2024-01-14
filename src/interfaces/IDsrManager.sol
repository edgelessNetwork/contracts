// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IPot } from "./IPot.sol";

interface IDsrManager {
    function join(address dst, uint256 wad) external;
    function exit(address dst, uint256 wad) external;
    function exitAll(address dst) external;
    function DaiBalance(address usr) external returns (uint256 wad);
    function pot() external view returns (IPot);
    function pieOf(address) external view returns (uint256);
}
