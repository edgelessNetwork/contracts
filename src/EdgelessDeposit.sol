// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "./Constants.sol";

import { StakingManager } from "./StakingManager.sol";
import { WrappedToken } from "./WrappedToken.sol";

import { IL1StandardBridge } from "./interfaces/IL1StandardBridge.sol";

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EdgelessDeposit
 * @notice EdgelessDeposit is a contract that allows users to deposit Eth, Usdc, Usdt, or Dai and
 * receive wrapped tokens in return. The wrapped tokens can be used to bridge to the Edgeless L2
 */
contract EdgelessDeposit is Ownable2StepUpgradeable, UUPSUpgradeable {
    bool public autoBridge;
    address public l2Eth;
    address public l2USD;
    WrappedToken public wrappedEth;
    WrappedToken public wrappedUSD;
    IL1StandardBridge public l1standardBridge;
    StakingManager public stakingManager;

    event DepositEth(address indexed to, address indexed from, uint256 EthAmount, uint256 mintAmount);
    event MintWrappedEth(address indexed to, uint256 amount);
    event SetAutoBridge(bool autoBridge);
    event ReceivedStakingManagerWithdrawal(uint256 amount);
    event SetL1StandardBridge(IL1StandardBridge l1standardBridge);
    event SetL2Eth(address l2Eth);
    event WithdrawEth(address indexed from, address indexed to, uint256 EthAmountWithdrew, uint256 burnAmount);
    event BridgeToL2(address indexed from, address indexed to, address indexed l2Address, uint256 amount);

    error MaxMintExceeded();
    error TransferFailed(bytes data);
    error ZeroAddress();
    error L2EthSet();

    function initialize(
        address _owner,
        address _staker,
        IL1StandardBridge _l1standardBridge,
        StakingManager _stakingManager
    )
        external
        initializer
    {
        if (address(_l1standardBridge) == address(0) || _owner == address(0) || _staker == address(0)) {
            revert ZeroAddress();
        }

        wrappedEth = new WrappedToken(address(this), "Edgeless Wrapped Eth", "ewEth");
        l1standardBridge = _l1standardBridge;
        autoBridge = false;
        stakingManager = _stakingManager;
        __Ownable_init(_owner);
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
        _bridgeToL2(wrappedEth, l2Eth, to, amount);
        emit DepositEth(to, msg.sender, msg.value, amount);
    }

    /**
     * @notice Withdraw Eth from the Eth pool
     * @param to Address to withdraw Eth to
     * @param amount  Amount to withdraw
     */
    function withdrawEth(address to, uint256 amount) external {
        wrappedEth.burn(msg.sender, amount);
        stakingManager.withdraw(stakingManager.ETH_ADDRESS(), amount);
        (bool success, bytes memory data) = to.call{ value: amount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit WithdrawEth(msg.sender, to, amount, amount);
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    /**
     * @notice Set the address of the L1StandardBridge contract
     * @param _l1standardBridge Address of the L1StandardBridge contract
     */
    function setL1StandardBridge(IL1StandardBridge _l1standardBridge) external onlyOwner {
        if (address(_l1standardBridge) == address(0)) revert ZeroAddress();
        l1standardBridge = _l1standardBridge;
        emit SetL1StandardBridge(_l1standardBridge);
    }

    /**
     * @notice Set the address of the L2 Wrapped Eth contract
     * @param _l2Eth Address of the L2 Wrapped Eth contract
     */
    function setL2Eth(address _l2Eth) external onlyOwner {
        if (address(_l2Eth) == address(0)) revert ZeroAddress();
        if (l2Eth != address(0)) revert L2EthSet();
        l2Eth = _l2Eth;
        emit SetL2Eth(_l2Eth);
    }

    /**
     * @notice Pause autobridging of wrapped tokens to the Edgeless L2
     * @param _autoBridge True to pause autobridging, false to unpause
     */
    function setAutoBridge(bool _autoBridge) external onlyOwner {
        autoBridge = _autoBridge;
        emit SetAutoBridge(_autoBridge);
    }

    /**
     * @notice Mint wrapped tokens based on the amount of Eth staked
     * @dev The owner can only mint up to the amount of Eth deposited + Eth staking rewards from Lido
     * @param to Address to mint wrapped tokens to
     * @param amount Amount of wrapped tokens to mint
     */
    function mintEthBasedOnStakedAmount(address to, uint256 amount) external onlyOwner {
        uint256 maxMint = stakingManager.getAssetTotal(stakingManager.ETH_ADDRESS()) - wrappedEth.totalSupply();
        if (maxMint > amount) {
            revert MaxMintExceeded();
        }
        wrappedEth.mint(to, amount);
        emit MintWrappedEth(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    /// -------------------------------- 🏗️ Internal Functions 🏗️ --------------------------------
    function _bridgeToL2(WrappedToken wrappedToken, address l2WrappedToken, address to, uint256 amount) internal {
        if (autoBridge) {
            wrappedToken.approve(address(l1standardBridge), amount);
            l1standardBridge.depositERC20To(address(wrappedToken), l2WrappedToken, to, amount, 0, "");
            emit BridgeToL2(address(wrappedToken), l2WrappedToken, to, amount);
        }
    }

    /**
     * @dev If autobridge, we mint thhe wrapped token to this contract so we can transfer it from '
     * this contract to the l1standardbridge contract. Otherwise, we mint it to the user
     */
    function _mintWrappedEth(address to, uint256 amount) internal {
        if (autoBridge) {
            wrappedEth.mint(address(this), amount);
        } else {
            wrappedEth.mint(to, amount);
        }
    }
}
