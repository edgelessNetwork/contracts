// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { LIDO } from "../Constants.sol";
import { StakingManager } from "../StakingManager.sol";
import { WrappedToken } from "../WrappedToken.sol";
/**
 * @title EdgelessDeposit
 * @notice EdgelessDeposit is a contract that allows users to deposit Eth and
 * receive wrapped tokens in return. The wrapped tokens can be used to bridge to the Edgeless L2
 */

contract UpgradedEdgelessDeposit is Ownable2StepUpgradeable, UUPSUpgradeable {
    address public l2Eth;
    WrappedToken public wrappedEth;
    StakingManager public stakingManager;
    uint256[50] private __gap;

    function doNothing() external { }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------
    receive() external payable { }

    function _authorizeUpgrade(address) internal override onlyOwner { }

    function implementation() public view returns (address) {
        return address(this);
    }
}
