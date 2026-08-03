# Sentrix Protocol Contracts

Foundry workspace for the Sentrix Protocol smart-contract core.

## Implemented Scope

This repository currently implements the approved contract foundation and per-user vault slice:

- Shared Sentrix types.
- Core MVP interfaces.
- `UserVault` initialization, deposits, idle withdrawals, risk settings, reinvestment setting, flash-loan toggle, strategy authorization, emergency pause controls, OpenZeppelin `SafeERC20`, and `ReentrancyGuard`.
- `UserVaultFactory` EIP-1167 clone deployment with OpenZeppelin `Clones`, CREATE2 deterministic deployment, address prediction, and owner/settlement-token vault registry.
- One vault per owner and settlement token per deployed factory chain.
- Mock-first `RouteValidator` for approved adapter/token policy, two-pool route validation, and triangular route validation.
- Test-only local AMM fixtures for deterministic two-pool and triangular arbitrage scenarios.
- `PancakeV2Adapter` for BSC Testnet PancakeSwap V2 routes, pinned to the approved router/factory/WBNB addresses.
- `ArbitrageExecutor` for user-funded two-pool and triangular arbitrage through approved adapters.
- Foundry unit, event, edge-case, and fuzz tests for vault and factory behavior.

Flash-loan callbacks, fee settlement, grid trading, backend services, and frontend integration are out of scope for this slice.

## Dependencies

- OpenZeppelin Contracts `v5.0.2`: used for `SafeERC20`, `ReentrancyGuard`, `Clones`, and test ERC-20 behavior.
- forge-std: used for Foundry tests.

## MVP Testnet

The current target testnet is BSC Testnet:

```text
Chain ID: 97
Native currency: tBNB
Explorer: https://testnet.bscscan.com/
Foundry RPC endpoint key: bsc_testnet
Environment variable: BSC_TESTNET_RPC_URL
Pancake V2 Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
Pancake V2 Factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
WBNB: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
```

Example command shape:

```shell
BSC_TESTNET_RPC_URL=<rpc-url> forge script <script> --rpc-url bsc_testnet
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

### Deploy Factory To BSC Testnet

Set `BSC_TESTNET_RPC_URL` and `PRIVATE_KEY` in your local environment. Never commit a funded private key.

```shell
forge script script/DeployUserVaultFactory.s.sol:DeployUserVaultFactory \
  --rpc-url bsc_testnet \
  --broadcast
```

### BSC Testnet Pancake Flow

Verify Pancake V2 router metadata:

```shell
forge script script/bsc-testnet/SmokeTestPancakeConfig.s.sol:SmokeTestPancakeConfig \
  --rpc-url bsc_testnet
```

Deploy Sentrix core contracts:

```shell
forge script script/bsc-testnet/DeploySentrixCore.s.sol:DeploySentrixCore \
  --rpc-url bsc_testnet \
  --broadcast
```

Each vault owner must authorize the deployed `ArbitrageExecutor` with `UserVault.authorizeStrategy(arbitrageExecutor)` before user-funded arbitrage can execute from that vault.

Deploy mock route tokens:

```shell
forge script script/bsc-testnet/DeployMockTokens.s.sol:DeployMockTokens \
  --rpc-url bsc_testnet \
  --broadcast
```

Create Pancake pools after setting `MOCK_USDC` and `MOCK_WBTC`:

```shell
forge script script/bsc-testnet/CreatePancakePools.s.sol:CreatePancakePools \
  --rpc-url bsc_testnet \
  --broadcast
```

Seed Pancake pools after the deployer holds enough mock tokens and tBNB. The script wraps missing tBNB into WBNB before adding liquidity.

```shell
forge script script/bsc-testnet/SeedPancakePools.s.sol:SeedPancakePools \
  --rpc-url bsc_testnet \
  --broadcast
```

Configure route validation after setting `ROUTE_VALIDATOR`, `PANCAKE_V2_ADAPTER`, `MOCK_USDC`, and `MOCK_WBTC`:

```shell
forge script script/bsc-testnet/ConfigureRouteValidator.s.sol:ConfigureRouteValidator \
  --rpc-url bsc_testnet \
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
