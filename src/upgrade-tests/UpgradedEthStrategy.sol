// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

contract UpgradedEthStrategy is Ownable2StepUpgradeable, UUPSUpgradeable {
    address public stakingManager;
    bool public autoStake;
    uint256[50] private __gap;

    function doNothing() external { }
    receive() external payable { }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
