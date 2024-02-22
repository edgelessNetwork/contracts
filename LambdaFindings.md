## High -  `EthStrategy`: Cannot receive ETH
The `EthStrategy` contract does not have a `receive` function and therefore cannot receive ETH when unstaking from Lido.

### Recommendation
Add a `receive` function.

### Response
Already fixed

## High - `StakingManager`: No way to recover ETH
There are two ways how ETH can end up in the `StakingManager` contract:
- Removing a strategy, which calls `strategy.withdraw`, but does not send the received ETH anywhere.
- Specifically for `EthStrategy`: Calling `ownerWithdraw`, which sends ETH directly to the staking manager.

However, the staking manager contract does not have a method to recover this ETH and it will be lost.

### Recommendation
It should be defined what happens with these funds. Depending on how centralized the flow should be, one possibility would be to let the owner withdraw it.

## Medium - ewETH may become undercollaterized because of slashing events in strategies
`EdgelessDeposit.mintEthBasedOnStakedAmount` allows to mint up to the current asset total of the strategies. However, this value may decrease in the future, making ewETH undercollaterized. More specifically for the LIDO strategy (which is the only at the moment), it can happen because of slashing events, but future strategies may have some different conditions.

### Recommendation
Completely avoiding this is not really possible in practice, but the impact could be alleviated. For instance, an insurance pool could be introduced or the losses could be distributed among all other users (unlike in the current design, where the last users will bear all the losses, incentivizing withdrawing everything as soon as this happens).

## Medium - `EdgelessDeposit`: Redemptions may use funds of other users
The function `withdrawEth` calls `StakingManager._withdrawEth`, which calls `strategy.withdraw` and sends to the deposit contract only the funds that it received. This may be lower than the funds that were requested (for the ETH strategy, this happens because the tokens are staked). In such a case, the withdrawal will typically still succeed, but use the ETH that other users deposited. Because the deposit contract is then technically undercollaterized, this may cause a bank run and the last redemptions will then fail (until an admin manually unstakes).

### Recommendation
With the current design, this is hard to avoid completely. To not have situations where the deposit contract is temporarily undercollaterized, one possibility would be to revert when the withdrawal does not result in enough funds (although it is not clear if that is better because no users could withdraw in that case).

A different design that some platforms (e.g. eBTC) use is to not integrate with LIDO directly, but to perform ETH / stETH swaps (e.g., on Uniswap). This allows immediate conversion of stETH to ETH and there is no need for owner interventions.

## Medium - `EthStrategy.claimLidoWithdrawals` time complexity
The function `LIDO_WITHDRAWAL_ERC721.findCheckpointHints` performs a binary search for every request ID and therefore has a time complexity of O(numRequests * log(numCheckpoints)). While `numRequests` is admin-controlled (and splitting IDs would be possible), `numCheckpoints` grows continuously. At some point, this may therefore run out of gas, making withdrawals impossible.

### Recommendation
There are two approaches to solve this:
- Passing in the hints (this would be more efficient anyways because it can then be calculated off-chain without any gas constraints, so the owner saves gas when claiming)
- Not hard-coding the start (currently always 1) for `findCheckpoints`, but making it configurable.

## Low - `WrappedToken`: Unnecessary events for mint / burn
The `mint` and `burn` functions both emit a dedicated event. Because they internally call `_mint` / `_burn`, which already does emit a special `Transfer` event in these scenarios, these events are unnecessary and could be removed to save gas.

### Recommendation
Consider removing the events.

## Low - Unused parameters
There are a few parameters that are not used and can be removed:
- `EdgelessDeposit.initialize`: The `_staker` argument is not used (except for checking that it is non-zero). I recommend removing it.
- `StakingManager.stake`: The function has an argument `asset`, but only supports staking ETH (at the moment). The argument is ignored except for the event. While this interface may have been chosen to be able to add new assets in the future, the current implementation is pretty confusing because it would technically support passing in an arbitrary asset that is then also emitted in the event. In practice, this can never happen with the current deposit contract (that is only allowed to call this function) because it only passes in the ETH address, but if the idea is to support more assets in the future, you might want to consider already adding validation for this (i.e. reverting for non-supported assets). Moreover, the interface is not consistent because `withdraw` does not have an `asset` parameter, so if the reason for this argument was to have a future-proof interface, this is not the case because `withdraw` needs to be changed anyways.
