// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IStakingStrategy } from "./interfaces/IStakingStrategy.sol";

/**
 * @notice The purpose of this contract is solely to take in assets and send them to strategies.
 * Upon withdrawal, all assets go to the depositor.
 * TODO: The depositor needs to be set after deployment
 */
contract StakingManager is Ownable2Step {
    mapping(address => IStakingStrategy[]) public strategies;
    mapping(address => uint256) public activeStrategyIndex;
    address public staker;
    address public depositor;
    bool public autoStake;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier onlyStaker() {
        require(msg.sender == staker, "Sender is not staker");
        _;
    }

    constructor(address _owner, address _staker) Ownable(_owner) { }

    function stake(address asset, uint256 amount) external onlyStaker { }

    function withdraw(address asset, uint256 amount) external onlyStaker { }

    /// ----------------- Helper Functions -----------------

    function setAutoStake(bool _autoStake) external onlyOwner { }

    function addStrategy(address asset, IStakingStrategy strategy) external onlyOwner { }

    function setActiveStrategy(address asset, uint256 index) external onlyOwner { }

    function getActiveStrategy(address asset) public view returns (IStakingStrategy) { }
}
