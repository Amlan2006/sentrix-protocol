# Sentrix Protocol Contracts

Foundry workspace for the Sentrix Protocol smart-contract core.

## Implemented Scope

This repository currently implements the approved contract foundation and per-user vault slice:

- Shared Sentrix types.
- Core MVP interfaces.
- `UserVault` initialization, deposits, idle withdrawals, risk settings, reinvestment setting, flash-loan toggle, strategy authorization, emergency pause controls, OpenZeppelin `SafeERC20`, and `ReentrancyGuard`.
- `UserVaultFactory` EIP-1167 clone deployment with OpenZeppelin `Clones` and owner-to-vault registry.
- Foundry unit tests for vault and factory behavior.

Arbitrage execution, DEX adapters, route validation, flash-loan callbacks, profit settlement, grid trading, backend services, and frontend integration are out of scope for this slice.

## Dependencies

- OpenZeppelin Contracts `v5.0.2`: used for `SafeERC20`, `ReentrancyGuard`, `Clones`, and test ERC-20 behavior.
- forge-std: used for Foundry tests.

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Format Check

```shell
forge fmt --check
```
