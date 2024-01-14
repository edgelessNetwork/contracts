// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Dai, LIDO, Usdc, Usdt, DSR_MANAGER, LIDO_WITHDRAWAL_ERC721 } from "./Constants.sol";

import { DepositManager } from "./DepositManager.sol";
import { StakingManager } from "./StakingManager.sol";
import { WrappedToken } from "./WrappedToken.sol";

import { IL1StandardBridge } from "./interfaces/IL1StandardBridge.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EdgelessDeposit
 * @notice EdgelessDeposit is a contract that allows users to deposit Eth, Usdc, Usdt, or Dai and
 * receive wrapped tokens in return. The wrapped tokens can be used to bridge to the Edgeless L2
 */
contract EdgelessDeposit is DepositManager, OwnableUpgradeable, UUPSUpgradeable {
    bool public autoBridge;
    address public l2Eth;
    address public l2USD;
    WrappedToken public wrappedEth;
    WrappedToken public wrappedUSD;
    IL1StandardBridge public l1standardBridge;
    StakingManager public stakingManager;

    event DepositDai(address indexed to, address indexed from, uint256 DaiAmount, uint256 mintAmount);
    event DepositEth(address indexed to, address indexed from, uint256 EthAmount, uint256 mintAmount);
    event DepositStEth(address indexed to, address indexed from, uint256 UsdtAmount, uint256 mintAmount);
    event DepositUsdc(address indexed to, address indexed from, uint256 UsdcAmount, uint256 mintAmount);
    event DepositUsdt(address indexed to, address indexed from, uint256 UsdtAmount, uint256 mintAmount);
    event MintWrappedEth(address indexed to, uint256 amount);
    event MintWrappedUSD(address indexed to, uint256 amount);
    event SetAutoBridge(bool autoBridge);
    event ReceivedStakingManagerWithdrawal(uint256 amount);
    event SetL1StandardBridge(IL1StandardBridge l1standardBridge);
    event SetL2Eth(address l2Eth);
    event SetL2USD(address l2USD);
    event WithdrawEth(address indexed from, address indexed to, uint256 EthAmountWithdrew, uint256 burnAmount);
    event WithdrawUSD(address indexed from, address indexed to, uint256 usdAmountWithdrew, uint256 burnAmount);

    error MaxMintExceeded();
    error TransferFailed(bytes data);
    error ZeroAddress();
    error L2EthSet();
    error L2USDSet();

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
        wrappedUSD = new WrappedToken(address(this), "Edgeless Wrapped USD", "ewUSD");
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
        uint256 amount = _depositEth(msg.value);
        _mintWrappedEth(to, amount);
        stakingManager.stake{ value: amount }(stakingManager.Eth_ADDRESS(), amount);
        _bridgeToL2(wrappedEth, l2Eth, to, amount);
        emit DepositEth(to, msg.sender, msg.value, amount);
    }

    /**
     * @notice Deposit stEth, mint wrapped tokens, and bridge to the Edgeless L2
     * @param to Address to mint wrapped tokens to
     * @param stEthAmount Amount to deposit in Dai (wad)
     */
    function depositStEth(address to, uint256 stEthAmount) public {
        uint256 mintAmount = _depositStEth(stEthAmount);
        // Don't stake stEth, just mint wrapped tokens
        _mintWrappedEth(to, mintAmount);
        IERC20(address(LIDO)).approve(address(stakingManager), stEthAmount);
        stakingManager.stake(address(LIDO), stEthAmount);
        _bridgeToL2(wrappedEth, l2Eth, to, mintAmount);
        emit DepositStEth(to, msg.sender, stEthAmount, mintAmount);
    }

    /**
     * @notice Deposit Usdc, mint wrapped tokens, and bridge to the Edgeless L2
     * @dev Usdc is converted to Dai using Maker DssPsm
     * @param to Address to mint wrapped tokens to
     * @param UsdcAmount Amount to deposit in Usdc (usd)
     */
    function depositUsdc(address to, uint256 UsdcAmount) public {
        uint256 mintAmount = _depositUsdc(UsdcAmount);
        _mintWrappedUSD(to, mintAmount);
        IERC20(address(Dai)).approve(address(stakingManager), mintAmount);
        stakingManager.stake(address(Dai), mintAmount);
        _bridgeToL2(wrappedUSD, l2USD, to, mintAmount);
        emit DepositUsdc(to, msg.sender, UsdcAmount, mintAmount);
    }

    /**
     * @notice Deposit Usdt, mint wrapped tokens, and bridge to the Edgeless L2
     * @dev Usdt is converted to Dai using Maker DssPsm
     * @param to Address to mint wrapped tokens to
     * @param UsdtAmount Amount to deposit in Usdt (usd)
     * @param minDaiAmount Minimum amount of Dai to receive from the PSM (slippage protection)
     */
    function depositUsdt(address to, uint256 UsdtAmount, uint256 minDaiAmount) public {
        uint256 mintAmount = _depositUsdt(UsdtAmount, minDaiAmount);
        _mintWrappedUSD(to, mintAmount);
        IERC20(address(Dai)).approve(address(stakingManager), mintAmount);
        stakingManager.stake(address(Dai), mintAmount);
        _bridgeToL2(wrappedUSD, l2USD, to, mintAmount);
        emit DepositUsdt(to, msg.sender, UsdtAmount, mintAmount);
    }

    /**
     * @notice Deposit Dai, mint wrapped tokens, and bridge to the Edgeless L2
     * @param to Address to mint wrapped tokens to
     * @param DaiAmount Amount to deposit in Dai (wad)
     */
    function depositDai(address to, uint256 DaiAmount) public {
        uint256 mintAmount = _depositDai(DaiAmount);
        _mintWrappedUSD(to, mintAmount);
        IERC20(address(Dai)).approve(address(stakingManager), mintAmount);
        stakingManager.stake(address(Dai), mintAmount);
        _bridgeToL2(wrappedUSD, l2USD, to, mintAmount);
        emit DepositDai(to, msg.sender, DaiAmount, mintAmount);
    }

    /**
     * @notice Deposit Usdc to the USD pool with a permit signature
     * @dev Usdc is converted to Dai using Maker DssPsm
     * @param UsdcAmount Amount to deposit in Usdc (usd)
     * @param deadline Permit signature deadline timestamp
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter
     * @param s Permit signature s parameter
     */
    function depositUsdcWithPermit(
        address to,
        uint256 UsdcAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        Usdc.permit(msg.sender, address(this), UsdcAmount, deadline, v, r, s);
        depositUsdc(to, UsdcAmount);
    }

    /**
     * @notice Deposit STEth with a permit signature
     * @dev Usdc is converted to Dai using Maker DssPsm
     * @param stEthAmount Amount to deposit in Usdc (usd)
     * @param deadline Permit signature deadline timestamp
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter
     * @param s Permit signature s parameter
     */
    function depositStEthWithPermit(
        address to,
        uint256 stEthAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        LIDO.permit(msg.sender, address(this), stEthAmount, deadline, v, r, s);
        depositStEth(to, stEthAmount);
    }

    /**
     * @notice Deposit Dai to the USD pool with a permit signature
     * @param DaiAmount Amount to deposit in Dai (wad)
     * @param nonce Permit signature nonce
     * @param expiry Permit signature expiry timestamp
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter
     * @param s Permit signature s parameter
     */
    function depositDaiWithPermit(
        address to,
        uint256 DaiAmount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        Dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        depositDai(to, DaiAmount);
    }

    /**
     * @notice Withdraw Eth from the Eth pool
     * @param to Address to withdraw Eth to
     * @param amount  Amount to withdraw
     */
    function withdrawEth(address to, uint256 amount) external {
        wrappedEth.burn(msg.sender, amount);
        stakingManager.withdraw(stakingManager.Eth_ADDRESS(), amount);
        (bool success, bytes memory data) = to.call{ value: amount }("");
        if (!success) {
            revert TransferFailed(data);
        }
        emit WithdrawEth(msg.sender, to, amount, amount);
    }

    /**
     * @notice Withdraw Dai from the stablecoin pool
     * @param to Address to withdraw Dai to
     * @param amount Amount to withdraw
     */
    function withdrawUSD(address to, uint256 amount) external {
        wrappedUSD.burn(msg.sender, amount);
        stakingManager.withdraw(address(Dai), amount);
        IERC20(address(Dai)).transfer(to, amount);
        emit WithdrawUSD(msg.sender, to, amount, amount);
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
     * @notice Set the address of the L2 Wrapped USD contract
     * @param _l2USD Address of the L2 Wrapped USD contract
     */
    function setL2USD(address _l2USD) external onlyOwner {
        if (address(_l2USD) == address(0)) revert ZeroAddress();
        if (l2USD != address(0)) revert L2USDSet();
        l2USD = _l2USD;
        emit SetL2USD(_l2USD);
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
        uint256 maxMint = stakingManager.getAssetTotal(stakingManager.Eth_ADDRESS()) - wrappedEth.totalSupply();
        if (maxMint > amount) {
            revert MaxMintExceeded();
        }
        wrappedEth.mint(to, amount);
        emit MintWrappedEth(to, amount);
    }

    /**
     * @notice Mint wrapped tokens based on the amount of USD staked
     * @dev The owner can only mint up to the amount of USD deposited + USD staking rewards from the Maker DSR
     * @param to Address to mint wrapped tokens to
     * @param amount Amount of wrapped tokens to mint
     */
    function mintUSDBasedOnStakedAmount(address to, uint256 amount) external onlyOwner {
        uint256 maxMint = stakingManager.getAssetTotal(address(Dai)) - wrappedUSD.totalSupply();
        if (maxMint > amount) {
            revert MaxMintExceeded();
        }
        wrappedUSD.mint(to, amount);
        emit MintWrappedUSD(to, amount);
    }

    /// -------------------------------- 🏗️ Internal Functions 🏗️ --------------------------------
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function _bridgeToL2(WrappedToken wrappedToken, address l2WrappedToken, address to, uint256 amount) internal {
        if (autoBridge) {
            wrappedToken.approve(address(l1standardBridge), amount);
            l1standardBridge.depositERC20To(address(wrappedToken), l2WrappedToken, to, amount, 0, "");
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

    /**
     * @dev If autobridge, we mint thhe wrapped token to this contract so we can transfer it from '
     * this contract to the l1standardbridge contract. Otherwise, we mint it to the user
     */
    function _mintWrappedUSD(address to, uint256 amount) internal {
        if (autoBridge) {
            wrappedUSD.mint(address(this), amount);
        } else {
            wrappedUSD.mint(to, amount);
        }
    }
}
