# 1. Critical. EthStrategy can't claim withdrawn ETH from Lido
## Description
In function `claimLidoWithdrawals()` EthStrategy expects to receive withdrawn ETH from Lido, however it doesn't have a function to receive ETH: there is no `receive() payable` or `fallback() payable`.

As a result, ETH can't be withdrawn, and withdrawal NFT can't be transferred either.

## Recommendation
Add function `receive() payable`.
Also add end-to-end tests to ensure protocol works as expected

# 2. High. Funds withdrawn via `EthStrategy.ownerWithdraw()` will stuck in StakingManager
## Description
Owner can withdraw ETH to StakingManager.sol via this function. However funds can't be retrieved from StakingManager contract, there is no such a method.
```solidity
    function ownerWithdraw(uint256 amount) external onlyOwner returns (uint256 withdrawnAmount) {
        (bool success, bytes memory data) = stakingManager.call{ value: amount }("");
        if (!success) revert TransferFailed(data);
        emit EthWithdrawn(amount);
        return amount;
    }
```

## Recommendation
Remove function `ownerWithdraw()`. ETH balance in `EthStrategy` belongs to WrappedEth holders, not to owner.

# 3. Medium. Incorrect role management of `address staker` and `address depositor`
## Description
Addresses `staker` and `depositor` are meant to be different: `depositor` is EdgelessDeposit, staker is EOA

However functions which are called by EdgelessDeposit have `onlyStaker` modifier, hence can't be called by EdgelessDeposit:
```solidity
    function stake(address asset, uint256 amount) external payable onlyStaker {
        _stakeEth(msg.value);
        emit Stake(asset, amount);
    }

    function withdraw(uint256 amount) external onlyStaker {
        _withdrawEth(amount);
    }
```

## Recommendation
Refactor access control

# 4. Medium. `mintEthBasedOnStakedAmount()` can mint less than expected
## Description
According to Natspec:
```solidity
    /**
     * @notice Mint wrapped tokens based on the amount of Eth staked
@>   * @dev The owner can only mint up to the amount of Eth deposited + Eth staking rewards from Lido
     * @param to Address to mint wrapped tokens to
     * @param amount Amount of wrapped tokens to mint
     */
    function mintEthBasedOnStakedAmount(address to, uint256 amount) external onlyOwner {
        uint256 maxMint = stakingManager.getAssetTotal(stakingManager.ETH_ADDRESS()) - wrappedEth.totalSupply();
        if (maxMint < amount) revert MaxMintExceeded();
        wrappedEth.mint(to, amount);
        emit MintWrappedEth(to, amount);
    }
```
Let's take a look on how `underlyingAssetAmount()` is calculated. It doesn't take into consideration pending withdrawals requested via `requestLidoWithdrawal()`.
```solidity
    function underlyingAssetAmount() external view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }
```

## Recommendation
According to Lido documentation, withdrawn ETH amount can't be greater than requested stETH amount, however can be slightly less. Keep

### Response
This is fine, since we are unable to mint more ETH than we should. Minting less ETH is acceptable, as we can just wait until it is withdrawn

# 5. Low. Bridged funds can be lost if `l2Eth = address(0)`
## Description
Soon after deployment user can call `depositEth()` when all values are set except `l2Eth`. And if `autoBridge = true`, bridged funds will be lost:
```solidity
    function _bridgeToL2(WrappedToken wrappedToken, address l2WrappedToken, address to, uint256 amount) internal {
        if (autoBridge) {
            wrappedToken.approve(address(l1standardBridge), amount);
            l1standardBridge.depositERC20To(address(wrappedToken), l2WrappedToken, to, amount, 0, "");
            emit BridgeToL2(address(wrappedToken), l2WrappedToken, to, amount);
        }
    }
```

## Recommendation
Add check to ensure that values are correctly set:
```diff
    function _bridgeToL2(WrappedToken wrappedToken, address l2WrappedToken, address to, uint256 amount) internal {
        if (autoBridge) {
+           require(l2Eth != address(0));
            wrappedToken.approve(address(l1standardBridge), amount);
            l1standardBridge.depositERC20To(address(wrappedToken), l2WrappedToken, to, amount, 0, "");
            emit BridgeToL2(address(wrappedToken), l2WrappedToken, to, amount);
        }
    }
```

### Response

When l2ETH is set to zero, this means that we receive native tokens on the L2. Check this transaction hash for an example:
On Sepolia: https://sepolia.etherscan.io/tx/0x9625234c9ebab28762339b1985fc6ed191239154f77ef438bb7be062f5f13677
On Edgeless Testnet: https://edgeless-testnet.explorer.caldera.xyz/tx/0x214c582b320917839d4dcb4e278467536ef4bc461cebef245c22cf6e8b1d13cf

# 6. Low. `underlyingAssetAmount()` treats stETH is equal to ETH
## Description
Here ETH balance is mixed with stETH balance:
```solidity
    function underlyingAssetAmount() external view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }
```
However historically stETH had deviations from ETH:
https://dune.com/LidoAnalytical/Curve-ETHstETH

## Recommendation
Consider using Oracle to convert stETH into ETH

### Response
We are not using `underlyingAssetAmount()` as a price check, rather, is a total eth amount check so I think we are fine assuming that steth redeems 1:1 with eth. Obviously there is a chance of mass slashing within lido, but we can manually check that no mass slashing has happened before minting more eth.

# 7. Info. Make sure that array `requestIds` in function `claimLidoWithdrawals` is sorted
Otherwise some `requestIds` won't be processed accroding to Lido docs:
```solidity
    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`.
@>  ///  NB! Array of request ids should be sorted
    ...
    function findCheckpointHints(uint256[] calldata _requestIds, uint256 _firstIndex, uint256 _lastIndex)
```

### Response
Added Check
