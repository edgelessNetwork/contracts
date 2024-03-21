// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStakingStrategy } from "./interfaces/IStakingStrategy.sol";

/**
 * @notice The purpose of this contract is solely to take in assets and send them to strategies.
 */
contract StakingManager is Ownable2StepUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address => IStakingStrategy[]) public strategies;
    mapping(address => uint256) public activeStrategyIndex;
    mapping(address => IStakingStrategy) public allStrategies;
    address public staker;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256[50] private __gap;

    event Stake(address indexed asset, uint256 amount);
    event Withdraw(address indexed asset, uint256 amount);
    event SetStaker(address staker);
    event AddStrategy(address indexed asset, IStakingStrategy indexed strategy);
    event SetActiveStrategy(address indexed asset, uint256 index);
    event RemoveStrategy(address indexed asset, IStakingStrategy indexed strategy, uint256 newActiveStrategyIndex);

    error OnlyStaker(address sender);
    error TransferFailed(bytes data);

    modifier onlyStaker() {
        if (msg.sender != staker) revert OnlyStaker(msg.sender);
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        _transferOwnership(_owner);
    }

    /// -------------------------------- 📝 Staker Functions 📝 --------------------------------
    function stake(address asset) external payable onlyStaker {
        require(asset == ETH_ADDRESS, "Unsupported asset");
        _stakeEth(msg.value);
        emit Stake(asset, msg.value);
    }

    function _stakeEth(uint256 amount) internal {
        IStakingStrategy strategy = getActiveStrategy(ETH_ADDRESS);
        strategy.deposit{ value: amount }(amount);
    }

    function withdraw(uint256 amount) external onlyStaker returns (uint256) {
        return _withdrawEth(amount);
    }

    function _withdrawEth(uint256 amount) internal returns (uint256 withdrawnAmount) {
        IStakingStrategy strategy = getActiveStrategy(ETH_ADDRESS);
        if (address(strategy) != address(0)) {
            withdrawnAmount = strategy.withdraw(amount);
        } else {
            withdrawnAmount = amount > address(this).balance ? address(this).balance : amount;
        }
        (bool success, bytes memory data) = staker.call{ value: withdrawnAmount }("");
        if (!success) revert TransferFailed(data);
        emit Withdraw(ETH_ADDRESS, withdrawnAmount);
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    function setStaker(address _staker) external onlyOwner {
        staker = _staker;
        emit SetStaker(_staker);
    }

    function addStrategy(address asset, IStakingStrategy strategy) external onlyOwner {
        require(ETH_ADDRESS == asset, "Unsupported asset");
        require(allStrategies[address(strategy)] == IStakingStrategy(address(0)), "Strategy already exists");
        strategies[asset].push(strategy);
        emit AddStrategy(asset, strategy);
    }

    function setActiveStrategy(address asset, uint256 index) external onlyOwner {
        require(index < strategies[asset].length, "Invalid index");
        activeStrategyIndex[asset] = index;
        emit SetActiveStrategy(asset, index);
    }

    function withdrawToStaker(address asset, uint256 index, uint256 amount) public onlyOwner {
        IStakingStrategy strategy = strategies[asset][index];
        uint256 withdrawnAmount = strategy.withdraw(amount);
        (bool success, bytes memory data) = staker.call{ value: withdrawnAmount }("");
        if (!success) revert TransferFailed(data);
        emit Withdraw(staker, withdrawnAmount);
    }

    function removeStrategy(address asset, uint256 index, uint256 newActiveStrategyIndex) public onlyOwner {
        require(newActiveStrategyIndex < strategies[asset].length - 1, "Invalid index");
        IStakingStrategy strategy = strategies[asset][index];
        uint256 lastIndex = strategies[asset].length - 1;
        strategies[asset][index] = strategies[asset][lastIndex];
        strategies[asset].pop();
        activeStrategyIndex[asset] = newActiveStrategyIndex;
        allStrategies[address(strategy)] = IStakingStrategy(address(0));
        emit RemoveStrategy(asset, strategy, newActiveStrategyIndex);
    }

    function withdrawAndRemoveStrategy(
        address asset,
        uint256 index,
        uint256 amount,
        uint256 newActiveStrategyIndex
    )
        public
        onlyOwner
    {
        withdrawToStaker(asset, index, amount);
        removeStrategy(asset, index, newActiveStrategyIndex);
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

    receive() external payable {
        bool validSender = false;
        for (uint256 i = 0; i < strategies[ETH_ADDRESS].length; i++) {
            if (msg.sender == address(strategies[ETH_ADDRESS][i])) {
                validSender = true;
                break;
            }
        }
        require(validSender, "Invalid sender");
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
