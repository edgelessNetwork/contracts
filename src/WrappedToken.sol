// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title WrappedToken
 * @notice This represents the wrapped tokens that are bridged to the Edgeless L2
 */
contract WrappedToken is ERC20 {
    address public minter;

    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);
    error SenderIsNotMinter();

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert SenderIsNotMinter();
        }
        _;
    }

    /**
     * @notice The owner of WrappedToken is the EdgelessDeposit contract
     * @param _minter The address of the minter - this should be the EdgelessDeposit contract
     */
    constructor(address _minter, string memory name, string memory symbol) ERC20(name, symbol) {
        minter = _minter;
    }

    /**
     * @notice Only the EdgelessDeposit contract can mint wrapped tokens
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
        emit Mint(account, amount);
    }

    /**
     * @notice Only the EdgelessDeposit contract can burn wrapped tokens
     */
    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
        emit Burn(account, amount);
    }
}
