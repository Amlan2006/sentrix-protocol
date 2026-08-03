# BSC Testnet Runbook

## Required Environment

```text
BSC_TESTNET_RPC_URL=
PRIVATE_KEY=
```

## Verify Pancake Config

```shell
forge script script/bsc-testnet/SmokeTestPancakeConfig.s.sol:SmokeTestPancakeConfig --rpc-url bsc_testnet
```

## Deploy Core

```shell
forge script script/bsc-testnet/DeploySentrixCore.s.sol:DeploySentrixCore --rpc-url bsc_testnet --broadcast
```

Record the deployed `UserVaultFactory`, `RouteValidator`, `PancakeV2Adapter`, and `ArbitrageExecutor` addresses in `deployments/bsc-testnet/addresses.json`.

Each user vault owner must authorize the deployed `ArbitrageExecutor` before user-funded arbitrage can move vault idle capital.

## Deploy Mock Tokens

```shell
forge script script/bsc-testnet/DeployMockTokens.s.sol:DeployMockTokens --rpc-url bsc_testnet --broadcast
```

Record `mockUsdc` and `mockWbtc`, then export:

```text
MOCK_USDC=
MOCK_WBTC=
```

## Create Pancake Pools

```shell
forge script script/bsc-testnet/CreatePancakePools.s.sol:CreatePancakePools --rpc-url bsc_testnet --broadcast
```

Record `usdcWbnb`, `wbnbWbtc`, and `wbtcUsdc`.

## Seed Pancake Pools

The deployer needs enough mock tokens and tBNB before seeding. The script wraps missing tBNB into WBNB before adding liquidity.

Default liquidity amounts are intentionally small for testnet:

```text
USDC_WBNB_USDC_AMOUNT=20000000000
USDC_WBNB_WBNB_AMOUNT=10000000000000000000
WBNB_WBTC_WBNB_AMOUNT=10000000000000000000
WBNB_WBTC_WBTC_AMOUNT=50000000
WBTC_USDC_WBTC_AMOUNT=50000000
WBTC_USDC_USDC_AMOUNT=22000000000
```

```shell
forge script script/bsc-testnet/SeedPancakePools.s.sol:SeedPancakePools --rpc-url bsc_testnet --broadcast
```

## Configure Route Validator

```text
ROUTE_VALIDATOR=
PANCAKE_V2_ADAPTER=
MOCK_USDC=
MOCK_WBTC=
```

```shell
forge script script/bsc-testnet/ConfigureRouteValidator.s.sol:ConfigureRouteValidator --rpc-url bsc_testnet --broadcast
```

## Smoke Test User-Funded Arbitrage

```text
USER_VAULT_FACTORY=
ROUTE_VALIDATOR=
PANCAKE_V2_ADAPTER=
ARBITRAGE_EXECUTOR=
MOCK_USDC=
MOCK_WBTC=
```

Optional raw-unit overrides:

```text
SMOKE_DEPOSIT_AMOUNT=1000000000
SMOKE_BORROW_AMOUNT=100000000
SMOKE_MIN_GROSS_PROFIT=1
SMOKE_DEADLINE_SECONDS=1800
```

This script creates or reuses the deployer's USDC vault, authorizes `ArbitrageExecutor`, deposits mock USDC if needed, then executes:

```text
MOCK_USDC -> WBNB -> MOCK_WBTC -> MOCK_USDC
```

Run a dry run first:

```shell
forge script script/bsc-testnet/SmokeTestUserFundedArbitrage.s.sol:SmokeTestUserFundedArbitrage --rpc-url bsc_testnet
```

Broadcast only after the dry run succeeds:

```shell
forge script script/bsc-testnet/SmokeTestUserFundedArbitrage.s.sol:SmokeTestUserFundedArbitrage --rpc-url bsc_testnet --broadcast
```
