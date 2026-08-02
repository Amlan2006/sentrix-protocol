# Sentrix Protocol — Frontend Design Specification

## 1. Design Direction

Sentrix Protocol should use a premium, futuristic financial theme inspired by the supplied reference:

- Deep aubergine and near-black backgrounds
- Large editorial serif typography
- High-contrast financial values
- Rounded panels with soft glass treatment
- Fluid neon gradients
- Organic animated waves and particle surfaces
- Sparse borders and generous spacing
- Calm, deliberate animation

The interface should feel like institutional finance combined with experimental digital art. It must not resemble a generic exchange dashboard.

## 2. Brand Foundation

**Product:** Sentrix Protocol  
**Tagline:** Autonomous strategies. Protected capital.

Brand qualities:

- Intelligent
- Protective
- Precise
- Futuristic
- Premium
- Non-custodial

The main visual metaphor is capital flowing through markets as energy. Waves, particles, and gradient paths should represent liquidity, execution, strategy allocation, and risk boundaries.

## 3. Color System

### Backgrounds

```css
--bg-root: #120d15;
--bg-primary: #1a1220;
--bg-secondary: #24192b;
--bg-tertiary: #2b1f33;
--bg-elevated: rgba(43, 31, 51, 0.78);
--bg-overlay: rgba(13, 8, 17, 0.72);
```

### Text

```css
--text-primary: #f7f2f8;
--text-secondary: #b9aebd;
--text-muted: #817684;
--text-disabled: #5f5562;
--text-dark: #171118;
```

### Accent Colors

```css
--accent-lime: #c9ff4d;
--accent-green: #76ff56;
--accent-cyan: #42ddd4;
--accent-blue: #4a56ff;
--accent-violet: #8c4dff;
--accent-magenta: #e94898;
--accent-orange: #ff763b;
--accent-yellow: #ffe95c;
```

### Status Colors

```css
--success: #9eff68;
--warning: #ffd166;
--danger: #ff6b77;
--info: #6cb8ff;
```

### Primary Gradient

```css
--gradient-primary:
  linear-gradient(
    110deg,
    #ff7438 0%,
    #ffdf4d 22%,
    #a9ff4b 45%,
    #47e9bb 66%,
    #5364ff 84%,
    #8c47ff 100%
  );
```

Use gradients as focal highlights rather than page backgrounds. Keep most of the interface dark and neutral.

## 4. Typography

Use two font families.

### Editorial Serif

Recommended:

- Instrument Serif
- Cormorant Garamond
- DM Serif Display
- Bodoni Moda

Use for:

- Hero headings
- Large balances
- Strategy titles
- Major metrics
- Empty states

### Interface Sans

Recommended:

- Inter
- Geist
- Manrope
- IBM Plex Sans

Use for:

- Navigation
- Buttons
- Labels
- Tables
- Forms
- Tooltips
- Technical values

### Type Scale

```css
--font-display-hero: clamp(3.5rem, 8vw, 8rem);
--font-display-xl: clamp(2.75rem, 5vw, 5.5rem);
--font-display-lg: clamp(2.25rem, 4vw, 4rem);
--font-heading-xl: 2.5rem;
--font-heading-lg: 2rem;
--font-heading-md: 1.5rem;
--font-body-lg: 1.125rem;
--font-body: 1rem;
--font-body-sm: 0.875rem;
--font-label: 0.75rem;
```

Large balances should use serif typography and tabular numerals where supported.

## 5. Layout System

Use a 12-column desktop grid.

```css
max-width: 1600px;
margin: 0 auto;
padding-inline: 32px;
column-gap: 24px;
```

### Spacing

```css
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-20: 80px;
```

### Radius

```css
--radius-sm: 12px;
--radius-md: 18px;
--radius-lg: 28px;
--radius-xl: 36px;
--radius-pill: 999px;
```

### Card Treatment

```css
.card {
  background: rgba(40, 28, 47, 0.78);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 28px;
  backdrop-filter: blur(20px);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.05),
    0 24px 80px rgba(0, 0, 0, 0.25);
}
```

## 6. Application Navigation

Primary navigation:

- Overview
- Vault
- Arbitrage
- Grid Strategies
- Marketplace
- Portfolio
- Activity
- Settings

Utility controls:

- Network selector
- Smart-account status
- Wallet connection
- Notifications
- Emergency pause
- User menu

Prefer a clean top navigation on desktop. Use bottom navigation on mobile.

## 7. Landing Page

### Hero

Headline:

```text
Autonomous strategies.
Protected capital.
```

Description:

```text
Deploy a non-custodial vault that discovers arbitrage,
settles profit, and reinvests through automated strategies.
```

Actions:

- Launch App
- Explore Strategies

Hero visual:

- Animated neon particle surface
- Slow gradient movement
- Pointer-responsive displacement
- Capital-flow particles
- Dark aubergine background
- Soft parallax

Sections:

1. Non-custodial vaults
2. Arbitrage execution
3. Profit settlement
4. Automated reinvestment
5. Grid strategies
6. Smart accounts
7. Strategy marketplace
8. Security model

## 8. Overview Dashboard

### Main Balance Panel

Display:

- Total vault value
- Available balance
- Active strategy capital
- Withdrawable profit
- Unrealized PnL
- Daily and monthly change

Design:

- Large serif balance
- Animated capital wave underneath
- Small summary metrics along the bottom
- Profit or loss color used only as an accent

Example:

```text
TOTAL VAULT VALUE

$31,439.12

+4.82% this month
```

### Strategy Cards

Cards for:

- Arbitrage
- Flash-loan mode
- Grid trading
- Marketplace strategies

Each card should show:

- Enabled or disabled
- Allocated capital
- Realized PnL
- Last execution
- Risk profile

## 9. Vault Page

Display:

- Vault address
- Smart-account address
- Owner address
- Settlement token
- Available capital
- Active strategy capital
- Withdrawable profit

Actions:

- Deposit
- Withdraw
- Full exit
- Emergency exit
- Copy address
- View on explorer

Deposit form:

```text
ENTER AMOUNT

$500.00

$100  $250  $500  MAX
```

The amount should use a large serif input with a full-width rounded CTA.

## 10. Arbitrage Page

### Summary Metrics

- Total arbitrage profit
- Executions
- Success rate
- Average net profit
- Gas spent
- Flash-loan fees

### Strategy Controls

Cards for:

- Two-pool arbitrage
- Triangular arbitrage
- Stablecoin arbitrage
- Fee-tier arbitrage
- Multi-DEX arbitrage
- Liquid-staking-token arbitrage

Each card includes:

- Enable toggle
- Risk level
- Maximum trade size
- Minimum net profit
- Funding mode
- Last execution

### Flash-Loan Control

Flash loans must be visibly optional.

```text
Flash-loan arbitrage
Use borrowed capital for atomic arbitrage execution.

[ Disabled / Enabled ]
```

When enabled, show:

- Maximum flash-loan amount
- Approved provider
- Maximum premium
- Minimum expected net profit
- Session-key permission status

### Route Visualization

Display routes as connected animated token nodes:

```text
USDC → WETH → WBTC → USDC
```

The active path should light up during execution.

## 11. Grid Strategy Page

Inputs:

- Asset
- Allocation
- Lower price
- Upper price
- Grid count
- Arithmetic or geometric mode
- Stop loss
- Take profit
- Expiration
- Compounding
- Maximum inventory

Visualization:

- Price chart
- Buy levels
- Sell levels
- Current market price
- Filled levels
- Pending levels
- Average entry
- Stop-loss boundary

Use glow only for active or recently filled levels.

## 12. Strategy Marketplace

The marketplace lists protocol-approved strategies.

Each strategy card shows:

- Strategy name
- Developer
- Risk score
- Supported assets
- Historical return
- Maximum drawdown
- Strategy fee
- Audit status
- Active users
- Version

Example:

```text
Stable Triangle

Conservative stablecoin arbitrage

30D Return        +3.8%
Max Drawdown      -0.4%
Risk              Low
Developer Fee     5% of profit
Audit             Verified
```

Strategy detail pages include:

- Description
- Requested permissions
- Contract address
- Code hash
- Audit report
- Backtest
- Live performance
- Fees
- Risk assumptions
- Version history
- Allocation controls

Activation must show a human-readable permission summary before confirmation.

## 13. Smart Account Page

Display:

- Smart-account address
- Owner wallet
- Session keys
- Paymaster status
- Daily spending limit
- Recovery configuration
- Last automation execution

Each session-key card shows:

- Key identifier
- Status
- Expiration
- Allowed contracts
- Allowed functions
- Daily limit
- Flash-loan permission
- Grid permission
- Last used
- Revoke action

Always display:

```text
This session key cannot withdraw funds or change ownership.
```

## 14. Activity Page

Every execution should have a transparent receipt.

Arbitrage receipt fields:

- Route
- Starting capital
- Borrowed amount
- Flash-loan premium
- Gross proceeds
- Gas reimbursement
- Executor fee
- Protocol fee
- Net profit
- Reinvested amount
- Withdrawable amount
- Transaction hash
- Block number
- Execution duration

Statuses:

```text
Simulating
Submitting
Pending
Confirmed
Reverted
Expired
```

## 15. Buttons

### Primary

```css
background: #f6f1f7;
color: #171118;
border-radius: 999px;
height: 56px;
padding-inline: 28px;
font-weight: 600;
```

Hover:

- Scale to 1.015
- Soft glow
- Arrow moves 4px right

### Accent

```css
background: var(--gradient-primary);
color: #171118;
```

### Secondary

```css
background: rgba(255, 255, 255, 0.03);
border: 1px solid rgba(255, 255, 255, 0.08);
color: var(--text-primary);
```

## 16. Inputs and Toggles

Amount inputs should be dominant.

```css
.amount-input {
  font-family: var(--font-serif);
  font-size: clamp(3rem, 7vw, 6rem);
  background: transparent;
  border: 0;
  color: var(--text-primary);
}
```

Standard inputs:

- Minimum height: 52px
- Radius: 16px
- Dark translucent background
- Clear focus ring
- Inline validation

Enabled toggles should use a lime-to-green gradient with a soft glow.

## 17. Motion System

### Principles

Motion should explain:

- State
- Flow
- Priority
- Execution
- Confirmation
- Risk

Use slow ambient motion and fast interaction feedback.

### Durations

```css
--motion-instant: 100ms;
--motion-fast: 180ms;
--motion-standard: 280ms;
--motion-slow: 500ms;
--motion-ambient: 8s;
```

### Easing

```css
--ease-standard: cubic-bezier(0.22, 1, 0.36, 1);
--ease-enter: cubic-bezier(0.16, 1, 0.3, 1);
--ease-exit: cubic-bezier(0.7, 0, 0.84, 0);
--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
```

## 18. Ambient Visual Animations

### Particle Wave

Use WebGL or Canvas, not DOM particles.

Behavior:

- 80–140 horizontal particle lines
- Slow sine-wave deformation
- Gradient moving across the surface
- Mild pointer displacement
- Market activity affects amplitude
- Profit increases green and yellow intensity
- Risk increases orange and magenta intensity

Recommended:

- React Three Fiber
- Three.js
- Custom shader
- PixiJS
- Canvas fallback

### Gradient Orb

Use for:

- Landing hero
- Empty portfolio
- Smart-account onboarding
- Strategy activation

Behavior:

- Slow morphing
- 10–16 second loop
- Subtle grain
- Gradient rotation
- Pointer parallax

### Noise Layer

```css
opacity: 0.025;
mix-blend-mode: soft-light;
```

## 19. Functional Animations

### Page Transition

- Opacity: 0 to 1
- Translate Y: 12–20px to 0
- Duration: 240–320ms

### Card Entrance

- Opacity: 0 to 1
- Translate Y: 16px to 0
- Stagger: 40ms

### Number Updates

- Animate changed digits only
- Preserve decimal alignment
- Duration: 500–900ms

### Deposit Flow

```text
Amount entered
→ CTA activates
→ wallet confirmation
→ pending pulse
→ success gradient expands
→ balance updates
```

### Arbitrage Execution

1. Route nodes appear
2. Active route brightens
3. Capital particle moves through each swap
4. Flash-loan node appears when enabled
5. Repayment path closes
6. Profit particle returns to the vault
7. Profit counts upward
8. Allocation splits into withdrawable and reinvested balances

The animation must reflect real transaction state.

### Grid Execution

When a level fills:

- Grid line pulses
- Capital particle moves between assets
- Filled level changes from outline to solid
- Realized PnL updates

### Strategy Activation

- Permission summary slides upward
- Requested permissions highlight sequentially
- Confirmation activates the strategy
- Strategy card gains a subtle animated edge

## 20. Microinteractions

Hover:

- Card lifts 2–4px
- Border opacity increases
- Gradient shifts toward pointer
- CTA arrow moves slightly

Press:

- Scale to 0.985
- Duration: 100ms

Focus:

```css
outline: 2px solid rgba(201, 255, 77, 0.8);
outline-offset: 3px;
```

Copy address:

- Copy icon changes to check
- Text changes to “Copied”
- Reverts after 1.5 seconds

## 21. Charts

Style:

- Dark transparent background
- Minimal axes
- Muted labels
- Fine grid lines
- Gradient area fills
- White primary line
- Lime for realized gains
- Orange or magenta for risk and loss
- Glass tooltip

Required charts:

- Vault value
- Realized versus unrealized PnL
- Arbitrage profit over time
- Gas and fee breakdown
- Strategy allocation
- Grid execution history
- Drawdown
- Marketplace strategy performance

Use a waterfall chart for:

```text
Gross arbitrage
- flash-loan fee
- gas
- executor fee
- protocol fee
= net profit
```

## 22. Responsive Design

### Desktop

- Full navigation
- Multi-column layout
- Large ambient visuals
- Side-by-side forms and previews

### Tablet

- Eight-column layout
- Reduced hero type
- Two-column cards
- Collapsible navigation

### Mobile

- Single-column layout
- Bottom navigation
- Sticky primary CTA
- Full-width amount inputs
- Reduced particle density
- Simplified route visualization

Mobile navigation:

- Overview
- Vault
- Trade
- Strategies
- Profile

## 23. Accessibility

Requirements:

- WCAG AA contrast
- Keyboard navigation
- Visible focus
- Reduced-motion support
- Screen-reader labels
- Semantic headings
- Input-linked errors
- No color-only status indicators
- Minimum 44px targets

Reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Replace particle animation with static gradient artwork when reduced motion is enabled.

## 24. Performance Requirements

- Lighthouse performance target: 90+
- Lazy-load WebGL visuals
- Use Canvas or WebGL instead of DOM particles
- Pause ambient animation in hidden tabs
- Reduce detail on low-power devices
- Use route-level code splitting
- Avoid continuous React state updates for animation
- Limit backdrop blur on mobile

## 25. Recommended Stack

```text
Framework: Next.js
Language: TypeScript
Styling: Tailwind CSS with CSS variables
Primitives: Radix UI
Motion: Framer Motion
Charts: Visx, Recharts, or custom SVG
WebGL: React Three Fiber / Three.js
Wallet: Wagmi + Viem
State: Zustand or TanStack Query
Forms: React Hook Form + Zod
Testing: Vitest, React Testing Library, Playwright
```

## 26. Component Structure

```text
src/
├── app/
│   ├── page.tsx
│   ├── overview/
│   ├── vault/
│   ├── arbitrage/
│   ├── grid/
│   ├── marketplace/
│   ├── portfolio/
│   ├── activity/
│   └── settings/
├── components/
│   ├── layout/
│   ├── visuals/
│   │   ├── ParticleWave.tsx
│   │   ├── GradientOrb.tsx
│   │   ├── CapitalFlow.tsx
│   │   └── NoiseOverlay.tsx
│   ├── vault/
│   ├── arbitrage/
│   ├── grid/
│   ├── marketplace/
│   ├── smart-account/
│   ├── charts/
│   └── ui/
├── hooks/
├── lib/
├── styles/
├── types/
└── animations/
```

## 27. Dashboard Composition

```text
┌──────────────────────────────────────────────────────────────────┐
│ SENTRIX      Overview  Vault  Arbitrage  Grid  Marketplace      │
│                                      Network  Smart Account       │
├──────────────────────────────────────────┬───────────────────────┤
│ TOTAL VAULT VALUE                        │ QUICK ACTION           │
│                                          │                       │
│ $31,439.12                               │ Deposit               │
│ +4.82% this month                        │ Withdraw              │
│                                          │ Configure Strategy    │
│ [Animated capital wave]                  │                       │
├─────────────────────┬────────────────────┴───────────────────────┤
│ ARBITRAGE PROFIT    │ ACTIVE STRATEGIES                          │
│ $1,482.20           │ Two-pool       Active                      │
│                     │ Triangular     Active                      │
│                     │ Flash loan     Disabled                    │
├─────────────────────┴────────────────────────────────────────────┤
│ RECENT EXECUTIONS                                                │
│ USDC → WETH → USDC          +$42.18       Confirmed             │
│ USDC → WETH → WBTC → USDC   +$73.09       Confirmed             │
└──────────────────────────────────────────────────────────────────┘
```

## 28. Design Completion Requirements

The frontend design phase is finished only when:

- [ ] Desktop, tablet, and mobile layouts are defined.
- [ ] The dark aubergine theme is consistent.
- [ ] Typography roles are consistent.
- [ ] Every core page has an approved wireframe.
- [ ] Every core page has a high-fidelity design.
- [ ] Motion specifications exist for critical flows.
- [ ] Reduced-motion behavior is implemented.
- [ ] Particle-wave visuals meet performance targets.
- [ ] Financial values use consistent formatting.
- [ ] Estimated, unrealized, and realized values are clearly distinguished.
- [ ] Flash-loan mode is visibly optional.
- [ ] Smart-account permissions are human-readable.
- [ ] Marketplace risk and audit states are visible.
- [ ] Withdrawal remains accessible during automation failures.
- [ ] Accessibility checks pass.
- [ ] Responsive layouts pass visual regression tests.
- [ ] Core journeys pass Playwright tests.
- [ ] Lighthouse targets are met.

## 29. Final Principle

The interface must make complex automated trading understandable without hiding risk or security details.

```text
Capital is protected.
Automation is restricted.
Profit is measurable.
Risk is configurable.
Every action is transparent.
```
