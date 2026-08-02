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

Record the deployed `UserVaultFactory`, `RouteValidator`, and `PancakeV2Adapter` addresses in `deployments/bsc-testnet/addresses.json`.

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
