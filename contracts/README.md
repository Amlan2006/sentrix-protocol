# Sentrix Protocol Contracts

Foundry workspace for the Sentrix Protocol smart-contract core.

## Implemented Scope

This repository currently implements the approved contract foundation and per-user vault slice:

- Shared Sentrix types.
- Core MVP interfaces.
- `UserVault` initialization, deposits, idle withdrawals, risk settings, reinvestment setting, flash-loan toggle, strategy authorization, emergency pause controls, OpenZeppelin `SafeERC20`, and `ReentrancyGuard`.
- `UserVaultFactory` EIP-1167 clone deployment with OpenZeppelin `Clones`, CREATE2 deterministic deployment, address prediction, and owner/settlement-token vault registry.
- One vault per owner and settlement token per deployed factory chain.
- Foundry unit, event, edge-case, and fuzz tests for vault and factory behavior.

Arbitrage execution, DEX adapters, route validation, flash-loan callbacks, profit settlement, grid trading, backend services, and frontend integration are out of scope for this slice.

## Dependencies

- OpenZeppelin Contracts `v5.0.2`: used for `SafeERC20`, `ReentrancyGuard`, `Clones`, and test ERC-20 behavior.
- forge-std: used for Foundry tests.

## MVP Testnet

The current target testnet is Celo Sepolia:

```text
Chain ID: 11142220
Native currency: CELO
Block gas limit: 30000000
Foundry RPC endpoint key: celo_sepolia
Environment variable: CELO_SEPOLIA_RPC_URL
```

Example command shape:

```shell
CELO_SEPOLIA_RPC_URL=<rpc-url> forge script <script> --rpc-url celo_sepolia
```

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Coverage

```shell
forge coverage
```

### Deploy Factory To Celo Sepolia

Set `CELO_SEPOLIA_RPC_URL` and `PRIVATE_KEY` in your local environment. Never commit a funded private key.

```shell
forge script script/DeployUserVaultFactory.s.sol:DeployUserVaultFactory \
  --rpc-url celo_sepolia \
  --broadcast
```

### Format

```shell
forge fmt
```

### Format Check

```shell
forge fmt --check
```
