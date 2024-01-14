// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IStakingStrategy } from "./interfaces/IStakingStrategy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { console2 } from "forge-std/src/console2.sol";
/**
 * @notice The purpose of this contract is solely to take in assets and send them to strategies.
 * Upon withdrawal, all assets go to the depositor.
 * TODO: The depositor needs to be set after deployment
 */

contract StakingManager is OwnableUpgradeable {
    error OnlyStaker(address sender);

    mapping(address => IStakingStrategy[]) public strategies;
    mapping(address => uint256) public activeStrategyIndex;
    address public staker;
    address public depositor;
    bool public autoStake;
    address public constant Eth_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    error TransferFailed(bytes data);

    modifier onlyStaker() {
        if (msg.sender != staker) {
            revert OnlyStaker(msg.sender);
        }
        _;
    }

    function initialize(address _owner, address _staker) external initializer {
        staker = _staker;
        __Ownable_init(_owner);
    }

    function stake(address asset, uint256 amount) external payable onlyStaker {
        if (asset == Eth_ADDRESS) {
            _stakeEth(msg.value);
        } else {
            _stakeERC20(asset, amount);
        }
    }

    function _stakeEth(uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(Eth_ADDRESS);
        strategy.deposit{ value: amount }(amount);
    }

    function _stakeERC20(address asset, uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(asset);
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(strategy), amount);
        strategy.deposit(amount);
    }

    function withdraw(address asset, uint256 amount) external onlyStaker {
        if (asset == Eth_ADDRESS) {
            _withdrawEth(amount);
        } else {
            _withdrawERC20(asset, amount);
        }
    }

    function _withdrawEth(uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(Eth_ADDRESS);
        uint256 withdrawnAmount;
        if (address(strategy) != address(0)) withdrawnAmount = strategy.withdraw(amount);
        (bool success, bytes memory data) = depositor.call{ value: withdrawnAmount }("");
        if (!success) {
            revert TransferFailed(data);
        }
    }

    function _withdrawERC20(address asset, uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(asset);
        uint256 withdrawnAmount;
        if (address(strategy) != address(0)) {
            withdrawnAmount = strategy.withdraw(amount);
        }
        IERC20(asset).transfer(depositor, withdrawnAmount);
    }

    function setStaker(address _staker) external onlyOwner {
        staker = _staker;
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    /// ----------------- Helper Functions -----------------

    function setAutoStake(bool _autoStake) external onlyOwner {
        autoStake = _autoStake;
    }

    function addStrategy(address asset, IStakingStrategy strategy) external onlyOwner {
        strategies[asset].push(strategy);
    }

    function setActiveStrategy(address asset, uint256 index) external onlyOwner {
        activeStrategyIndex[asset] = index;
    }

    function getActiveStrategy(address asset) public view returns (IStakingStrategy) {
        return strategies[asset][activeStrategyIndex[asset]];
    }

    function getAssetTotal(address asset) external returns (uint256 total) {
        for (uint256 i = 0; i < strategies[asset].length; i++) {
            IStakingStrategy strategy = strategies[asset][i];
            total += strategy.underlyingAssetAmount();
        }
    }

    function getAssetTotalNoUpdate(address asset) external view returns (uint256 total) {
        for (uint256 i = 0; i < strategies[asset].length; i++) {
            IStakingStrategy strategy = strategies[asset][i];
            total += strategy.underlyingAssetAmountNoUpdate();
        }
    }

    function removeStrategy(address asset, uint256 index) external onlyOwner {
        IStakingStrategy strategy = strategies[asset][index];
        uint256 lastIndex = strategies[asset].length - 1;
        strategies[asset][index] = strategies[asset][lastIndex];
        strategies[asset].pop();
        if (activeStrategyIndex[asset] == index) {
            activeStrategyIndex[asset] = lastIndex;
        }
        strategy.withdraw(strategy.underlyingAssetAmount());
    }

    receive() external payable { }
}
