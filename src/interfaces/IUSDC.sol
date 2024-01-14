// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IUsdc is IERC20, IERC20Permit {
    function transferWithAuthorization(
        address,
        address,
        uint256,
        uint256,
        uint256,
        bytes32,
        uint8,
        bytes32,
        bytes32
    )
        external;
}
