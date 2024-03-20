// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { LIDO } from "./Constants.sol";
import { StakingManager } from "./StakingManager.sol";
import { WrappedToken } from "./WrappedToken.sol";

/**
 * @notice EdgelessDeposit is a contract that allows users to deposit Eth and receive wrapped tokens
 */
contract EdgelessDeposit is Ownable2StepUpgradeable, UUPSUpgradeable {
    address public l2Eth;
    WrappedToken public wrappedEth;
    StakingManager public stakingManager;
    uint256[50] private __gap;

    event DepositEth(address indexed to, address indexed from, uint256 EthAmount, uint256 mintAmount);
    event MintWrappedEth(address indexed to, uint256 amount);
    event ReceivedStakingManagerWithdrawal(uint256 amount);
    event SetL2Eth(address l2Eth);
    event WithdrawEth(address indexed from, address indexed to, uint256 EthAmountWithdrew, uint256 burnAmount);

    error MaxMintExceeded();
    error TransferFailed(bytes data);
    error ZeroAddress();

    function initialize(address _owner, StakingManager _stakingManager) external initializer {
        if (_owner == address(0)) revert ZeroAddress();
        wrappedEth = new WrappedToken(address(this), "Edgeless Wrapped Eth", "ewEth");
        stakingManager = _stakingManager;
        __Ownable_init_unchained(_owner);
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    receive() external payable {
        if (msg.sender == address(stakingManager)) {
            emit ReceivedStakingManagerWithdrawal(msg.value);
        } else {
            depositEth(msg.sender);
        }
    }

    /**
     * @notice Deposit Eth, mint wrapped tokens, and bridge to the Edgeless L2
     * @param to Address to mint wrapped tokens to
     */
    function depositEth(address to) public payable {
        uint256 amount = msg.value;
        _mintWrappedEth(to, amount);
        stakingManager.stake{ value: amount }(stakingManager.ETH_ADDRESS(), amount);
        emit DepositEth(to, msg.sender, msg.value, amount);
    }

    /**
     * @notice Withdraw Eth from the Eth pool
     * @param to Address to withdraw Eth to
     * @param amount  Amount to withdraw
     */
    function withdrawEth(address to, uint256 amount) external {
        wrappedEth.burn(msg.sender, amount);
        stakingManager.withdraw(amount);
        (bool success, bytes memory data) = to.call{ value: amount }("");
        if (!success) revert TransferFailed(data);
        emit WithdrawEth(msg.sender, to, amount, amount);
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    /**
     * @notice Mint wrapped tokens based on the amount of Eth staked
     * @dev The owner can only mint up to the amount of Eth deposited + Eth staking rewards from Lido
     * @param to Address to mint wrapped tokens to
     * @param amount Amount of wrapped tokens to mint
     */
    function mintEthBasedOnStakedAmount(address to, uint256 amount) external onlyOwner {
        uint256 maxMint = stakingManager.getAssetTotal(stakingManager.ETH_ADDRESS()) - wrappedEth.totalSupply();
        if (maxMint < amount) revert MaxMintExceeded();
        wrappedEth.mint(to, amount);
        emit MintWrappedEth(to, amount);
    }

    function upgrade() external onlyOwner { }

    /// -------------------------------- 🏗️ Internal Functions 🏗️ --------------------------------
    /**
     * @dev We mint wrapped eth to the user
     */
    function _mintWrappedEth(address to, uint256 amount) internal {
        wrappedEth.mint(to, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
