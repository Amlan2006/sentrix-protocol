# EVM Arbitrage and Automated Investment Platform — Development Plan

## 1. Project Overview

Build a non-custodial, same-chain EVM trading platform that deploys an isolated vault for each user.

The system will:

1. Detect profitable same-chain arbitrage opportunities.
2. Execute two-pool and triangular arbitrage.
3. Use flash loans as temporary execution capital only when the vault owner explicitly enables flash-loan arbitrage.
4. Settle flash-loan principal, flash-loan fees, gas reimbursement, executor fees, and protocol fees.
5. Credit the remaining net profit to the correct user vault.
6. Reinvest a user-defined percentage of net profit.
7. Allocate reinvested funds to approved high-performing assets.
8. Manage those assets through configurable grid-trading strategies.
9. Track deposits, balances, positions, realized profit, and unrealized profit.
10. Allow users to withdraw idle funds and exit active strategies.

The MVP is limited to one EVM chain. Cross-chain arbitrage, bridge integrations, and cross-chain accounting are explicitly excluded.

---

## 2. Core Product Principles

### 2.1 User isolation

Every user must have a separate vault contract or minimal-proxy vault instance.

Funds and accounting belonging to one user must never be mixed with another user's funds.

### 2.2 Non-custodial withdrawals

Only the vault owner may withdraw user-owned assets, except where the user has explicitly authorized a strategy operation.

Administrators, keepers, searchers, and executors must not have unrestricted withdrawal permissions.

### 2.3 Atomic arbitrage

Every arbitrage transaction must:

- Start with an approved settlement token.
- End with the same settlement token.
- Repay flash-loan principal and fees when applicable.
- Satisfy the configured minimum-profit requirement.
- Revert completely when repayment or profitability requirements are not met.

### 2.4 Explicit accounting separation

The system must separately track:

- User principal.
- Idle vault balance.
- Arbitrage working capital.
- Gross arbitrage profit.
- Flash-loan principal.
- Flash-loan fee.
- Gas reimbursement.
- Executor fee.
- Protocol fee.
- Net realized profit.
- Reinvestment allocation.
- Withdrawable profit.
- Active grid capital.
- Realized grid profit.
- Unrealized grid profit.

### 2.5 Restricted execution

Off-chain services may identify opportunities and request trades, but on-chain contracts must validate every route, token, adapter, deadline, slippage limit, and profit threshold.

The system must not allow arbitrary calls supplied by a keeper or searcher.

### 2.6 User-controlled flash-loan mode

Flash-loan arbitrage is an optional execution mode controlled by each vault owner.

Requirements:

- It must be disabled by default when a vault is created.
- Only the vault owner may enable or disable it.
- Enabling standard arbitrage must not automatically enable flash-loan arbitrage.
- When disabled, the executor and flash-loan receiver must reject every flash-loan request associated with that vault.
- The setting must apply independently to two-pool and triangular routes that use flash-loan capital.
- Disabling it must not disable user-funded arbitrage unless the user separately disables arbitrage entirely.
- Every setting change must emit an event.
- The frontend must display whether an execution used user funds or a flash loan.

Suggested state:

```solidity
bool public flashLoanArbitrageEnabled;
```

Suggested event:

```solidity
event FlashLoanArbitrageSettingUpdated(
    address indexed vault,
    bool enabled
);
```

---

## 3. MVP Scope

### Included

- One EVM chain.
- One settlement token, preferably USDC.
- Per-user vault deployment using EIP-1167 clones.
- User deposits and withdrawals.
- Two-pool arbitrage.
- Triangular arbitrage.
- User-funded arbitrage.
- Optional flash-loan-funded arbitrage, controlled independently by each user and disabled by default.
- Atomic profit validation.
- Gas-cost estimation and capped reimbursement.
- Protocol and executor fee settlement.
- User-defined profit reinvestment percentage.
- Approved investment-token universe.
- Asset-ranking service.
- Single-asset and multi-asset grid configurations.
- Position and profit tracking.
- Off-chain opportunity detector.
- Off-chain keeper/executor service.
- Emergency pause and user emergency exit.
- Testnet deployment.
- Limited mainnet beta.

### Excluded

- Cross-chain arbitrage.
- Bridge integrations.
- Cross-chain vault balances.
- Arbitrary user-selected tokens.
- Permissionless adapters.
- Fully decentralized keeper networks.
- Leveraged grid trading.
- Lending or collateralized borrowing.
- Derivatives.
- Guaranteed returns.
- Socialized losses.
- Automatic upgrading without timelock.
- Governance token.
- DAO governance.

---

## 4. Target Architecture

```text
Frontend
   |
   +-- User dashboard
   +-- Vault configuration
   +-- Arbitrage settings
   +-- Reinvestment settings
   +-- Grid configuration
   +-- Portfolio and PnL view
   +-- Withdrawal and emergency exit
   |
Backend / Off-chain Services
   |
   +-- Pool indexer
   +-- Opportunity detector
   +-- Route simulator
   +-- Gas estimator
   +-- Flash-loan quote service
   +-- Asset-ranking service
   +-- Grid keeper
   +-- Transaction submitter
   +-- Event indexer
   +-- Monitoring and alerting
   |
Smart Contracts
   |
   +-- SmartAccountFactory and session-key validator
   +-- UserVaultFactory
   +-- UserVault clones
   +-- ArbitrageExecutor
   +-- FlashLoanReceiver
   +-- RouteValidator
   +-- ProfitSettlementManager
   +-- GridTradingStrategy
   +-- PortfolioAllocator
   +-- OracleManager
   +-- KeeperRegistry
   +-- DEX adapters
```

---

## 5. Suggested Repository Structure

```text
project-root/
├── contracts/
│   ├── factory/
│   │   └── UserVaultFactory.sol
│   ├── vault/
│   │   ├── UserVault.sol
│   │   ├── UserVaultStorage.sol
│   │   └── UserVaultTypes.sol
│   ├── arbitrage/
│   │   ├── ArbitrageExecutor.sol
│   │   ├── FlashLoanReceiver.sol
│   │   ├── TwoPoolArbitrageStrategy.sol
│   │   └── TriangularArbitrageStrategy.sol
│   ├── settlement/
│   │   └── ProfitSettlementManager.sol
│   ├── strategies/
│   │   ├── GridTradingStrategy.sol
│   │   └── PortfolioAllocator.sol
│   ├── adapters/
│   │   ├── IDexAdapter.sol
│   │   ├── UniswapV2Adapter.sol
│   │   └── UniswapV3Adapter.sol
│   ├── oracle/
│   │   └── OracleManager.sol
│   ├── execution/
│   │   ├── KeeperRegistry.sol
│   │   └── RouteValidator.sol
│   ├── account/
│   │   ├── SmartAccountFactory.sol
│   │   ├── SessionKeyValidator.sol
│   │   ├── PaymasterPolicy.sol
│   │   └── RecoveryModule.sol
│   ├── security/
│   │   ├── EmergencyController.sol
│   │   └── RiskManager.sol
│   ├── interfaces/
│   └── libraries/
│       ├── ArbitrageMath.sol
│       ├── ProfitMath.sol
│       ├── GridMath.sol
│       └── RiskValidation.sol
├── services/
│   ├── indexer/
│   ├── opportunity-detector/
│   ├── simulator/
│   ├── executor/
│   ├── grid-keeper/
│   ├── asset-ranking/
│   └── monitoring/
├── apps/
│   ├── web/
│   └── admin/
├── packages/
│   ├── sdk/
│   ├── config/
│   ├── database/
│   └── shared-types/
├── test/
│   ├── unit/
│   ├── integration/
│   ├── invariant/
│   ├── fork/
│   └── e2e/
├── deployments/
├── scripts/
├── docs/
├── .env.example
├── README.md
└── plan.md
```

---


# Smart-Contract-First Development Rule

The smart-contract core must be completed before full backend, frontend, strategy marketplace, or smart-account development begins.

A minimal off-chain simulator may be developed alongside the contracts only for:

- Fork testing.
- Route simulation.
- Gas estimation.
- Profitability validation.
- Flash-loan integration testing.
- Contract event inspection.

The simulator is supporting infrastructure and must not become the production backend before the contract interfaces, accounting model, events, permissions, and invariants are stable.

## Smart-Contract Core Scope

The following components form the mandatory smart-contract core:

1. `UserVaultFactory`
2. Per-user `UserVault`
3. Deposit and withdrawal logic
4. Access control and emergency controls
5. Explicit accounting buckets
6. DEX adapters
7. Route validation
8. User-funded two-pool arbitrage
9. Triangular arbitrage
10. Optional flash-loan arbitrage
11. Profit, gas, executor-fee, and protocol-fee settlement
12. Reinvestment allocation
13. Portfolio allocation validation
14. Grid-trading strategy
15. Oracle validation
16. Keeper permission restrictions
17. Smart-contract events required by the indexer
18. Upgradeability, multisig, and timelock controls

## Smart-Contract Core Completion Gate

The smart-contract core is considered finished only when:

- [ ] A user can deploy an isolated vault.
- [ ] A user can deposit the approved settlement token.
- [ ] Only the vault owner can withdraw unrestricted funds.
- [ ] Admins, keepers, and executors cannot withdraw user funds.
- [ ] User-funded two-pool arbitrage works atomically.
- [ ] Triangular arbitrage works atomically.
- [ ] Flash-loan arbitrage is disabled by default.
- [ ] Only the vault owner can enable or disable flash-loan arbitrage.
- [ ] Flash-loan principal and premium are repaid atomically.
- [ ] Failed arbitrage cannot reduce user principal.
- [ ] Route validation prevents arbitrary external calls.
- [ ] Gas reimbursement is capped.
- [ ] Flash-loan fees, gas reimbursement, executor fees, and protocol fees are charged exactly once.
- [ ] Net realized profit is calculated correctly.
- [ ] Reinvestment and withdrawable allocations sum exactly to net realized profit.
- [ ] Grid strategies cannot spend more than authorized reinvestment capital.
- [ ] Users can pause and exit grid strategies.
- [ ] Emergency pause does not prevent permitted owner withdrawals.
- [ ] All critical accounting, vault, arbitrage, settlement, and grid invariants pass.
- [ ] Unit, integration, fork, fuzz, and stateful invariant tests pass.
- [ ] Core accounting contracts have at least 95% line and branch coverage.
- [ ] Other core contracts have at least 90% line coverage.
- [ ] Static analysis has no unresolved critical or high-severity finding.
- [ ] Contract interfaces and events are frozen for the first backend integration version.
- [ ] Testnet deployment scripts reproduce the same deployment successfully.
- [ ] An internal security review is completed.

Until this gate is passed:

- Production backend development must not begin.
- Full frontend integration must not begin.
- The governed strategy marketplace must not begin.
- Smart-account and session-key integration must not begin.
- Mainnet deployment preparation must not begin.

External audit preparation may begin while the smart-contract core is being finalized, but unrestricted mainnet deployment requires the completed external audit defined later in this plan.

---

# Phase 0 — Product Definition and Threat Model

## Objective

Convert the product idea into precise technical, financial, and security requirements before implementation begins.

## Work Items

### Product decisions

- Select the MVP chain.
- Select the settlement token.
- Select initial DEX integrations.
- Select the flash-loan provider.
- Decide whether user-funded arbitrage is enabled in the MVP.
- Define protocol fee.
- Define executor fee.
- Define gas reimbursement rules.
- Define minimum user deposit.
- Define minimum net-profit requirement.
- Define maximum trade size.
- Define supported investment assets.
- Define how "top-performing assets" are ranked.
- Define grid-trading parameters.
- Define immediate withdrawal and full-exit behavior.
- Define upgradeability model.
- Define administrative roles and multisig requirements.

### Threat model

Document threats involving:

- Malicious keeper.
- Malicious route submitter.
- Malicious DEX adapter.
- Malicious or non-standard ERC-20 token.
- Flash-loan callback spoofing.
- Oracle manipulation.
- Sandwich attacks.
- Front-running.
- Back-running competition.
- Reentrancy.
- Approval misuse.
- Fee-on-transfer tokens.
- Rebasing tokens.
- Slippage.
- Stale price data.
- Gas-price manipulation.
- Excessive gas reimbursement.
- Vault insolvency.
- Accounting duplication.
- Unauthorized upgrades.
- Emergency-pause abuse.
- Denial of service.
- Database/indexer inconsistency.
- Private-key compromise.

### Required documents

- Product Requirements Document.
- System architecture document.
- Threat model.
- Accounting specification.
- Permission matrix.
- State-transition diagrams.
- MVP scope and exclusion list.

## Phase Completion Requirements

Phase 0 is finished only when:

- [ ] The MVP chain is selected.
- [ ] The settlement token is selected.
- [ ] At least two DEX integrations are selected.
- [ ] A flash-loan provider is selected and verified to support the target chain and asset.
- [ ] All fee formulas are written with worked examples.
- [ ] Gas reimbursement rules and caps are defined.
- [ ] The exact definition of net profit is approved.
- [ ] The user withdrawal model is approved.
- [ ] The asset-ranking formula is documented.
- [ ] Grid behavior is documented for rising, falling, and range-bound markets.
- [ ] Administrative roles and permissions are documented.
- [ ] The threat model covers every externally callable component.
- [ ] MVP inclusions and exclusions are frozen.
- [ ] No unresolved product decision blocks contract interface design.

---

# Phase 1 — Development Environment and Core Interfaces

## Objective

Create the repository, development standards, interfaces, shared types, CI pipeline, and testing foundation.

## Work Items

### Repository setup

- Initialize monorepo.
- Configure Solidity project using Foundry.
- Add Hardhat only if required for deployment tooling or TypeScript integrations.
- Configure formatter and linter.
- Configure Solidity static analysis.
- Configure TypeScript strict mode.
- Configure environment validation.
- Configure commit hooks.
- Configure CI.

### Solidity interfaces

Define:

- `IUserVault`
- `IUserVaultFactory`
- `IArbitrageExecutor`
- `IFlashLoanReceiver`
- `IDexAdapter`
- `IRouteValidator`
- `IProfitSettlementManager`
- `IGridTradingStrategy`
- `IPortfolioAllocator`
- `IOracleManager`
- `IKeeperRegistry`

### Shared data structures

Define:

```solidity
enum ArbitrageType {
    TWO_POOL,
    TRIANGULAR
}

struct SwapStep {
    address adapter;
    address tokenIn;
    address tokenOut;
    uint256 minAmountOut;
    bytes routeData;
}

struct ArbitrageRequest {
    address vault;
    address settlementToken;
    uint256 borrowAmount;
    uint256 minGrossProfit;
    uint256 maxGasReimbursement;
    uint256 deadline;
    ArbitrageType arbitrageType;
    SwapStep[] swaps;
}

struct UserRiskConfig {
    uint256 minNetProfit;
    uint256 maxTradeSize;
    uint256 maxGasReimbursement;
    uint16 maxSlippageBps;
    uint16 reinvestmentBps;
    bool arbitrageEnabled;
    bool flashLoanArbitrageEnabled;
    bool gridEnabled;
}
```

### CI checks

Every pull request must run:

- Compilation.
- Unit tests.
- Formatting checks.
- Linting.
- Static analysis.
- Contract-size checks.
- Coverage generation.
- Type checking.
- Dependency vulnerability scan.

## Phase Completion Requirements

Phase 1 is finished only when:

- [ ] The repository structure is committed.
- [ ] Contracts compile without warnings that affect correctness.
- [ ] TypeScript compiles in strict mode.
- [ ] All core interfaces are documented.
- [ ] Shared structs and enums are finalized.
- [ ] CI runs automatically on every pull request.
- [ ] CI blocks merges on failed tests or failed analysis.
- [ ] A deployment configuration exists for local, testnet, and mainnet environments.
- [ ] `.env.example` documents every required variable.
- [ ] No private key or secret is committed.
- [ ] A basic local test deployment completes successfully.

---

# Phase 2 — Per-User Vault and Factory

## Objective

Implement isolated user vaults with secure deposits, withdrawals, role restrictions, and explicit accounting.

## Work Items

### UserVaultFactory

Implement:

- EIP-1167 minimal-proxy deployment.
- Deterministic deployment option using CREATE2.
- One or multiple vaults per user, based on final product decision.
- Vault registration.
- Implementation-version tracking.
- Initialization validation.
- Events for vault creation.

### UserVault

Implement:

- Vault owner.
- Settlement token.
- Deposits.
- Idle-balance withdrawals.
- Approved strategy modules.
- Approved executor.
- Risk configuration.
- Reinvestment configuration.
- Independent flash-loan arbitrage enable/disable configuration, disabled by default.
- Internal accounting buckets.
- Emergency pause.
- Emergency user withdrawal.
- Strategy asset receipts.
- Protection against repeated initialization.
- Reentrancy protection.
- Safe token transfer handling.

### Accounting fields

At minimum track:

```text
principalDeposited
principalWithdrawn
idleSettlementBalance
grossArbitrageProfit
flashLoanFeesPaid
gasReimbursementsPaid
protocolFeesPaid
executorFeesPaid
netArbitrageProfit
withdrawableProfit
reinvestmentCapital
activeGridCapital
realizedGridProfit
```

### Events

Include:

- `VaultCreated`
- `Deposited`
- `Withdrawn`
- `RiskConfigUpdated`
- `ReinvestmentConfigUpdated`
- `FlashLoanArbitrageSettingUpdated`
- `StrategyAuthorized`
- `StrategyRevoked`
- `EmergencyPaused`
- `EmergencyUnpaused`
- `EmergencyWithdrawal`

## Testing Requirements

- Initialization tests.
- Factory clone tests.
- CREATE2 address tests.
- Deposit tests.
- Partial withdrawal tests.
- Full withdrawal tests.
- Unauthorized withdrawal tests.
- Flash-loan setting authorization and default-state tests.
- Reentrancy tests.
- Duplicate initialization tests.
- Accounting tests.
- Paused-state tests.
- Non-standard ERC-20 handling tests.
- Fuzz tests for deposit and withdrawal sequences.
- Invariant: recorded user assets must never exceed actual vault-controlled assets.

## Phase Completion Requirements

Phase 2 is finished only when:

- [ ] A user can deploy a vault through the factory.
- [ ] Vault addresses are correctly mapped to users.
- [ ] A user can deposit the approved settlement token.
- [ ] Only the vault owner can withdraw user funds.
- [ ] Administrators cannot directly withdraw user assets.
- [ ] Strategies cannot transfer assets to arbitrary recipients.
- [ ] Accounting buckets update correctly after every deposit and withdrawal.
- [ ] Flash-loan arbitrage is disabled by default and can only be changed by the vault owner.
- [ ] Disabling flash-loan arbitrage does not disable permitted user-funded arbitrage.
- [ ] Emergency pause blocks strategy execution.
- [ ] Emergency withdrawal behavior matches the approved specification.
- [ ] Reentrancy tests pass.
- [ ] Fuzz tests pass.
- [ ] Vault-accounting invariants pass.
- [ ] Unit-test coverage for vault and factory code is at least 90%.
- [ ] Static analysis reports no unresolved high-severity issue.
- [ ] A testnet vault can be deployed, funded, and withdrawn from.

---

# Phase 3 — DEX Adapter and Route Validation Layer

## Objective

Create a restricted, reusable swap layer that supports approved DEX protocols without allowing arbitrary external calls.

## Work Items

### DEX adapter interface

Each adapter must expose a consistent swap API.

```solidity
interface IDexAdapter {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes calldata routeData
    ) external returns (uint256 amountOut);
}
```

### Initial adapters

Implement at least:

- One Uniswap V2-compatible adapter.
- One Uniswap V3-compatible adapter or a second liquid DEX adapter.

### RouteValidator

Validate:

- Approved adapter.
- Approved token.
- Approved router.
- Route starts with settlement token.
- Route ends with settlement token.
- Token continuity between swap steps.
- Exactly two steps for two-pool arbitrage.
- Exactly three steps for triangular arbitrage.
- No zero addresses.
- No repeated invalid token transitions.
- Deadline not expired.
- Minimum-output values are non-zero where required.
- Trade size does not exceed user limit.
- Requested slippage does not exceed user limit.
- Route data cannot change the recipient to an arbitrary address.

### Token policy

Initially reject or explicitly exclude:

- Fee-on-transfer tokens.
- Rebasing tokens.
- ERC-777-style callback tokens.
- Blacklistable tokens unless reviewed.
- Tokens with transfer restrictions.
- Tokens with unusual decimals unless explicitly supported.
- Tokens without sufficient liquidity.

## Testing Requirements

- Adapter unit tests.
- Fork tests against real pools.
- Invalid-route tests.
- Unauthorized-adapter tests.
- Token-continuity tests.
- Deadline tests.
- Min-output tests.
- Slippage-limit tests.
- Recipient-manipulation tests.
- Malicious-adapter mock tests.
- False return-value token tests.

## Phase Completion Requirements

Phase 3 is finished only when:

- [ ] Two DEX adapter implementations are complete.
- [ ] Every adapter sends output only to the authorized execution context.
- [ ] Arbitrary call targets cannot be supplied through route data.
- [ ] Route validation rejects malformed two-pool routes.
- [ ] Route validation rejects malformed triangular routes.
- [ ] Only approved tokens and routers can be used.
- [ ] Fork tests execute real swaps successfully.
- [ ] Minimum-output protection is enforced.
- [ ] Expired routes are rejected.
- [ ] Malicious adapter and malicious route tests pass.
- [ ] No adapter retains unexpected token balances after execution.
- [ ] Adapter and validator unit-test coverage is at least 90%.
- [ ] Static analysis reports no unresolved high-severity issue.

---

# Phase 4 — User-Funded Two-Pool Arbitrage

## Objective

Implement the simplest atomic arbitrage path using vault-provided capital before adding flash loans.

## Work Items

### ArbitrageExecutor

Implement:

- Authorized keeper entry point.
- Request validation.
- Capital request from vault.
- Two-step swap execution.
- Initial and final balance snapshots.
- Gross-profit calculation.
- Minimum-profit enforcement.
- Profit return to vault.
- Atomic revert on loss.
- Replay protection.
- Request deadline.
- Request nonce or unique execution identifier.

### Profit rule

```text
grossProfit =
finalSettlementBalance
- startingSettlementBalance
```

The transaction must revert when:

```text
grossProfit < requiredGrossProfit
```

### Off-chain simulation script

Implement a local script that:

- Reads pool state.
- Builds a two-pool route.
- Estimates output.
- Estimates gas.
- Calculates expected gross and net profit.
- Submits only when thresholds are satisfied.

## Testing Requirements

- Profitable two-pool route.
- Unprofitable route.
- Exact break-even route.
- Slippage-induced loss.
- Unauthorized caller.
- Expired request.
- Duplicate request.
- Incorrect starting token.
- Incorrect ending token.
- Profit credited to wrong vault attempt.
- Fork test using real DEX liquidity.
- Invariant: failed arbitrage cannot reduce vault principal.

## Phase Completion Requirements

Phase 4 is finished only when:

- [ ] A keeper can execute a valid two-pool arbitrage.
- [ ] An unprofitable transaction reverts atomically.
- [ ] Vault principal cannot be reduced by a completed arbitrage.
- [ ] Profit is credited only to the originating vault.
- [ ] Requests cannot be replayed.
- [ ] Unauthorized callers are rejected.
- [ ] Fork tests demonstrate at least one successful simulated arbitrage route.
- [ ] Gas usage is measured and documented.
- [ ] All arbitrage events contain sufficient data for off-chain accounting.
- [ ] The accounting invariant holds across fuzzed execution sequences.
- [ ] Unit-test coverage for the executor is at least 90%.
- [ ] No unresolved high-severity static-analysis finding remains.

---

# Phase 5 — Triangular Arbitrage

## Objective

Add three-swap atomic arbitrage using the same-chain route:

```text
Settlement Token -> Token B -> Token C -> Settlement Token
```

## Work Items

Implement:

- Three-step route validation.
- Token continuity.
- Three-pool quote simulation.
- Fee-aware output calculations.
- Per-hop minimum outputs.
- Final minimum-profit enforcement.
- Support for pools on one DEX or multiple approved DEXs.
- Route-specific gas estimation.
- Triangular opportunity indexing.

### Example route

```text
USDC -> WETH -> WBTC -> USDC
```

### Required validation

```text
swap[0].tokenIn  == settlementToken
swap[0].tokenOut == swap[1].tokenIn
swap[1].tokenOut == swap[2].tokenIn
swap[2].tokenOut == settlementToken
swaps.length      == 3
```

## Testing Requirements

- Profitable triangular route.
- Unprofitable triangular route.
- Broken token continuity.
- Wrong final token.
- More than three swaps.
- Fewer than three swaps.
- Mixed-adapter route.
- Per-hop slippage failure.
- Final-profit failure.
- Fork tests.
- Fuzz tests over route amounts.
- Invariant: triangular execution cannot consume unrelated vault tokens.

## Phase Completion Requirements

Phase 5 is finished only when:

- [ ] Exactly three swaps are enforced.
- [ ] All token transitions are validated.
- [ ] Routes may use multiple approved DEX adapters.
- [ ] Per-hop slippage limits are enforced.
- [ ] Final profit is measured in the original settlement token.
- [ ] Unprofitable routes revert atomically.
- [ ] Fork tests demonstrate complete triangular execution.
- [ ] Opportunity simulation and on-chain execution produce acceptably close outputs within documented tolerances.
- [ ] Gas costs are measured and included in profitability simulation.
- [ ] Fuzz and invariant tests pass.
- [ ] Unit-test coverage for triangular logic is at least 90%.

---

# Phase 6 — Flash-Loan Integration

## Objective

Add flash loans as an optional funding mechanism for two-pool and triangular arbitrage.

## Work Items

### FlashLoanReceiver

Implement:

- Approved provider registry.
- Per-vault flash-loan arbitrage enable/disable setting.
- Flash-loan request initiation only when the vault owner has enabled it.
- Authenticated callback.
- Asset validation.
- Amount validation.
- Initiator validation.
- Callback-data validation.
- Two-pool and triangular execution.
- Principal repayment.
- Premium repayment.
- Final-profit validation.
- Residual-profit forwarding to the correct vault.

### Flash-loan settlement formula

```text
grossArbitrageSurplus =
finalSettlementBalance
- borrowedPrincipal
- flashLoanPremium
```

The callback must revert unless:

```text
finalSettlementBalance >=
borrowedPrincipal
+ flashLoanPremium
+ minimumGrossProfit
```

### Security rules

- Callback caller must equal the approved provider.
- Callback initiator must equal the system receiver.
- Borrowed asset must equal the authorized settlement token.
- Borrowed amount must match the signed or stored request.
- The originating vault must have `flashLoanArbitrageEnabled == true`.
- Request must be unused and unexpired.
- Route must already be validated.
- Repayment approval must be exact or reset after use.
- The flash-loan receiver must not retain unrelated balances.

## Testing Requirements

- Successful two-pool flash-loan arbitrage.
- Successful triangular flash-loan arbitrage.
- Insufficient repayment.
- Insufficient profit.
- Spoofed callback.
- Wrong initiator.
- Wrong asset.
- Wrong amount.
- Replayed callback data.
- Provider fee change.
- Malicious provider mock.
- Fork test against the selected provider.
- Invariant: the protocol cannot retain unpaid flash-loan debt after a successful transaction.

## Phase Completion Requirements

Phase 6 is finished only when:

- [ ] Both two-pool and triangular arbitrage can use flash-loan funding when enabled by the vault owner.
- [ ] Flash-loan execution is rejected when the user's flash-loan setting is disabled.
- [ ] The setting is disabled by default for newly deployed vaults.
- [ ] Only the vault owner can change the flash-loan setting.
- [ ] Flash-loan callbacks are authenticated.
- [ ] Principal and premium are repaid atomically.
- [ ] Failure to repay reverts the entire transaction.
- [ ] Residual profit is credited to the correct user vault.
- [ ] No user vault can be charged for another user's flash loan.
- [ ] Replayed requests are rejected.
- [ ] Provider fork tests pass.
- [ ] Flash-loan fee is included in off-chain profitability calculations.
- [ ] Gas usage is measured and documented.
- [ ] Unit, fuzz, fork, and invariant tests pass.
- [ ] Unit-test coverage for flash-loan logic is at least 90%.
- [ ] No unresolved high-severity static-analysis finding remains.

---

# Phase 7 — Profit, Gas, and Fee Settlement

## Objective

Implement complete post-arbitrage accounting and safely divide gross profit into expenses, fees, reinvestment, and withdrawable profit.

## Work Items

### Settlement order

```text
Gross arbitrage surplus
    - flash-loan premium
    - capped gas reimbursement
    - executor fee
    - protocol fee
    = net realized profit
```

The flash-loan principal is repayment of debt and must not be treated as profit or expense.

### Reinvestment allocation

```text
reinvestmentAmount =
netRealizedProfit * reinvestmentBps / 10_000

withdrawableAmount =
netRealizedProfit - reinvestmentAmount
```

### Gas reimbursement

Implement:

- Starting gas snapshot.
- Measured gas used.
- Configured gas-price cap.
- User-configured reimbursement cap.
- Native-token-to-settlement-token conversion.
- Trusted oracle or signed quote.
- Maximum quote age.
- Safety margin.
- Protection against keeper-controlled oracle values.

Suggested formula:

```text
effectiveGasPrice = min(tx.gasprice, configuredGasPriceCap)

nativeGasCost =
gasUsed * effectiveGasPrice

settlementGasCost =
convert(nativeGasCost, oraclePrice)

gasReimbursement =
min(
    settlementGasCost,
    request.maxGasReimbursement,
    user.maxGasReimbursement
)
```

### Fee policy

Document and implement whether fees are calculated from:

- Gross profit.
- Profit after gas reimbursement.
- Net realized profit.

Do not change the fee basis after deployment without timelocked governance.

## Testing Requirements

- Zero-profit settlement.
- Small-profit settlement.
- Large-profit settlement.
- 0% reinvestment.
- 100% reinvestment.
- Invalid reinvestment percentage.
- Gas cap reached.
- Gas-price cap reached.
- Stale oracle.
- Manipulated oracle.
- Rounding behavior.
- Fee rounding.
- Accounting duplication attempt.
- Multiple consecutive settlements.
- Invariant: total allocated amount equals net realized profit.
- Invariant: protocol fees cannot be withdrawn from user balances.

## Phase Completion Requirements

Phase 7 is finished only when:

- [ ] Every settlement component has a documented formula.
- [ ] Settlement order is fixed and tested.
- [ ] Flash-loan principal is never recorded as profit.
- [ ] Flash-loan premium is accounted for exactly once.
- [ ] Gas reimbursement is capped.
- [ ] Oracle quotes have freshness validation.
- [ ] Protocol and executor fees are separated from user balances.
- [ ] Reinvestment and withdrawable amounts always sum to net realized profit.
- [ ] Rounding rules are documented.
- [ ] Multiple sequential arbitrages maintain correct balances.
- [ ] Accounting invariants pass under fuzz testing.
- [ ] Unit-test coverage for settlement logic is at least 95%.
- [ ] Independent manual calculations match contract results for all documented examples.

---

# Phase 8 — Off-Chain Arbitrage Searcher and Execution Service

> **Prerequisite:** The Smart-Contract Core Completion Gate must be satisfied. A limited simulator may exist earlier only for contract development and testing.

## Objective

Build the production-grade service that identifies, simulates, ranks, and submits profitable arbitrage opportunities.

## Work Items

### Pool indexer

- Index approved pools.
- Store token pairs.
- Store fee tiers.
- Store pool addresses.
- Track liquidity and reserve changes.
- Track block number and timestamp.
- Handle chain reorganizations.
- Mark stale pool state.

### Opportunity detector

Support:

- Two-pool cycles.
- Triangular cycles.
- Multiple trade sizes.
- DEX fee calculation.
- Flash-loan premium.
- Gas estimate.
- Slippage buffer.
- Minimum net-profit threshold.
- Maximum trade size.
- User-specific constraints.

### Simulator

Before submission:

- Simulate the complete transaction against the latest block.
- Confirm repayment.
- Confirm final profit.
- Confirm gas consumption.
- Reject stale simulations.
- Apply safety margin.
- Generate request calldata.

### Executor service

- Manage keeper key securely.
- Use nonce locking.
- Retry only when safe.
- Cancel stale transactions.
- Prefer private transaction submission where supported.
- Record transaction lifecycle.
- Prevent duplicate execution.
- Maintain per-vault rate limits.

### Profitability formula

```text
expectedNetProfit =
expectedFinalSettlementAmount
- borrowedPrincipal
- flashLoanPremium
- estimatedGasInSettlementToken
- executorFee
- protocolFee
- safetyMargin
```

## Testing Requirements

- Unit tests for route discovery.
- Unit tests for quote calculations.
- Backtesting against historical blocks.
- Local fork simulations.
- Stale-state rejection.
- Reorg handling.
- Duplicate-opportunity suppression.
- Failed-transaction handling.
- Nonce-conflict handling.
- Provider outage handling.
- RPC inconsistency handling.
- Chaos testing for delayed blocks and dropped transactions.

## Phase Completion Requirements

Phase 8 is finished only when:

- [ ] The service indexes all approved pools.
- [ ] Two-pool opportunities are detected.
- [ ] Triangular opportunities are detected.
- [ ] Flash-loan fees are included.
- [ ] Gas costs are included.
- [ ] User risk limits are applied.
- [ ] Every submitted transaction is simulated first.
- [ ] Stale opportunities are discarded.
- [ ] Duplicate submissions are prevented.
- [ ] Private transaction submission is supported where available.
- [ ] Reorgs do not corrupt indexed pool state.
- [ ] Transaction states are persisted.
- [ ] Backtesting results are documented.
- [ ] The service runs continuously on testnet for at least seven days without unrecovered state corruption.
- [ ] No transaction is submitted when modeled net profit is below the configured threshold.

---

# Phase 9 — Asset Ranking and Portfolio Allocation

## Objective

Define and implement a controlled process for selecting approved investment assets using transparent, reproducible metrics.

## Work Items

### Approved token universe

Maintain per-chain metadata:

- Token address.
- Symbol.
- Decimals.
- Minimum liquidity.
- Minimum volume.
- Maximum allocation.
- Oracle source.
- DEX availability.
- Risk status.
- Enable/disable state.

### Ranking metrics

Possible factors:

- 24-hour return.
- 7-day return.
- 30-day return.
- Trading volume.
- Available liquidity.
- Volatility.
- Maximum drawdown.
- Token age.
- Price-oracle quality.
- Smart-contract risk score.

### Ranking formula

Define a deterministic formula, for example:

```text
score =
(returnWeight * normalizedReturn)
+ (volumeWeight * normalizedVolume)
+ (liquidityWeight * normalizedLiquidity)
- (volatilityWeight * normalizedVolatility)
- riskPenalty
```

### Allocation constraints

- Maximum number of active assets.
- Maximum allocation per asset.
- Minimum stablecoin reserve.
- Minimum allocation amount.
- Maximum portfolio turnover.
- Rebalance cooldown.
- User exclusions.
- Risk-manager exclusions.

### On-chain/off-chain boundary

The ranking engine may run off-chain, but the on-chain allocator must validate:

- Token is approved.
- Allocation does not exceed caps.
- Total allocation equals authorized reinvestment capital.
- Quote is signed by an approved signer if signatures are used.
- Quote is not expired.
- Quote nonce is unused.

## Testing Requirements

- Ranking determinism.
- Missing market data.
- Stale data.
- Outlier price.
- Low-liquidity token.
- Disabled token.
- Allocation cap.
- Stablecoin reserve.
- Signature replay.
- Expired allocation.
- Invalid signer.
- Rounding and dust handling.

## Phase Completion Requirements

Phase 9 is finished only when:

- [ ] The approved-token universe is documented.
- [ ] Every token has a valid oracle and executable DEX route.
- [ ] Ranking methodology is deterministic and versioned.
- [ ] Ranking inputs have freshness rules.
- [ ] Low-liquidity and disabled assets are excluded.
- [ ] Allocation caps are enforced on-chain.
- [ ] Stablecoin reserve requirements are enforced.
- [ ] Allocation messages cannot be replayed.
- [ ] Historical ranking backtests are documented.
- [ ] Ranking output can be reproduced from stored inputs.
- [ ] Portfolio allocation never exceeds available reinvestment capital.

---

# Phase 10 — Grid Trading Strategy

## Objective

Use reinvested profit to create and manage user-configurable grid strategies for approved assets.

## Work Items

### User grid configuration

Support:

- Asset.
- Quote/settlement token.
- Lower price.
- Upper price.
- Number of grid levels.
- Total allocation.
- Per-grid allocation.
- Maximum slippage.
- Stop loss.
- Take profit.
- Grid expiration.
- Compounding enabled/disabled.
- Maximum token inventory.
- Minimum time between executions.
- Pause and cancel.

### Grid calculation

Support either:

- Arithmetic grid.
- Geometric grid.

For an arithmetic grid:

```text
gridSpacing =
(upperPrice - lowerPrice) / numberOfGrids
```

For a geometric grid:

```text
ratio =
(upperPrice / lowerPrice) ^ (1 / numberOfGrids)
```

### Execution model

The off-chain keeper monitors market prices and submits execution requests.

The on-chain strategy validates:

- Grid is active.
- Trigger price has been crossed.
- Price comes from an approved oracle.
- Oracle is fresh.
- Correct grid level is being executed.
- Grid level has not already been filled.
- Cooldown has passed.
- Slippage is within limit.
- Allocation is available.
- Maximum inventory is respected.
- Stop-loss conditions are respected.

### Position accounting

Track:

- Asset amount.
- Settlement-token cost basis.
- Average entry price.
- Filled buy levels.
- Filled sell levels.
- Realized PnL.
- Unrealized PnL.
- Total fees.
- Last execution price.
- Last execution block.
- Active capital.
- Idle grid capital.

### Exit behavior

Support:

- Pause without selling.
- Cancel and retain asset.
- Cancel and convert to settlement token.
- Emergency exit.
- User withdrawal of the asset directly.
- User withdrawal after liquidation.

## Testing Requirements

- Arithmetic grid generation.
- Geometric grid generation.
- Buy trigger.
- Sell trigger.
- Repeated trigger.
- Skipped price levels.
- Large price gap.
- Stop loss.
- Take profit.
- Expiration.
- Pause.
- Cancel.
- Full exit.
- Partial exit.
- Slippage failure.
- Oracle staleness.
- Inventory cap.
- Multiple assets.
- PnL calculations.
- Dust and rounding.
- Fuzz tests for arbitrary grid parameters.
- Invariant: strategy cannot spend more than allocated grid capital.

## Phase Completion Requirements

Phase 10 is finished only when:

- [ ] Users can create valid grid configurations.
- [ ] Invalid ranges and grid counts are rejected.
- [ ] Buy and sell levels are generated deterministically.
- [ ] Each grid level has explicit state.
- [ ] A filled level cannot be executed twice.
- [ ] Oracle freshness and price checks are enforced.
- [ ] Slippage limits are enforced.
- [ ] Maximum asset inventory is enforced.
- [ ] Stop-loss and expiration behavior match the specification.
- [ ] Realized and unrealized PnL calculations are tested.
- [ ] Users can pause and exit a strategy.
- [ ] Grid capital cannot exceed the reinvestment allocation.
- [ ] Unit-test coverage for grid logic is at least 90%.
- [ ] Fuzz and invariant tests pass.

---

# Phase 11 — Backend, Database, and Event Indexing

> **Prerequisite:** The Smart-Contract Core Completion Gate must be satisfied and contract events must be frozen for the integration version.

## Objective

Create the application backend and durable data model for user vaults, transactions, positions, configurations, and analytics.

## Work Items

### Database entities

At minimum:

- Users.
- Vaults.
- Deposits.
- Withdrawals.
- Arbitrage requests.
- Arbitrage executions.
- Swap steps.
- Flash loans.
- Profit settlements.
- Gas reimbursements.
- Protocol fees.
- Executor fees.
- Investment allocations.
- Grid configurations.
- Grid orders.
- Grid executions.
- Positions.
- Price snapshots.
- Token rankings.
- Keeper heartbeats.
- Alerts.
- Chain sync state.

### Event indexer

Index:

- Vault creation.
- Deposits.
- Withdrawals.
- Arbitrage execution.
- Flash-loan repayment.
- Profit settlement.
- Reinvestment allocation.
- Grid creation.
- Grid execution.
- Grid closure.
- Emergency pause.
- Administrative changes.

### Reconciliation

Implement periodic checks:

```text
On-chain vault balance
vs
On-chain accounting
vs
Database accounting
```

Any mismatch must trigger an alert and disable automated execution for the affected vault until reviewed.

## Testing Requirements

- Event idempotency.
- Reorg rollback.
- Duplicate event handling.
- Missing-block recovery.
- Database transaction rollback.
- Chain/database reconciliation.
- Historical resync.
- API authorization.
- Rate limiting.
- Input validation.

## Phase Completion Requirements

Phase 11 is finished only when:

- [ ] All critical contract events are indexed.
- [ ] Reorged events are rolled back correctly.
- [ ] Duplicate events do not create duplicate records.
- [ ] The indexer can resume from the last confirmed block.
- [ ] Historical resync is supported.
- [ ] Reconciliation runs automatically.
- [ ] Accounting mismatch disables affected automation.
- [ ] APIs enforce authorization and input validation.
- [ ] Database migrations are versioned.
- [ ] Backup and restoration procedures are tested.
- [ ] No user-facing balance is derived solely from the database without on-chain confirmation.

---

# Phase 12 — Frontend and User Experience

> **Prerequisite:** The Smart-Contract Core Completion Gate must be satisfied. UI mockups may be created earlier, but full contract integration must wait.

## Objective

Build a user interface that clearly communicates capital status, strategy risk, realized results, and withdrawal availability.

## Required Pages

### Dashboard

Display:

- Vault address.
- Total deposited principal.
- Idle balance.
- Active arbitrage configuration.
- Net arbitrage profit.
- Withdrawable profit.
- Reinvested capital.
- Active grid capital.
- Portfolio value.
- Realized PnL.
- Unrealized PnL.
- Total fees.
- Recent transactions.

### Vault page

- Create vault.
- Deposit.
- Withdraw idle funds.
- Full exit.
- Emergency withdrawal.
- Token approvals.
- Vault configuration.

### Arbitrage settings

- Enable/disable.
- Funding mode.
- Enable/disable flash-loan arbitrage.
- Maximum trade size.
- Minimum net profit.
- Maximum gas reimbursement.
- Maximum slippage.
- Reinvestment percentage.

### Investment settings

- Approved assets.
- Maximum assets.
- Maximum allocation per asset.
- Stablecoin reserve.
- Risk profile.
- Asset exclusions.

### Grid settings

- Asset.
- Range.
- Grid type.
- Grid count.
- Allocation.
- Stop loss.
- Take profit.
- Expiration.
- Pause.
- Cancel.
- Exit.

### Transaction transparency

For every arbitrage execution show:

- Borrowed amount.
- Route.
- DEXs.
- Gross proceeds.
- Flash-loan fee.
- Gas reimbursement.
- Executor fee.
- Protocol fee.
- Net profit.
- Reinvested amount.
- Withdrawable amount.
- Transaction hash.

## Phase Completion Requirements

Phase 12 is finished only when:

- [ ] A user can create a vault.
- [ ] A user can deposit and withdraw.
- [ ] A user can configure arbitrage limits.
- [ ] A user can independently enable or disable flash-loan arbitrage.
- [ ] The UI clearly distinguishes user-funded and flash-loan-funded execution.
- [ ] A user can configure reinvestment percentage.
- [ ] A user can create, pause, cancel, and exit a grid.
- [ ] All displayed balances match on-chain state.
- [ ] Pending and failed transactions are clearly shown.
- [ ] Financial values show token units and fiat estimates separately.
- [ ] The interface never labels estimated profit as realized profit.
- [ ] Risk disclosures are visible before enabling strategies.
- [ ] Mobile and desktop layouts are usable.
- [ ] Wallet rejection and chain mismatch are handled.
- [ ] End-to-end tests cover the primary user flows.

---

# Phase 13 — Security Hardening

## Objective

Prepare the complete system for adversarial use and independent review.

## Work Items

### Smart-contract security

- Reentrancy review.
- Access-control review.
- Initialization review.
- Upgradeability review.
- Storage-layout review.
- Oracle review.
- Approval review.
- Arbitrary-call review.
- Callback authentication review.
- Flash-loan repayment review.
- Accounting review.
- Rounding review.
- Denial-of-service review.
- Emergency control review.
- Token-behavior review.
- MEV exposure review.

### Testing

- Unit tests.
- Integration tests.
- Fork tests.
- Fuzz tests.
- Stateful invariant tests.
- Differential tests.
- Mutation testing.
- Static analysis.
- Symbolic analysis where practical.
- Gas profiling.
- Contract-size checks.

### Operational security

- Multisig administration.
- Timelocked upgrades.
- Hardware-backed deployer keys.
- Separate deployer, upgrader, pauser, and fee-recipient roles.
- Keeper key rotation.
- Secret management.
- RPC failover.
- Monitoring.
- Incident-response runbook.
- Emergency shutdown procedure.
- Dependency pinning.
- Reproducible builds.

### External audit preparation

Prepare:

- Architecture.
- Threat model.
- Contract specification.
- Role matrix.
- Known assumptions.
- Test report.
- Coverage report.
- Deployment scripts.
- Invariant list.
- Previous security findings.
- Out-of-scope list.

## Phase Completion Requirements

Phase 13 is finished only when:

- [ ] All critical paths have unit and integration tests.
- [ ] Core accounting contracts have at least 95% line and branch coverage.
- [ ] Other smart contracts have at least 90% line coverage.
- [ ] All defined invariants pass.
- [ ] Fork tests pass against selected live protocols.
- [ ] Static-analysis findings are reviewed.
- [ ] No unresolved critical or high-severity issue remains.
- [ ] Medium findings have documented resolution or accepted risk.
- [ ] Upgrade permissions are protected by multisig and timelock.
- [ ] Emergency pause has been tested on a fork.
- [ ] Keeper compromise has been simulated.
- [ ] Oracle failure has been simulated.
- [ ] RPC failure has been simulated.
- [ ] Incident-response procedures are documented.
- [ ] An external audit is completed before unrestricted mainnet deposits.

---

# Phase 14 — Testnet Beta

## Objective

Operate the complete system on a public testnet under realistic conditions.

## Work Items

- Deploy contracts.
- Verify contracts.
- Configure roles.
- Configure adapters.
- Configure tokens.
- Configure oracles.
- Run opportunity detector.
- Run flash-loan simulations where supported.
- Run grid keeper.
- Enable frontend.
- Collect telemetry.
- Test pause and recovery.
- Test indexer resync.
- Test deployment reproducibility.
- Conduct controlled user testing.

## Required Testnet Scenarios

- User creates vault.
- User deposits.
- User configures risk limits.
- User enables arbitrage.
- Two-pool arbitrage executes.
- Triangular arbitrage executes.
- Flash loan is borrowed and repaid.
- Profit is settled.
- Reinvestment allocation is created.
- Grid buys.
- Grid sells.
- User pauses grid.
- User exits grid.
- User withdraws funds.
- Keeper goes offline.
- RPC provider fails.
- Oracle becomes stale.
- Contract is paused.
- Indexer resynchronizes.
- Duplicate transaction is rejected.

## Phase Completion Requirements

Phase 14 is finished only when:

- [ ] The complete user flow works end to end.
- [ ] Contracts are verified.
- [ ] Deployment addresses and configuration are documented.
- [ ] The system runs continuously for at least 14 days.
- [ ] No unreconciled accounting mismatch occurs.
- [ ] No flash loan remains unpaid after a successful transaction.
- [ ] Failed arbitrage transactions do not reduce vault principal.
- [ ] Grid executions match configured levels.
- [ ] Keeper restart does not duplicate execution.
- [ ] Indexer restart does not duplicate records.
- [ ] Emergency pause and recovery are tested.
- [ ] All discovered defects are classified and resolved or explicitly deferred.
- [ ] Testnet beta sign-off is approved by engineering and security reviewers.

---

# Phase 15 — Mainnet Limited Beta

## Objective

Launch with strict caps and a small approved user group.

## Initial Restrictions

- Maximum number of users.
- Maximum deposit per vault.
- Maximum system TVL.
- Maximum arbitrage size.
- Maximum flash-loan size.
- Maximum daily execution count.
- Maximum grid allocation.
- Limited approved tokens.
- Limited approved DEXs.
- Manual approval for new vault activation.
- 24/7 monitoring.
- Immediate pause authority.

## Rollout Steps

1. Deploy implementation contracts.
2. Verify bytecode and constructor/initializer parameters.
3. Transfer roles to multisig.
4. Configure timelock.
5. Configure fee recipients.
6. Configure adapters and tokens.
7. Fund operational wallets.
8. Run read-only monitoring.
9. Enable one internal vault.
10. Enable a small group of external vaults.
11. Gradually increase caps.
12. Review performance and incidents after each cap increase.

## Phase Completion Requirements

Phase 15 is finished only when:

- [ ] External audit findings are resolved.
- [ ] Mainnet deployment is verified.
- [ ] Administrative roles are held by the intended multisig.
- [ ] Upgrade operations require the configured timelock.
- [ ] Deposit and trade caps are enforced on-chain.
- [ ] Monitoring and alerts are active.
- [ ] Accounting reconciliation runs continuously.
- [ ] At least 30 days of limited-beta operation completes.
- [ ] No unresolved critical or high-severity incident exists.
- [ ] User withdrawals work during normal and paused states.
- [ ] Keeper or backend downtime does not prevent owner withdrawals.
- [ ] Mainnet performance, gas cost, failure rate, and realized profit reports are reviewed.
- [ ] A formal go/no-go review approves broader release.

---

# Phase 16 — Production Release

## Objective

Open the system to broader use while maintaining risk-controlled limits.

## Work Items

- Increase user limits gradually.
- Increase TVL caps gradually.
- Add additional approved assets.
- Add additional DEX adapters.
- Add additional flash-loan providers only after separate review.
- Improve private transaction submission.
- Add user reporting.
- Add tax/export data.
- Add strategy analytics.
- Add performance attribution.
- Add public status page.
- Add bug bounty.
- Establish periodic security reviews.
- Establish upgrade release process.

## Phase Completion Requirements

Phase 16 is finished only when:

- [ ] Limited-beta exit criteria are met.
- [ ] Production caps are documented.
- [ ] A bug-bounty program is active.
- [ ] A public incident-response channel exists.
- [ ] Operational ownership is assigned.
- [ ] On-call rotation is active.
- [ ] Service-level objectives are documented.
- [ ] Backup RPC, database, and deployment procedures are tested.
- [ ] Monthly accounting reconciliation reports are generated.
- [ ] Security review is required for every new adapter, token, oracle, or flash-loan provider.
- [ ] Production launch is approved by engineering, security, and operations.

---

# Phase 17 — Additional Same-Chain Arbitrage Strategies

## Objective

Expand the production system beyond basic two-pool and triangular arbitrage while remaining on a single EVM chain.

Every new strategy must use the existing vault, route-validation, settlement, risk-control, and user-permission framework. New strategies must be individually enabled or disabled by each user.

## User Configuration

Add per-strategy controls such as:

```solidity
struct ArbitrageStrategyConfig {
    bool enabled;
    bool flashLoanAllowed;
    uint256 maxTradeSize;
    uint256 minNetProfit;
    uint256 maxGasReimbursement;
    uint16 maxSlippageBps;
}
```

A strategy may execute only when:

- Global arbitrage is enabled for the vault.
- The specific strategy is enabled by the vault owner.
- Flash-loan use is enabled by the user when the request requires a flash loan.
- The route satisfies the user's limits.
- The predicted and simulated net profit exceed the configured threshold.

## Strategies

### Stablecoin arbitrage

Support cycles between approved stablecoins, for example:

```text
USDC -> USDT -> DAI -> USDC
```

Requirements:

- Approved stablecoins only.
- Reliable price-oracle coverage.
- Depeg protection.
- Per-token exposure limits.
- Tight slippage limits.
- Minimum pool-liquidity requirements.

### Uniswap V3 fee-tier arbitrage

Compare the same pair across different fee tiers, for example:

```text
USDC/WETH 0.05% pool
vs
USDC/WETH 0.30% pool
```

Requirements:

- Tick-aware quoting.
- Active-liquidity analysis.
- Price-impact simulation across initialized ticks.
- Fee-tier-specific route validation.
- Accurate callback authentication.

### Multi-DEX routing

Allow one atomic route to use several approved DEX adapters.

Requirements:

- Token continuity across all hops.
- Approved adapter and router for every hop.
- Maximum permitted hop count.
- Per-hop minimum output.
- Final settlement-token profit validation.

### Liquid-staking-token arbitrage

Support approved liquid-staking tokens against their wrapped or underlying assets.

Requirements:

- Explicit allowlist.
- Exchange-rate and redemption-model review.
- Depeg and withdrawal-delay protections.
- No assumption that one derivative token always equals one underlying token.
- Separate liquidity and oracle limits.

### Backrun arbitrage

Allow the searcher to submit an arbitrage transaction immediately after a qualifying pending or bundled transaction.

Requirements:

- Private bundle submission where available.
- Exact target-block or maximum-block constraints.
- Complete bundle simulation.
- Revert protection.
- No dependence on public mempool ordering guarantees.
- Strategy-specific gas and MEV limits.

## Architecture Changes

Add:

```text
contracts/arbitrage/
├── StablecoinArbitrageStrategy.sol
├── V3FeeTierArbitrageStrategy.sol
├── MultiDexArbitrageStrategy.sol
├── LiquidStakingArbitrageStrategy.sol
└── BackrunArbitrageStrategy.sol

services/opportunity-detector/
├── stablecoin-detector/
├── v3-fee-tier-detector/
├── multi-dex-detector/
├── lst-detector/
└── backrun-detector/
```

The core executor must not hardcode strategy-specific arbitrary calls. Each strategy must return or validate a bounded execution plan using approved adapters.

## Testing Requirements

- Unit tests for every strategy.
- Profitable and unprofitable route tests.
- User-disabled strategy tests.
- Flash-loan-disabled tests.
- Stablecoin depeg tests.
- V3 tick-crossing and low-liquidity tests.
- Mixed-DEX route tests.
- LST exchange-rate deviation tests.
- Backrun target-block and failed-bundle tests.
- Fork tests against supported live protocols.
- Fuzz tests over trade size, slippage, and hop count.
- Invariant: no strategy can bypass vault limits or settlement accounting.
- Invariant: a successful strategy cannot reduce protected user principal.

## Phase Completion Requirements

Phase 17 is finished only when:

- [ ] Every new strategy is independently configurable by the vault owner.
- [ ] Every new strategy is disabled by default for existing and new vaults.
- [ ] Flash-loan use remains separately controlled by the user.
- [ ] Stablecoin arbitrage enforces depeg and exposure limits.
- [ ] V3 fee-tier execution handles concentrated liquidity and tick crossings correctly.
- [ ] Multi-DEX routes enforce adapter approval, token continuity, and maximum hop count.
- [ ] Liquid-staking-token routes use reviewed assets, oracles, and conversion assumptions.
- [ ] Backrun routes require successful bundle simulation and bounded block validity.
- [ ] Gas, DEX fees, flash-loan fees, MEV costs, and protocol fees are included in profitability calculations.
- [ ] Failed and unprofitable executions revert atomically.
- [ ] Fork tests pass for each enabled production strategy.
- [ ] Core accounting and security invariants pass.
- [ ] No unresolved critical or high-severity issue remains.
- [ ] Each strategy has completed a separate security review before production activation.

---

# Phase 18 — Governed Strategy Marketplace

> **Prerequisite:** The Smart-Contract Core Completion Gate, security hardening, and base-strategy audit requirements must be satisfied.

## Objective

Create a non-custodial marketplace where approved strategy developers can publish strategy modules or configuration templates that users may voluntarily activate for their own vaults.

The marketplace must never allow a third-party developer to custody user funds or execute unrestricted calls from a user vault.

## Marketplace Model

A strategy listing may represent either:

1. A configuration-only strategy template using existing audited modules.
2. A new strategy module that has passed governance review, technical validation, and security review.

Configuration-only templates should be preferred because they introduce less smart-contract risk.

## Strategy Listing Data

Track:

```solidity
struct StrategyListing {
    bytes32 strategyId;
    address implementation;
    address developer;
    bytes32 codeHash;
    uint32 version;
    uint16 developerFeeBps;
    StrategyRiskLevel riskLevel;
    bool configurationOnly;
    bool approved;
    bool paused;
}
```

Off-chain metadata may include:

- Strategy name and description.
- Supported assets and DEXs.
- Required vault permissions.
- Historical performance.
- Maximum drawdown.
- Win rate.
- Average net profit.
- Gas consumption.
- Failure rate.
- Audit reports.
- Source-code repository and commit hash.
- Known risks and assumptions.

Historical performance must be clearly labeled as simulated, backtested, testnet, or live. It must not be presented as guaranteed future performance.

## Security and Governance Requirements

### Module approval

A module may be listed only after:

- Source code is published.
- Bytecode matches the reviewed source.
- Contract interfaces are compatible.
- Static analysis passes.
- Unit, fork, fuzz, and invariant tests pass.
- Required external audit or independent review is completed.
- Governance approves the exact implementation address and code hash.
- A timelock expires before activation.

### Execution sandbox

Marketplace strategies must not be able to:

- Withdraw user assets to arbitrary recipients.
- Change vault ownership.
- Approve arbitrary spenders.
- Call unapproved contracts.
- Upgrade the vault.
- Disable user withdrawals.
- bypass token, adapter, oracle, slippage, gas, loss, or exposure limits.

The vault must execute marketplace strategies through a restricted strategy interface and validate all resulting state changes.

### User consent

The user must explicitly select:

- Strategy version.
- Capital allocation.
- Maximum trade size.
- Maximum loss.
- Maximum gas reimbursement.
- Allowed assets.
- Whether flash loans are allowed.
- Developer fee.
- Expiration or review date.

Strategies must be disabled by default.

### Versioning

- Every module version receives a unique strategy ID or version identifier.
- Existing users are not migrated automatically.
- Users must explicitly approve a new version.
- Deprecated or vulnerable versions can be paused from new executions.
- A pause must not prevent users from withdrawing or exiting positions.

### Developer compensation

Possible fee model:

```text
Gross strategy profit
- flash-loan fee
- gas reimbursement
- protocol fee
- executor fee
- developer performance fee
= user net realized profit
```

Developer fees must:

- Be disclosed before activation.
- Be capped by governance.
- Apply only to realized positive profit.
- Never be charged on principal or unrealized gains.
- Be included in minimum-net-profit validation.

## Reputation and Analytics

Display verified metrics such as:

- Total executions.
- Successful executions.
- Failure rate.
- Realized net profit.
- Maximum drawdown.
- Average gas cost.
- Profit after all fees.
- Number of active vaults.
- Strategy age.
- Current audited version.

Metrics must be derived from indexed on-chain events wherever possible.

## Emergency Controls

Support:

- Pause a strategy version.
- Disable new allocations.
- Allow position closure.
- Revoke module authorization.
- Notify affected vault owners.
- Preserve owner withdrawals.
- Provide migration instructions for replacement versions.

## Testing Requirements

- Listing creation and approval tests.
- Unapproved module rejection.
- Code-hash mismatch rejection.
- Unauthorized developer update tests.
- User activation and deactivation tests.
- Allocation-cap tests.
- Developer-fee tests.
- Fee-on-loss rejection tests.
- Version-upgrade consent tests.
- Paused-strategy exit tests.
- Malicious module tests.
- Arbitrary-call attempt tests.
- Arbitrary-approval attempt tests.
- Withdrawal-blocking attempt tests.
- Cross-vault isolation tests.
- Marketplace analytics reconciliation tests.
- Invariant: a listed strategy cannot obtain more authority than the user explicitly granted.

## Phase Completion Requirements

Phase 18 is finished only when:

- [ ] Configuration-only templates and executable modules are clearly separated.
- [ ] No strategy can be listed without governance approval.
- [ ] Approved source, bytecode, implementation address, and code hash are linked.
- [ ] Every executable strategy version has completed the required security review.
- [ ] Users explicitly activate strategies and define capital and risk limits.
- [ ] Strategies are disabled by default.
- [ ] Flash-loan permission remains separately controlled by each user.
- [ ] Developer fees are disclosed, capped, and charged only on realized positive profit.
- [ ] A module cannot withdraw, approve, upgrade, or call arbitrary addresses.
- [ ] A vulnerable strategy can be paused without blocking user withdrawals or exits.
- [ ] Existing users are never automatically migrated to a new strategy version.
- [ ] Performance labels distinguish backtested, simulated, testnet, and live results.
- [ ] Marketplace metrics reconcile with on-chain events.
- [ ] Malicious-module and permission-escape tests pass.
- [ ] No unresolved critical or high-severity issue remains.
- [ ] A separate external audit is completed before third-party executable modules are publicly enabled.

---


# Phase 19 — Smart-Account Experience and Session-Key Automation

> **Prerequisite:** The Smart-Contract Core Completion Gate must be satisfied and vault permissions must be stable.

## Objective

Improve user experience and automation security by allowing each vault to operate through a programmable smart-account layer.

The smart-account integration must reduce repeated wallet confirmations without giving the keeper, backend, or session key unrestricted control over user funds.

This phase may use ERC-4337-compatible account abstraction or an equivalent audited smart-account framework available on the selected chain.

## User-Facing Capabilities

Support:

- Batched vault creation, approval, and deposit.
- Batched strategy configuration.
- Optional sponsored gas through an approved paymaster.
- Session keys for limited automated actions.
- Session-key expiration.
- Session-key revocation.
- Daily and per-transaction spending limits.
- Contract and function allowlists.
- Token allowlists.
- Strategy-specific permissions.
- Social or guardian-assisted recovery, if supported.
- Owner-controlled emergency invalidation.
- Clear display of active automation permissions.

## Permission Model

The smart-account owner retains full control.

A session key may be authorized only for predefined operations such as:

```text
- Execute validated arbitrage
- Execute validated grid orders
- Update non-critical strategy state
- Spend no more than the configured execution limit
- Interact only with approved protocol contracts
```

A session key must never be able to:

```text
- Withdraw user funds
- Transfer assets to an arbitrary recipient
- Change the smart-account owner
- Change recovery guardians
- Upgrade the vault or smart account
- Approve a new adapter, router, token, or flash-loan provider
- Increase its own permissions
- Disable protocol safety checks
- Modify fee recipients
```

## Suggested Session-Key Policy

```solidity
struct SessionKeyPolicy {
    address sessionKey;
    uint48 validAfter;
    uint48 validUntil;
    uint256 maxValuePerOperation;
    uint256 maxValuePerDay;
    uint256 maxGasPerOperation;
    bool arbitrageAllowed;
    bool gridExecutionAllowed;
    bool flashLoanExecutionAllowed;
}
```

Additional policy data should include:

- Approved target contracts.
- Approved function selectors.
- Approved settlement tokens.
- Approved strategy identifiers.
- Vault identifier.
- Chain identifier.
- Nonce or replay-protection domain.
- Maximum executions per hour or day.

## Account-Abstraction Components

Where ERC-4337 is used, define and document:

- Smart-account implementation.
- Account factory.
- EntryPoint version.
- Bundler integration.
- Paymaster policy.
- Signature validation.
- Session-key validator module.
- Recovery module.
- Upgrade policy.
- Nonce model.
- UserOperation simulation.
- Gas-estimation flow.

## Gas Sponsorship

Gas sponsorship must be optional and policy controlled.

The paymaster may sponsor only:

- Vault creation.
- Initial deposit setup.
- Approved configuration changes.
- Validated arbitrage executions.
- Validated grid executions.

The paymaster must reject:

- Withdrawals to arbitrary addresses.
- Unsupported contracts.
- Unsupported function selectors.
- Expired operations.
- Operations exceeding user or protocol limits.
- Repeated or replayed requests.
- Operations from blocked accounts.

Sponsorship cost must be accounted for explicitly as one of:

- Protocol-funded onboarding cost.
- Deduction from future net profit.
- Subscription benefit.
- User-prepaid gas balance.

The accounting model must not hide sponsored gas as trading profit.

## Batched User Operations

Support safe batching for actions such as:

```text
Create vault
-> approve settlement token
-> deposit
-> configure risk limits
-> optionally enable flash-loan arbitrage
```

And:

```text
Pause strategy
-> close grid position
-> convert approved assets
-> withdraw settlement token
```

Every batched sub-call must be individually validated. Failure behavior must be documented as either fully atomic or intentionally partial.

## Recovery

Where recovery is enabled:

- Recovery cannot bypass withdrawal safety.
- Guardian changes require a delay.
- Recovery initiation emits events.
- Owner cancellation is supported during the delay.
- Recovery cannot silently change session-key permissions.
- Recovery modules must be independently audited or widely reviewed.
- The protocol must not act as the sole recovery guardian.

## Frontend Requirements

The frontend must show:

- Whether the user is using an EOA or smart account.
- Smart-account address.
- Owner address.
- Active session keys.
- Session-key permissions.
- Spending limits.
- Expiration time.
- Last usage.
- Paymaster sponsorship status.
- Recovery configuration.
- Revoke-session-key action.
- Emergency disable-all-automation action.

Before authorization, the user must see a human-readable permission summary.

## Backend Requirements

The backend must:

- Simulate every UserOperation before submission.
- Refuse operations outside the stored session policy.
- Track session-key usage.
- Track daily spending limits.
- Prevent duplicate submissions.
- Handle bundler failure.
- Support multiple bundlers or fallback submission.
- Persist UserOperation hashes and final transaction hashes.
- Alert on unexpected permission failures.
- Never store the owner wallet's private key.

## Testing Requirements

Test:

- Smart-account deployment.
- Deterministic account address.
- Batched vault creation and deposit.
- Valid owner operation.
- Invalid owner signature.
- Valid session-key arbitrage execution.
- Valid session-key grid execution.
- Session-key withdrawal attempt.
- Arbitrary target attempt.
- Unauthorized function selector.
- Spending-limit breach.
- Daily-limit breach.
- Expired session key.
- Revoked session key.
- Flash-loan execution while permission is disabled.
- Replay attempt across nonces.
- Replay attempt across chains.
- Replay attempt across vaults.
- Bundler rejection.
- Paymaster rejection.
- Paymaster balance exhaustion.
- Recovery initiation.
- Recovery cancellation.
- Delayed recovery completion.
- Guardian replacement.
- Emergency automation invalidation.
- Upgrade authorization.
- Fuzz testing of permission combinations.
- Invariant: session keys cannot reduce user assets except through explicitly authorized strategy execution.

## Phase Completion Requirements

Phase 19 is finished only when:

- [ ] A user can create or connect an approved smart account.
- [ ] Vault setup can be performed through a documented atomic batch.
- [ ] Session keys are disabled by default.
- [ ] Only the smart-account owner can authorize or revoke session keys.
- [ ] Every session key has an expiration time.
- [ ] Contract and function-selector allowlists are enforced.
- [ ] Per-operation and daily spending limits are enforced.
- [ ] Session keys cannot withdraw funds.
- [ ] Session keys cannot change ownership or recovery configuration.
- [ ] Session keys cannot expand their own permissions.
- [ ] Flash-loan execution requires both the user's vault setting and the session-key permission.
- [ ] Revocation takes effect immediately for future operations.
- [ ] UserOperations are simulated before submission.
- [ ] Replay protection works across operations, vaults, and chains.
- [ ] Paymaster sponsorship rules are documented and enforced.
- [ ] Sponsored gas is accounted for separately from investment returns.
- [ ] Bundler and paymaster failures do not block direct owner withdrawals.
- [ ] Recovery behavior is documented and tested.
- [ ] The frontend displays all active automation permissions.
- [ ] Emergency disable-all-automation is tested.
- [ ] Unit, integration, fuzz, and invariant tests pass.
- [ ] No unresolved critical or high-severity security issue remains.
- [ ] The selected smart-account framework and modules receive an independent security review before production use.

---

# Phase 20 — Other Post-MVP Extensions

These items must not be started until the production MVP and the relevant prior expansion phases are stable.

## Potential Extensions

### Keeper decentralization

- Multiple approved keepers.
- Keeper staking.
- Slashing.
- Execution auctions.
- Permissionless opportunity submission with bonded security.

### Portfolio improvements

- Risk-adjusted ranking.
- Volatility targeting.
- Rebalancing strategies.
- Drawdown controls.
- Correlation limits.
- Stablecoin diversification.

### Cross-chain research phase

Cross-chain functionality must be treated as a separate product because it introduces:

- Non-atomic settlement.
- Bridge risk.
- Inventory risk.
- Finality differences.
- Rebalancing requirements.
- Capital fragmentation.
- Additional accounting complexity.

## Post-MVP Entry Requirements

Post-MVP work may begin only when:

- [ ] Production MVP has operated for at least 90 days.
- [ ] No unresolved critical or high-severity security issue exists.
- [ ] Accounting reconciliation is stable.
- [ ] Withdrawal success rate meets the defined service objective.
- [ ] Strategy performance and failure rates are understood.
- [ ] The team has capacity for a new threat model and audit scope.

---

# 6. Global Definition of Done

A phase marked as finished must satisfy all of the following general conditions in addition to its phase-specific requirements.

## Engineering

- [ ] Code is merged into the protected main branch.
- [ ] Code is reviewed by at least one engineer other than the author.
- [ ] Compilation succeeds.
- [ ] Formatting and linting pass.
- [ ] CI passes.
- [ ] Required tests pass.
- [ ] Test coverage meets the phase threshold.
- [ ] No unresolved critical or high-severity defect exists.
- [ ] Documentation is updated.
- [ ] Deployment or migration scripts are included.
- [ ] Rollback or recovery behavior is documented.

## Smart-contract security

- [ ] Access control is tested.
- [ ] Reentrancy risk is reviewed.
- [ ] External calls are reviewed.
- [ ] Token approvals are minimized.
- [ ] Events provide sufficient auditability.
- [ ] State transitions are documented.
- [ ] Accounting invariants are tested.
- [ ] Upgrade and initialization safety are reviewed.
- [ ] Emergency controls are tested.

## Product

- [ ] Acceptance criteria are demonstrated.
- [ ] User-visible behavior matches the specification.
- [ ] Failure states are understandable.
- [ ] Financial calculations are reproducible.
- [ ] No feature relies on undocumented manual intervention.

## Operations

- [ ] Monitoring exists.
- [ ] Alerts exist.
- [ ] Logs include execution identifiers.
- [ ] Secrets are stored securely.
- [ ] Runbooks exist for likely failures.
- [ ] The phase output can be deployed reproducibly.

A phase must not be declared finished based only on compilation or the existence of code.

---

# 7. Critical System Invariants

The following invariants must remain true throughout development.

## Vault invariants

```text
user-owned assets
>=
recorded withdrawable assets
```

```text
one user's funds cannot satisfy another user's liabilities
```

```text
only the vault owner can initiate unrestricted withdrawal
```

## Arbitrage invariants

```text
successful arbitrage cannot reduce user principal
```

```text
route starts and ends with the same settlement token
```

```text
two-pool arbitrage contains exactly two swaps
```

```text
triangular arbitrage contains exactly three swaps
```

```text
final balance must cover flash-loan repayment and required profit
```

## Settlement invariants

```text
gross surplus
=
flash-loan premium
+ gas reimbursement
+ executor fee
+ protocol fee
+ net realized profit
```

```text
net realized profit
=
reinvestment amount
+ withdrawable amount
```

```text
each expense and fee is charged exactly once
```

## Grid invariants

```text
active grid capital
<=
authorized reinvestment capital
```

```text
a grid level cannot be filled more than once without an explicit reset
```

```text
strategy inventory cannot exceed the configured cap
```

```text
keeper cannot withdraw grid assets to an arbitrary address
```

## Administrative invariants

```text
administrator cannot directly seize user funds
```

```text
upgrades require authorized multisig and timelock
```

```text
pausing automation does not prevent owner withdrawals unless explicitly required for safety
```

```text
session keys cannot withdraw funds or expand their own permissions
```

---

# 8. Suggested Technology Stack

## Smart contracts

- Solidity.
- Foundry.
- OpenZeppelin Contracts.
- Slither.
- Echidna or Foundry invariant testing.
- Tenderly or equivalent simulation tooling.
- Multisig administration.
- Timelock controller.

## Backend

- TypeScript.
- Node.js.
- PostgreSQL.
- Redis.
- Viem.
- WebSocket RPC connections.
- Queue system for execution jobs.
- Structured logging.
- Metrics and alerting.

## Frontend

- Next.js.
- TypeScript.
- Viem or Wagmi.
- Wallet connection library.
- On-chain reads as the source of truth for balances.

## Infrastructure

- Docker.
- Managed PostgreSQL.
- Multiple RPC providers.
- Secret manager.
- Centralized logs.
- Metrics dashboard.
- Alerting service.
- CI/CD with protected deployment environments.

---

# 9. Recommended Initial MVP Configuration

This configuration should be finalized in Phase 0.

```text
Chain:
One low-cost, liquid EVM L2

Settlement token:
USDC

Vault model:
One EIP-1167 clone per user per chain

Arbitrage:
- Two-pool
- Triangular

Funding:
- User-funded by default
- Flash-loan-funded only when explicitly enabled by the user

Initial DEX adapters:
- One Uniswap V2-compatible DEX
- One Uniswap V3-compatible or second liquid DEX

Investment assets:
Three to five approved liquid assets

Grid strategy:
- Arithmetic grid first
- One quote asset
- Stop loss
- Take profit
- Expiration
- Maximum inventory

Automation:
Centralized approved keeper for MVP

Administration:
Multisig plus timelock

Withdrawals:
- Immediate idle-balance withdrawal
- Strategy exit
- Direct asset withdrawal where supported
```

---

# 10. Development Order Summary

```text
Mandatory order:
Smart-contract core must pass its completion gate before production backend, frontend, marketplace, or smart-account implementation.

Phase 0   Product definition and threat model
Phase 1   Repository, interfaces, and CI
Phase 2   Per-user vault and factory
Phase 3   DEX adapters and route validation
Phase 4   User-funded two-pool arbitrage
Phase 5   Triangular arbitrage
Phase 6   Flash-loan integration
Phase 7   Profit, gas, and fee settlement
Phase 8   Off-chain searcher and executor
Phase 9   Asset ranking and allocation
Phase 10  Grid trading
Phase 11  Backend and indexer
Phase 12  Frontend
Phase 13  Security hardening
Phase 14  Testnet beta
Phase 15  Mainnet limited beta
Phase 16  Production release
Phase 17  Additional same-chain arbitrage strategies
Phase 18  Governed strategy marketplace
Phase 19  Smart-account experience and session-key automation
Phase 20  Other post-MVP extensions
```

---

# 11. MVP Release Gate

The MVP may be considered complete only when all of the following are true:

- [ ] One user can deploy an isolated vault.
- [ ] The user can deposit and withdraw the settlement token.
- [ ] Two-pool arbitrage works atomically.
- [ ] Triangular arbitrage works atomically.
- [ ] Both arbitrage types support optional flash-loan funding.
- [ ] Flash-loan arbitrage is disabled by default.
- [ ] Only the vault owner can enable or disable flash-loan arbitrage.
- [ ] No flash loan can be initiated for a vault while the setting is disabled.
- [ ] Flash-loan principal and premium are repaid atomically.
- [ ] Failed arbitrage cannot reduce user principal.
- [ ] Gas reimbursement is capped and independently verifiable.
- [ ] Protocol and executor fees are correctly separated.
- [ ] Net profit is calculated correctly.
- [ ] Reinvestment percentage is user configurable.
- [ ] Reinvestment is limited to approved assets.
- [ ] Grid strategies can buy, sell, pause, expire, and exit.
- [ ] Users can withdraw idle balances during keeper downtime.
- [ ] User accounting matches actual on-chain balances.
- [ ] The keeper cannot withdraw funds.
- [ ] The administrator cannot directly seize funds.
- [ ] All critical invariants pass.
- [ ] External audit is complete.
- [ ] Testnet beta exit requirements are met.
- [ ] Mainnet limited-beta safeguards are active.
- [ ] Monitoring, alerting, reconciliation, and incident response are operational.

Until every item above is satisfied, the product must not be described as a finished production system.
