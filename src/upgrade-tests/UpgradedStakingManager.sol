// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";

/**
 * @notice The purpose of this contract is solely to take in assets and send them to strategies.
 * Upon withdrawal, all assets go to the depositor. The depositor needs to be set after deployment
 */
contract UpgradedStakingManager is Ownable2StepUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => IStakingStrategy[]) public strategies;
    mapping(address => uint256) public activeStrategyIndex;
    address public staker;
    address public depositor;
    bool public autoStake;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256[50] private __gap;

    function doNothing() external { }

    receive() external payable { }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
