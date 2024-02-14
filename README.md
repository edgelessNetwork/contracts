# Edgeless Contracts

## Getting Started

```sh
npm i
forge test
```
## Overview

### Background

- A feeless yield bearing L2 focused on iGaming and Social Gaming
- Overview
    - Traditional marketplaces charge anywhere from 1% to 30% (credit card companies, apple store)
    - Blast and Manta are focused on creating generalizable L2s where the native token is yield bearing.
    - While a yield bearing token is a step in the right direction, the yield should be used for more than just higher APYs - the ultimate vision should be to move from charging transaction fees to removing them all together.
- Use Cases
    - The first set of use cases is within social gaming. Think games that Zynga would make, such as poker, blackjack, slot machines, and Gacha games
    - For the first time ever, developers could offer EV neutral or even EV positive games. Developers would no longer need to take a house rake or fee but could monetize off of the yield (ETH or stables).
- Why Now
    - Casinos and other similar businesses cannot offer this due to lack of access to tbills(hard to get when based out of curacao) and liquidity risks. The true unlock here is that liquid staked eth/staked Dai is truly liquid and has liquidity to convert and withdraw
    - There are some interesting ways to gamify the chain, for example accumulating jackpots or lotteries that become increasingly positive EV to participate or even redistributing a portion of earnings to developers who are creating apps on the platform based on the amount of capital used in their dApp / the length in which it is used (since this directly correlates to earnings for the L2).
    - Lastly, from a market sizing perspective, we can think about capturing 4-5% of deposits which while significantly smaller than the average hold for a casino (~10% of volume), is an extremely attractive business at scale. Lido currently has about $20bn of liquid staked ETH for context, with annualized yields equally about $800m.
    - Account abstraction is mature enough for gasless experiences
    - Devs will build here since you can offer your users a gasless experience with nothing out of pocket

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
