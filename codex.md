# Sentrix Protocol — Engineering Guidelines

These guidelines apply to all development work in the Sentrix Protocol repository.

They are intended to keep the codebase secure, maintainable, testable, and aligned with the approved project scope.

---

## 1. Scope Discipline

- Implement only the functionality that has been discussed and approved.
- Do not add speculative features for future phases.
- Follow the YAGNI principle: build only what is currently required.
- Do not introduce abstractions, modules, services, contracts, routes, or database entities without an immediate use.
- Do not begin backend, frontend, or smart-account work before the relevant smart-contract phase is complete.
- Do not expand the scope to cross-chain functionality unless it is approved as a separate phase.

---

## 2. Implementation Plan First

Before implementing any new feature:

1. Create an implementation plan.
2. Divide the work into clear phases.
3. Explain:
   - Why the feature is needed
   - The intended behavior
   - The complete flow
   - The mental model
   - Smart-contract impact
   - Backend impact
   - Database impact
   - Frontend impact
   - Security considerations
   - Error cases
   - Testing requirements
   - Completion requirements
4. Save the plan under:

```text
implementation_plans/
```

Use a descriptive file name:

```text
implementation_plans/
├── per_user_vault_implementation.md
├── triangular_arbitrage_implementation.md
├── flash_loan_arbitrage_implementation.md
├── profit_settlement_implementation.md
└── grid_strategy_implementation.md
```

After writing the implementation plan:

- Stop before implementation.
- Ask the project owner to review the plan.
- Apply requested revisions.
- Begin implementation only after explicit approval.

---

## 3. Smart-Contract-First Rule

The smart-contract layer is the source of truth for:

- User ownership
- Vault balances
- Deposits
- Withdrawals
- Arbitrage permissions
- Flash-loan permissions
- Strategy permissions
- Profit settlement
- Fees
- Reinvestment allocations
- Grid capital
- Emergency controls

Backend and frontend code must not attempt to replace or bypass on-chain validation.

Before implementing a dependent backend or frontend feature:

- Confirm the relevant contract interface is stable.
- Confirm required events exist.
- Confirm contract tests pass.
- Confirm the accounting model is finalized.
- Confirm the feature is approved in the implementation plan.

---

## 4. Reuse Existing Components

Before creating a new:

- Contract
- Library
- Adapter
- Service
- Controller
- Route
- Middleware
- Model
- Schema
- Utility
- React component
- Hook
- Type
- Test helper

Check whether an equivalent implementation already exists.

If existing logic can be reused safely:

- Reuse it directly.
- Refactor shared behavior into a common module.
- Avoid copying and modifying nearly identical code.
- Keep protocol-specific behavior isolated behind interfaces.

Examples:

```text
Shared DEX behavior      -> IDexAdapter
Shared route validation  -> RouteValidator
Shared fee calculations  -> ProfitMath
Shared database queries  -> Repository or service helper
Shared UI controls       -> components/ui
```

---

## 5. Remove Stale Code

Do not preserve obsolete logic after changing functionality.

When replacing or modifying a feature:

- Delete unused routes.
- Delete unused services.
- Delete unused contracts.
- Delete deprecated models.
- Delete dead configuration.
- Delete unused imports.
- Delete old tests that no longer represent valid behavior.
- Delete compatibility code unless compatibility is explicitly required.
- Remove commented-out implementation code.

Do not drag stale code through later phases.

Version history is available through Git.

---

## 6. Repository Structure

Follow the existing repository structure.

Suggested structure:

```text
contracts/
├── factory/
├── vault/
├── arbitrage/
├── settlement/
├── strategies/
├── adapters/
├── oracle/
├── execution/
├── security/
├── interfaces/
└── libraries/

backend/
├── routes/
├── controllers/
├── services/
├── models/
├── repositories/
├── middleware/
├── validators/
├── types/
├── utils/
└── tests/

frontend/
├── app/
├── components/
├── hooks/
├── services/
├── state/
├── types/
└── tests/

implementation_plans/
docs/
scripts/
deployments/
```

Do not create new top-level folders without a clear architectural reason.

---

## 7. Database Rules

The primary database for Sentrix Protocol is PostgreSQL.

If data must be persisted:

- Define the database schema before using it.
- Store schema definitions in the appropriate backend model or schema folder.
- Add a migration.
- Add constraints.
- Add indexes where required.
- Document enums and versioned fields.
- Add tests for database behavior.

Suggested location:

```text
backend/models/
```

or the repository's established equivalent.

Every persistent entity must have an explicit schema definition.

Examples:

- Users
- Vaults
- Arbitrage executions
- Flash-loan executions
- Profit settlements
- Grid strategies
- Positions
- Session-key metadata
- Chain sync state

Do not store temporary execution state in PostgreSQL when Redis is more appropriate.

Redis may be used for:

- Pool-state cache
- Job queues
- Nonce locks
- Rate limiting
- Short-lived opportunities
- Distributed execution locks

Redis must not be treated as the source of truth.

---

## 8. Database Migrations

Every schema change must include:

- A forward migration
- A rollback strategy where practical
- Updated model definitions
- Updated tests
- Updated documentation

Do not manually alter production tables.

Migration names must be descriptive:

```text
add_flash_loan_enabled_to_vaults
create_profit_settlements
add_route_version_to_arbitrage_routes
```

---

## 9. Model Documentation

All model fields that are not immediately obvious must include documentation.

Enums must be documented.

Example:

```python
class ArbitrageType(str, Enum):
    """
    Supported arbitrage execution types.

    TWO_POOL:
        Settlement token is swapped to an intermediate token and
        returned to the settlement token using a second pool.

    TRIANGULAR:
        Settlement token is routed through two intermediate assets
        before returning to the settlement token.
    """

    TWO_POOL = "two_pool"
    TRIANGULAR = "triangular"
```

Versioned fields must include comments in the schema definition.

Example:

```python
route_version: str = Field(
    ...,
    description=(
        "Version of the serialized arbitrage route format. "
        "Examples: arb_route.v1, arb_route.v2. "
        "See README.md for compatibility rules."
    ),
)
```

Version values such as:

```text
arb_route.v1
arb_route.v2
grid_config.v1
profit_settlement.v1
```

must also be documented in the README.

---

## 10. Route Naming

Use descriptive route paths.

Examples:

```text
GET    /get_arbitrage_events
POST   /create_arbitrage_configuration
PATCH  /update_arbitrage_configuration
POST   /enable_flash_loan_arbitrage
POST   /disable_flash_loan_arbitrage
GET    /get_profit_settlements
POST   /create_grid_strategy
PATCH  /update_grid_strategy
POST   /pause_grid_strategy
POST   /exit_grid_strategy
```

Route names must clearly communicate the operation.

Do not use vague paths such as:

```text
/process
/action
/data
/update
/run
```

Follow the repository's existing routing convention consistently.

---

## 11. Lean Routes and Controllers

Routes and controllers must remain lean.

They may handle:

- Request parsing
- Authentication
- Authorization
- Input validation
- Calling the correct service
- Mapping service errors to HTTP responses
- Swagger/OpenAPI documentation

They must not contain:

- Business logic
- Arbitrage calculations
- Profit calculations
- Complex database logic
- Blockchain transaction logic
- Route optimization
- Reconciliation logic

Move business logic into services.

Example:

```text
Route
  -> validates request
  -> calls service
  -> maps result to response
```

---

## 12. Service Layer

Services contain application business logic.

Examples:

```text
ArbitrageDetectionService
ArbitrageExecutionService
FlashLoanService
ProfitSettlementService
GridStrategyService
VaultService
PortfolioAllocationService
SmartAccountService
StrategyMarketplaceService
ReconciliationService
```

If a service file becomes too large:

- Split it by responsibility.
- Create separate classes.
- Create separate files.
- Preserve one clear responsibility per service.

Example:

```text
arbitrage/
├── opportunity_detection_service.py
├── route_simulation_service.py
├── trade_size_optimization_service.py
├── execution_submission_service.py
└── execution_reconciliation_service.py
```

Do not create generic service files containing unrelated functionality.

---

## 13. Error Handling

Every implemented functionality must define:

- Validation errors
- Authorization errors
- Not-found errors
- Conflict errors
- Blockchain errors
- RPC errors
- Simulation errors
- Database errors
- External protocol errors
- Internal errors

Routes must not return HTTP 200 or 201 for failed operations.

Use appropriate status codes.

Recommended mapping:

```text
400 Bad Request
Invalid input or malformed parameters

401 Unauthorized
Missing or invalid authentication

403 Forbidden
Authenticated user lacks permission

404 Not Found
Requested resource does not exist

409 Conflict
State conflict, duplicate request, or invalid transition

422 Unprocessable Entity
Valid request format but invalid business condition

429 Too Many Requests
Rate limit exceeded

502 Bad Gateway
RPC, bundler, DEX quote, or external service failure

503 Service Unavailable
Required service temporarily unavailable

500 Internal Server Error
Unexpected internal failure
```

Use a consistent error shape:

```json
{
  "error": {
    "code": "FLASH_LOAN_DISABLED",
    "message": "Flash-loan arbitrage is disabled for this vault.",
    "details": {
      "vault_id": "..."
    }
  }
}
```

Do not expose:

- Private keys
- Secrets
- Internal stack traces
- Database credentials
- Raw provider credentials
- Sensitive infrastructure details

---

## 14. Swagger and OpenAPI

Every route must include detailed Swagger/OpenAPI documentation.

Documentation must explain:

- What the route does
- Authentication requirements
- Authorization requirements
- Request parameters
- Request body
- Response format
- Error responses
- Side effects
- Blockchain interactions
- Idempotency behavior
- Relevant state transitions

Example documentation should include:

```text
Summary
Description
Request schema
Success response
400 response
401 response
403 response
404 response
409 response
422 response
500/502/503 responses
```

Do not add undocumented routes.

---

## 15. Validation

Validate all external input before use.

Validate:

- Ethereum addresses
- Chain identifiers
- Token addresses
- Vault ownership
- Token amounts
- Decimal precision
- Basis points
- Deadlines
- Nonces
- Route versions
- Arbitrage types
- Strategy identifiers
- Grid ranges
- Grid counts
- Slippage values
- Reinvestment percentages
- Flash-loan flags
- Risk limits

Never trust:

- Frontend validation
- Keeper payloads
- Searcher output
- Database values
- External API responses
- Blockchain event data without confirmation rules

---

## 16. Testing Requirements

Every new functionality must include tests.

Required test categories depend on the component.

### Smart Contracts

- Unit tests
- Integration tests
- Fork tests
- Fuzz tests
- Stateful invariant tests
- Access-control tests
- Reentrancy tests
- Failure-path tests
- Accounting tests

### Backend

- Unit tests
- Service tests
- Route tests
- Validation tests
- Database tests
- Error-response tests
- Idempotency tests
- Reconciliation tests

### Frontend

- Component tests
- Form validation tests
- Contract interaction tests
- Error-state tests
- Loading-state tests
- End-to-end tests

Do not mark a functionality complete until its tests pass.

---

## 17. Test Environment

Before running backend tests:

```bash
conda activate mm-bot
```

If the environment name changes for Sentrix Protocol, update this guideline and the README together.

Tests must be reproducible from documented commands.

Example:

```bash
conda activate mm-bot
pytest
```

Smart-contract tests:

```bash
forge test
forge test --match-path test/invariant/*
forge test --fork-url $RPC_URL
```

Frontend tests:

```bash
npm run test
npm run test:e2e
```

---

## 18. Completion Criteria

A feature is complete only when:

- The implementation plan is approved.
- The code follows the repository pattern.
- Existing components were reused where appropriate.
- Stale code was removed.
- Models and migrations were added where required.
- Services contain the business logic.
- Routes remain lean.
- Swagger documentation is complete.
- Errors return appropriate status codes.
- Tests were added.
- Tests pass.
- Documentation is updated.
- No unrelated functionality was introduced.
- No unresolved critical or high-severity security issue remains.

Compilation alone does not mean a feature is finished.

---

## 19. Code Quality

Follow established programming best practices.

Code should be:

- Minimal
- Readable
- Typed
- Testable
- Modular
- Deterministic where possible
- Explicit about financial calculations
- Explicit about permissions
- Consistent with the repository style

Avoid:

- Duplicate logic
- Hidden side effects
- Deep nesting
- Large functions
- Large multipurpose classes
- Magic values
- Unbounded loops
- Unnecessary abstractions
- Premature optimization
- Premature generalization

---

## 20. Complexity and Performance

Prefer efficient algorithms and data access patterns.

Avoid O(n²) behavior when data may scale.

Examples of risky patterns:

- Nested pool comparisons over all pools
- Repeated database queries inside loops
- Repeated RPC calls per item
- Recomputing token graphs on every request
- Loading complete historical datasets into memory

Prefer:

- Indexed database queries
- Batch RPC calls
- Multicall
- Cached pool state
- Precomputed adjacency lists
- Sets and maps for lookup
- Pagination
- Background processing
- Bounded concurrency
- Bulk database operations

O(n²) logic is acceptable only when:

- Input size is strictly bounded.
- The bound is documented.
- The performance impact is measured.
- A simpler implementation is preferable for the current scope.

---

## 21. Blockchain Interaction Rules

All transaction flows must include:

- Chain validation
- Contract-address validation
- Simulation before submission where applicable
- Deadline
- Slippage limit
- Gas limit
- Replay protection
- Transaction-state tracking
- Confirmation policy
- Reorg handling
- Error mapping

Do not consider a submitted transaction successful until it has reached the required confirmation state.

Store:

- Transaction hash
- Chain ID
- Block number
- Block hash
- Confirmation state
- Revert reason where available
- Request identifier
- Vault identifier
- Route version

---

## 22. Financial Calculation Rules

Financial calculations must be:

- Deterministic
- Unit-tested
- Integer-safe
- Explicit about decimals
- Explicit about rounding
- Reproducible

Never use floating-point arithmetic for token accounting.

Track separately:

- Principal
- Gross profit
- Flash-loan premium
- Gas reimbursement
- Executor fee
- Protocol fee
- Net profit
- Reinvestment amount
- Withdrawable amount
- Grid capital
- Realized PnL
- Unrealized PnL

Every amount must identify:

- Token
- Decimals
- Raw integer value
- Display value

---

## 23. Smart-Contract Rules

Smart contracts must:

- Follow checks-effects-interactions.
- Use safe token-transfer methods.
- Validate callback callers.
- Validate flash-loan initiators.
- Prevent arbitrary external calls.
- Restrict adapters and routers.
- Restrict tokens.
- Enforce deadlines.
- Enforce minimum outputs.
- Enforce minimum profit.
- Protect user withdrawals.
- Emit sufficient events.
- Use custom errors where appropriate.
- Avoid unbounded storage iteration.
- Avoid unnecessary storage writes.
- Document storage layout when upgradeable.

A keeper, admin, executor, strategy, or session key must never receive unrestricted withdrawal authority.

---

## 24. Flash-Loan Rules

Flash-loan arbitrage is:

- Optional per user
- Disabled by default
- Enabled only by the vault owner
- Valid only for approved providers
- Valid only for approved settlement assets
- Subject to user-defined limits

Before execution, verify:

- Arbitrage is enabled.
- Flash loans are enabled.
- Provider is approved.
- Asset is approved.
- Amount is within limits.
- Route is valid.
- Expected net profit satisfies the user threshold.
- Full transaction simulation succeeds.

The transaction must revert if:

- Principal cannot be repaid.
- Premium cannot be repaid.
- Minimum profit is not reached.
- Route validation fails.
- Callback validation fails.

---

## 25. API Idempotency

Routes that may create duplicate financial actions must support idempotency.

Examples:

- Arbitrage execution request
- Grid execution request
- Strategy activation
- Deposit indexing
- Withdrawal indexing
- Profit settlement indexing

Use:

- Idempotency keys
- Unique database constraints
- Execution nonces
- Transaction hashes
- Request identifiers

Retries must not create duplicate financial records.

---

## 26. Logging

Use structured logs.

Include:

- Request ID
- User ID
- Vault address
- Chain ID
- Transaction hash
- Route version
- Strategy ID
- Execution ID
- Service name
- Error code

Do not log:

- Private keys
- Seed phrases
- Raw session-key secrets
- Access tokens
- Database passwords
- Provider secrets

---

## 27. Security Review

Before merging security-sensitive functionality, review:

- Access control
- Ownership
- Vault isolation
- Arbitrary calls
- Token approvals
- Reentrancy
- Flash-loan callback authentication
- Oracle freshness
- Slippage
- Replay protection
- Rounding
- Fee accounting
- Withdrawal behavior
- Emergency controls
- Upgrade permissions

Security-sensitive changes require additional review.

---

## 28. README Maintenance

Update the README when adding:

- New routes
- New environment variables
- New migrations
- New route versions
- New enums
- New contract addresses
- New deployment commands
- New test commands
- New services
- New external dependencies

Document versioned formats clearly.

Example:

```text
arb_route.v1
- Supports exactly two-pool and triangular routes
- Uses ordered SwapStep objects
- Route starts and ends with the settlement token
```

---

## 29. Dependency Rules

Before adding a dependency:

- Confirm existing dependencies cannot solve the problem.
- Confirm the package is maintained.
- Confirm its license is acceptable.
- Confirm it does not introduce unnecessary scope.
- Pin the version.
- Add tests around critical behavior.
- Document why it is needed.

Avoid dependencies for trivial utilities.

---

## 30. Pull Request Requirements

Every pull request must include:

- Summary
- Approved implementation-plan reference
- Scope
- Files changed
- Testing performed
- Security considerations
- Database migration notes
- Contract deployment impact
- API changes
- Documentation updates
- Known limitations

Do not mix unrelated features in one pull request.

---

## 31. Final Working Principle

For every task:

```text
Understand the requirement
-> write the implementation plan
-> request review
-> revise the plan
-> implement only the approved scope
-> reuse existing components
-> remove stale code
-> keep routes lean
-> place logic in services
-> document schemas and routes
-> handle errors explicitly
-> write tests
-> verify completion requirements
```

The objective is not to produce the most code.

The objective is to produce the smallest secure, correct, maintainable implementation required for the current Sentrix Protocol phase.
