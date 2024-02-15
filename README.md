# Edgeless Contracts

## For Auditors
Relevant Documentation/Design docs are below
Description:
- In Scope: `src/EdgelessDeposit.sol`, `src/StakingManager.sol`, `src/WrappedToken.sol`, `Constants.sol`, `src/strategies/EthStrategy.sol`
- Out of Scope: `src/edgeless/*` - forked from optimism `src/interfaces/*` - just interface
Copied Files
- `src/edgeless/*`: [IOptimismMintableERC20](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/IOptimismMintableERC20.sol/), [OptimismMintableERC20](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/OptimismMintableERC20.sol)
- `src/interfaces/*`: [IL1ERC20Bridge](https://github.com/oasysgames/l1-l2-bridge-tutorial/blob/main/contracts/L1/messaging/IL1ERC20Bridge.sol), [IWithdrawalQueueERC721](https://github.com/lidofinance/lido-dao/blob/master/contracts/0.8.9/WithdrawalQueueERC721.sol)
Rough Timeline: Start on 2/19, finish whenever?

## Getting Started

```sh
npm i --force
forge test
```
## Overview

### Background

The yield generating contracts on Ethereum for Edgeless Network.

Overview: The high level vision of Edgeless is to lower or remove the transaction fees that dApps currently charge and monetize via bridged TVL. Blast and Manta are focused on creating generalizable L2s where the native token is yield bearing and passed through to the initial user. While this is a step in the right direction the ultimate vision should be to remove transaction fees altogether, which is what we are setting out to do. Like Roblox and Epic, Edgeless is able to pool together the revenue that is generated across the ecosystem and redistribute it to app developers based on the value they bring to the ecosystem.

Use Cases: There are many use cases where charging no transaction fee naturally makes sense, social gaming is one of the most exciting, and is one of the key focuses for Edgeless to begin with (think games that Zynga would make: poker, blackjack, slot machines, and Gacha games). For the first time ever you could offer EV neutral or even EV positive games using the infrastructure that Edgeless offers. Game creators do not need to have a house rake or fee on every spin / turn since they can monetize off of the yield (ETH / stables). Other gaming related use cases include daily fantasy sports, season long survivor brackets and PvP games. Second to gaming, there are several DeFi and consumer applications that we believe would be great apps for our ecosystem including perps exchanges and NFT marketplaces.

## System Design

### Deposit Flow
<img width="1117" alt="image" src="https://github.com/edgelessNetwork/contracts/assets/156271310/74d8a869-badc-430b-93a6-dc5a85689d30">

### Withdrawal Flow

<img width="1117" alt="image" src="https://github.com/edgelessNetwork/contracts/assets/156271310/a1c214a9-17b9-4641-b374-20d92271fb58">



# Contract Design

### Contract Structure

- The contracts are organized into four distinct groups of contracts. Additionally, there is an integration with a standard bridge designed for Layer 1 (L1).

### Edgeless Managed Contracts

- **Edgeless Deposit Contract**: This contract is UUPS Upgradeable by the owner.
- **Edgeless Wrapped Ether**: An ERC20 representing ETH balance on the L2 with minting exposed to a minter (**Edgeless Deposit Contract)**.

### Staking Contracts

- **Lido Contract**: This contract is focused on managing the staking of Ethereum, a key component of the marketplace's asset management strategy.

### Deposit Flows

- **Eth**: Involves minting Wrapped Ether, optional auto-staking through Lido, and bridging the Wrapped Ether to the Edgeless Layer 2

### Withdrawal Flows

- **Lido (Eth)**: This flow allows the designated staker to request Lido to withdraw a specific balance of Eth, followed by claiming rewards after the withdrawal is finalized.

### Staking Information

- **Staker Responsibilities**: The staker is responsible for setting the AutoStake value, staking Dai and Eth in the bridge, and managing withdrawals from Lido.
- **AutoStake Feature**: This functionality allows for the automatic staking of deposits to respective platforms.
- **Owner's Role in Setting Staker**: The owner of the contract has the authority to designate the staker.

### Owner Information

- **Owner Responsibilities**: The owner is tasked with authorizing upgrades to the contract, setting the Layer 1 Bridge, designating the staker, pausing direct bridge deposits, and minting new Wrapped tokens in line with yield or staking rewards.

## Invariants

The following invariants should always be maintained within the contract:

- The balance of Wrapped Eth should always be less than or equal to the total Steth balance combined with the Eth balance.
- If autostaking is not enabled, only the designated staker has the authority to stake Eth and Dai.
- Toggling the AutoStake feature can only be done by the staker.
- Setting the staker, L1Bridge, bridgePause, authorizing upgrades, and minting tokens can only be performed by the owner of the contract.
- If the bridge is paused, users are unable to bridge to L1.
- The mint and burn functions can only be called by the Edgeless Deposit contract.

## Usage

This is a list of the most frequently needed commands.

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ npm run lint
```

### Test

Run the tests:

```sh
$ forge test
```

Generate test coverage and output result to the terminal:

```sh
$ npm run test:coverage
```

Generate test coverage with lcov report (you'll have to open the `./coverage/index.html` file in your browser, to do so
simply copy paste the path):

```sh
$ npm run test:coverage:report
```

### Deploy
There are four steps to the deployment process

For this script to work, you need to have a valid `.env` file. Copy the `.env.example` file to get started


1. Deploy contracts to the base chain, ie Ethereum or Goerli
```sh
$ npx hardhat deploy --network sepolia
```

2. Add the `l1Eth` addresses to namedAccounts in your `hardhat.config.ts`

3. Deploy the OptimismMintableTokens on the layer two, ie Edgeless
```sh
$ npx hardhat deploy --network edgelessSepoliaTestnet
```

4. Add the `l2Eth` contracts that you just deployed to `hardhat.config.ts`

5. Comment out the `func.skip` and run `002_setL2TokenAddresses.ts`
```sh
$ npx hardhat deploy --network sepolia
```
