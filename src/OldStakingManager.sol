// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, DAI, _RAY, DSR_MANAGER, LIDO_WITHDRAWAL_ERC721 } from "./Constants.sol";

import { IPot } from "./interfaces/IPot.sol";

import { MakerMath } from "./lib/MakerMath.sol";

/**
 * @title StakingManager
 * @notice Manages staking of pooled funds, the goal is to maintain the minimum amount of ETH
 * and DAI so users can withdraw their funds without delay, while maximizing the staking yield.
 */
abstract contract StakingManager {
    bool public autoStake;
    address public staker;

    event ClaimedLidoWithdrawals(uint256[] requestIds);
    event DaiStaked(uint256 amount);
    event EthStaked(uint256 amount);
    event RequestedLidoWithdrawals(uint256[] requestIds, uint256[] amounts);
    event SetAutoStake(bool autoDeposit);
    event SetStaker(address staker);

    error InsufficientFunds();
    error SenderIsNotStaker();

    modifier onlyStaker() {
        if (msg.sender != staker) revert SenderIsNotStaker();
        _;
    }

    /**
     * @notice Only the owner of EdgelessDeposit can set the staker address
     */
    function setStaker(address _staker) external virtual;

    function _setStaker(address _staker) internal {
        staker = _staker;
        emit SetStaker(_staker);
    }

    /**
     * @notice Set autoStake to true so all deposits sent to this contract will be staked.
     */
    function setAutoStake(bool _autoStake) public onlyStaker {
        _setAutoStake(_autoStake);
        emit SetAutoStake(_autoStake);
    }

    function _setAutoStake(bool _autoStake) internal {
        autoStake = _autoStake;
    }

    /**
     * @notice The staker can manually stake `amount` of DAI into the Maker DSR
     */
    function stakeDAI(uint256 amount) external onlyStaker {
        _stakeDAI(amount);
    }

    /**
     * @notice The staker can manually stake `amount` of ETH into Lido
     */
    function stakeETH(uint256 amount) external onlyStaker {
        _stakeETH(amount);
    }

    function requestLidoWithdrawal(uint256[] calldata amount)
        external
        onlyStaker
        returns (uint256[] memory requestIds)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        LIDO.approve(address(LIDO_WITHDRAWAL_ERC721), total);
        requestIds = LIDO_WITHDRAWAL_ERC721.requestWithdrawals(amount, address(this));
        emit RequestedLidoWithdrawals(requestIds, amount);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external onlyStaker {
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        emit ClaimedLidoWithdrawals(requestIds);
    }

    /**
     * @notice Stake pooled USD funds by depositing DAI into the Maker DSR
     * @param amount Amount in DAI to stake (usd)
     */
    function _stakeDAI(uint256 amount) internal {
        if (amount > DAI.balanceOf(address(this))) {
            revert InsufficientFunds();
        }

        DAI.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit DaiStaked(amount);
    }

    /**
     * @notice Stake pooled ETH funds by submiting ETH to Lido
     * @param amount Amount in ETH to stake (wad)
     */
    function _stakeETH(uint256 amount) internal {
        if (amount > address(this).balance) {
            revert InsufficientFunds();
        }
        LIDO.submit{ value: amount }(address(0));
        emit EthStaked(amount);
    }

    /**
     * @notice Get the current ETH pool balance
     * @return Pooled ETH balance between buffered balance and deposited Lido balance
     */
    function totalETHBalance() public view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }

    /**
     * @notice Get the current USD pool balance
     * @dev Does not update DSR yield
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalanceNoUpdate() public view returns (uint256) {
        IPot pot = DSR_MANAGER.pot();
        uint256 chi = MakerMath.rmul(MakerMath.rpow(pot.dsr(), block.timestamp - pot.rho(), _RAY), pot.chi());
        return DAI.balanceOf(address(this)) + MakerMath.rmul(DSR_MANAGER.pieOf(address(this)), chi);
    }

    /**
     * @notice Get the current USD pool balance
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalance() public returns (uint256) {
        return DAI.balanceOf(address(this)) + DSR_MANAGER.daiBalance(address(this));
    }
}
