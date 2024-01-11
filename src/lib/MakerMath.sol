// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { _RAY } from "../Constants.sol";

library MakerMath {
    uint256 public constant _USD_DECIMALS = 6;
    uint256 public constant _WAD_DECIMALS = 18;
    /**
     * @dev Based on _rpow from MakerDAO pot.sol contract
     * (https://github.com/makerdao/dss/blob/fa4f6630afb0624d04a003e920b0d71a00331d98/src/pot.sol#L87-L105)
     */

    function rpow(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 { z := base }
                default { z := 0 }
            }
            default {
                switch mod(n, 2)
                case 0 { z := base }
                default { z := x }
                let half := div(base, 2) // for rounding.
                for { n := div(n, 2) } n { n := div(n, 2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0, 0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0, 0) }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0, 0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    /**
     * @dev Based on _rmul in MakerDAO pot.sol contract
     * (https://github.com/makerdao/dss/blob/fa4f6630afb0624d04a003e920b0d71a00331d98/src/pot.sol#L109-L111)
     */
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y / _RAY;
    }

    /**
     * @notice Convert from USD (6 decimals) to wad (18 decimals) denomination
     * @param usd Amount in USD
     * @return Amount in wad
     */
    function usdToWad(uint256 usd) internal pure returns (uint256) {
        return usd * (10 ** (_WAD_DECIMALS - _USD_DECIMALS));
    }
}
