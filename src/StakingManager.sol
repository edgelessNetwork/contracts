// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStakingStrategy } from "./interfaces/IStakingStrategy.sol";

/**
 * @notice The purpose of this contract is solely to take in assets and send them to strategies.
 * Upon withdrawal, all assets go to the depositor. The depositor needs to be set after deployment
 */
contract StakingManager is Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => IStakingStrategy[]) public strategies;
    mapping(address => uint256) public activeStrategyIndex;
    address public staker;
    address public depositor;
    bool public autoStake;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    event Stake(address indexed asset, uint256 amount);
    event Withdraw(address indexed asset, uint256 amount);
    event SetStaker(address staker);
    event SetDepositor(address depositor);
    event SetAutoStake(bool autoStake);
    event AddStrategy(address indexed asset, IStakingStrategy indexed strategy);
    event SetActiveStrategy(address indexed asset, uint256 index);
    event RemoveStrategy(address indexed asset, IStakingStrategy indexed strategy, uint256 withdrawnAmount);

    error OnlyStaker(address sender);
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

    /// -------------------------------- 📝 Staker Functions 📝 --------------------------------
    function stake(address asset, uint256 amount) external payable onlyStaker {
        _stakeEth(msg.value);
        emit Stake(asset, amount);
    }

    function _stakeEth(uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(ETH_ADDRESS);
        strategy.deposit{ value: amount }(amount);
    }

    function withdraw(uint256 amount) external onlyStaker {
        _withdrawEth(amount);
    }

    function _withdrawEth(uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(ETH_ADDRESS);
        uint256 withdrawnAmount;
        if (address(strategy) != address(0)) withdrawnAmount = strategy.withdraw(amount);
        (bool success, bytes memory data) = depositor.call{ value: withdrawnAmount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit Withdraw(ETH_ADDRESS, amount);
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function setStaker(address _staker) external onlyOwner {
        staker = _staker;
        emit SetStaker(_staker);
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
        emit SetDepositor(_depositor);
    }

    function setAutoStake(bool _autoStake) external onlyOwner {
        autoStake = _autoStake;
        emit SetAutoStake(_autoStake);
    }

    function addStrategy(address asset, IStakingStrategy strategy) external onlyOwner {
        strategies[asset].push(strategy);
        emit AddStrategy(asset, strategy);
    }

    function setActiveStrategy(address asset, uint256 index) external onlyOwner {
        activeStrategyIndex[asset] = index;
        emit SetActiveStrategy(asset, index);
    }

    function removeStrategy(address asset, uint256 index) external onlyOwner {
        IStakingStrategy strategy = strategies[asset][index];
        uint256 lastIndex = strategies[asset].length - 1;
        strategies[asset][index] = strategies[asset][lastIndex];
        strategies[asset].pop();
        if (activeStrategyIndex[asset] == index) {
            activeStrategyIndex[asset] = lastIndex;
        }
        uint256 withdrawnAmount = strategy.withdraw(strategy.underlyingAssetAmount());
        emit RemoveStrategy(asset, strategy, withdrawnAmount);
    }

    /// --------------------------------- 🔎 View Functions 🔍 ---------------------------------
    function getActiveStrategy(address asset) public view returns (IStakingStrategy) {
        return strategies[asset][activeStrategyIndex[asset]];
    }

    function getAssetTotal(address asset) external view returns (uint256 total) {
        for (uint256 i = 0; i < strategies[asset].length; i++) {
            IStakingStrategy strategy = strategies[asset][i];
            total += strategy.underlyingAssetAmount();
        }
    }

    receive() external payable { }
}
