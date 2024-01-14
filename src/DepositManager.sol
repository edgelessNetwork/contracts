// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Dai, LIDO, USDC, Usdt, _RAY, CURVE_3POOL, PSM } from "./Constants.sol";
import { WrappedToken } from "./WrappedToken.sol";

import { MakerMath } from "./lib/MakerMath.sol";

/**
 * @title DepositManager
 * @notice DepositManager is a library of functions that take in an amount of ETH, USDC, Usdt, or
 * Dai and calculates how much of the corresponding wrapped token to mint.
 */
contract DepositManager {
    uint256 public constant _BASIS_POINTS = 10_000;
    address public constant _INITIAL_TOKEN_HOLDER = 0x000000000000000000000000000000000000dEaD;

    int128 public constant _CURVE_Dai_INDEX = 0;
    int128 public constant _CURVE_Usdt_INDEX = 2;
    uint256 public constant _INITIAL_DEPOSIT_AMOUNT = 1000;
    uint256 public constant _WAD = 10 ** 18;

    error ZeroDeposit();
    error InsufficientBalance();

    /**
     * @notice Deposit Eth to the ETH pool
     * @dev Amount is msg.value
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositEth(uint256 amount) internal pure returns (uint256 mintAmount) {
        if (amount == 0) {
            revert ZeroDeposit();
        }
        return amount;
    }

    /**
     * @notice Swaps USDC for Dai
     * @dev USDC is converted to Dai using Maker PSM
     * @param usdcAmount Amount of USDC deposited for swapping
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositUSDC(uint256 usdcAmount) internal returns (uint256 mintAmount) {
        if (usdcAmount == 0) {
            revert ZeroDeposit();
        }
        uint256 wadAmount = MakerMath.usdToWad(usdcAmount);
        uint256 conversionFee = PSM.tin() * wadAmount / _WAD;
        mintAmount = wadAmount - conversionFee;

        USDC.transferFrom(msg.sender, address(this), usdcAmount);

        /* Convert USDC to Dai through MakerDAO Peg Stability Mechanism. */
        USDC.approve(PSM.gemJoin(), usdcAmount);
        PSM.sellGem(address(this), usdcAmount);
    }

    /**
     * @notice Swaps Usdt for Dai
     * @dev Usdt is converted to Dai using Curve 3Pool
     * @param UsdtAmount Amount of Usdt deposited for swapping
     * @param minDaiAmount Minimum Dai amount to accept when exchanging through Curve (wad)
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositUsdt(uint256 UsdtAmount, uint256 minDaiAmount) internal returns (uint256 mintAmount) {
        if (UsdtAmount == 0) {
            revert ZeroDeposit();
        }

        uint256 UsdtBalance = Usdt.balanceOf(address(this));
        Usdt.transferFrom(msg.sender, address(this), UsdtAmount);
        uint256 receivedUsdt = Usdt.balanceOf(address(this)) - UsdtBalance;

        /* Exchange Usdt to Dai through the Curve 3Pool. */
        uint256 DaiBalance = Dai.balanceOf(address(this));
        Usdt.approve(address(CURVE_3POOL), receivedUsdt);
        CURVE_3POOL.exchange(_CURVE_Usdt_INDEX, _CURVE_Dai_INDEX, receivedUsdt, minDaiAmount);

        /* The amount of Dai received in the exchange is uncertain due to slippage, so we must record the deposit after
        the exchange. */
        mintAmount = Dai.balanceOf(address(this)) - DaiBalance;
    }

    /**
     * @notice Transfer Dai from the depositor to this contract
     * @param DaiAmount Amount to deposit in Dai (wad)
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositDai(uint256 DaiAmount) internal returns (uint256 mintAmount) {
        if (DaiAmount == 0) {
            revert ZeroDeposit();
        }
        Dai.transferFrom(msg.sender, address(this), DaiAmount);
        return DaiAmount;
    }

    /**
     * @notice Transfer StEth from the depositor to this contract
     * @param stEthAmount Amount to deposit in StEth
     * @return mintAmount Amount of wrapped tokens to mint
     */
    function _depositStEth(uint256 stEthAmount) internal returns (uint256 mintAmount) {
        if (stEthAmount == 0) {
            revert ZeroDeposit();
        }
        LIDO.transferFrom(msg.sender, address(this), stEthAmount);
        return stEthAmount;
    }
}
