## Purpose

Defines the four Home tab states authored on `📱 02 Home & Dashboard`: default,
empty, loading and over-budget alert.

Every requirement below was checked against the screen's **sibling annotation
frame**, read on 2026-09-09: `52:362`, `52:537`, `52:630` and `57:612`. Where an
annotation contradicts the frame, the annotation states the rule and the frame
shows one instance of it. Two requirements here exist only because the
annotations were read — the recent-list cap and the safe-to-spend formula — and
both contradict code that was already merged.

## ADDED Requirements

### Requirement: Home renders the default dashboard from node 52:2

The Home tab SHALL provide a default dashboard state matching Figma node `52:2`
and its sibling annotation frame `52:362`.

#### Scenario: Default Home composition
- **WHEN** the default Home state is rendered
- **THEN** the screen uses `AppBar`, `BalanceCard`, `BottomNav`, `BudgetCard`,
  `DateGroupHeader`, `IconButton`, `SectionHeader` and `TransactionRow`
- **AND** the Home tab is the active bottom navigation destination

#### Scenario: The budgets section is present
- **WHEN** the default Home state is rendered and budgets exist
- **THEN** a `SectionHeader` carrying an action introduces a budgets section
- **AND** that section renders `BudgetCard` entries as authored at `52:125` and
  `52:143`

#### Scenario: Quick actions follow the authored set
- **WHEN** the quick-actions row is rendered
- **THEN** it offers Add, Transfer, Budgets and Goals in that order, as authored
  at `52:66`, `52:80`, `52:93` and `52:105`
- **AND** an action whose destination does not exist yet is rendered in a
  disabled state rather than omitted or wired to a placeholder

### Requirement: Home's recent list is capped at five rows

The recent-transactions list on Home SHALL show at most five entries.

Annotation `52:362` states: *"Recent list is capped at 5 rows client-side."*
Frame `52:2` draws four rows. The cap is the rule; the frame is one instance of
it. Merged code set the cap to four and cited the frame in a comment, which is
how a drawing was mistaken for a specification.

#### Scenario: More entries than the cap
- **WHEN** more than five recent entries are available
- **THEN** exactly five are rendered
- **AND** the section offers a way to reach the full list

#### Scenario: Fewer entries than the cap
- **WHEN** fewer than five recent entries are available
- **THEN** every available entry is rendered and no placeholder rows are added

### Requirement: Safe to spend subtracts committed budgets

The balance card's safe-to-spend figure SHALL be the total balance minus the sum
of committed budget limits for the current period, computed in `lib/app` where
the coverage gate reaches it.

Annotation `52:362` states: *"safe-to-spend = balance minus committed budgets
minus scheduled bills to period end."* Merged code passed the total balance
through unchanged, commented "there is no budget feature yet" — true when it was
written and false now.

#### Scenario: No budgets are set
- **WHEN** no budget exists for the current period
- **THEN** safe to spend equals the total balance

#### Scenario: Budgets are set
- **WHEN** budgets exist for the current period
- **THEN** safe to spend is the total balance minus the sum of each budget's
  **unspent** remainder

#### Scenario: Spend is not subtracted twice
- **WHEN** a budget has already been partly spent
- **THEN** only its unspent remainder is subtracted from the balance
- **AND** the amount already spent is not subtracted again, because it has
  already left the balance

The annotation's two terms are parallel and both name *future* outflows: budget
money not yet spent, and bills not yet due. Subtracting a whole limit would
deduct the spent part a second time — a fully spent budget of 5m would cost the
user 10m of headroom.

#### Scenario: An overspent budget does not return headroom
- **WHEN** a budget's spend has passed its limit
- **THEN** its remainder contributes zero rather than a negative amount
- **AND** safe to spend does not rise because a budget was exceeded

#### Scenario: A foreign-currency budget is skipped
- **WHEN** a budget's currency differs from the wallet's
- **THEN** it is excluded from the subtraction rather than added across
  currencies

#### Scenario: Scheduled bills are not implemented
- **WHEN** the safe-to-spend figure is computed
- **THEN** the scheduled-bills term of the authored formula is omitted, because
  no scheduled-bill concept exists in the domain
- **AND** no scheduled-bill concept is invented in UI or app code to complete the
  formula
- **AND** the omission is recorded as a deviation in
  `docs/design-system/figma-map.md` naming annotation `52:362`, so a partial
  figure is not mistaken for the authored one

### Requirement: Home renders the empty dashboard from node 52:372

The Home tab SHALL provide an empty state matching Figma node `52:372` and its
sibling annotation frame `52:537`.

#### Scenario: Empty Home composition
- **WHEN** the empty Home state is rendered
- **THEN** the screen uses `AppBar`, `BottomNav`, `EmptyState` and `ListRow`
- **AND** the empty state is visually distinct from the loading state

#### Scenario: The empty state is not a dead end
- **WHEN** the empty Home state is rendered
- **THEN** it carries a primary action and a three-step checklist, per
  annotation `52:537`
- **AND** the primary action leads somewhere that exists

#### Scenario: The primary action is a step the app can perform
- **WHEN** the first-run screen's primary action is rendered
- **THEN** it offers logging a first expense, which the app supports
- **AND** it does not offer linking an account while no Accounts feature exists

Figma's authored CTA at `52:389` is the account one. Wiring the app's first
screen to a feature that is not built would produce the dead end the annotation
exists to prevent: a primary action that does nothing, above a checklist whose
first row also does nothing. The divergence is recorded in
`docs/design-system/figma-map.md` and reverts when Accounts lands.

#### Scenario: A checklist step with no destination makes no promise
- **WHEN** a checklist step has no destination because its feature is unbuilt
- **THEN** the step is still listed, so the checklist reads as three steps
- **AND** it renders no chevron, because a chevron advertises navigation that
  would not happen

#### Scenario: Completed checklist steps show as done, independently
- **WHEN** one checklist step is already complete and the others are not
- **THEN** that step alone reads as done
- **AND** it no longer responds to being tapped, because re-doing a finished
  step is not a step

Annotation `52:537`: *"checklist items tick off independently."* `52:372` authors
no completed state — nothing is finished on a first-run frame — so the done form
composes `ListRow`'s authored `Badge` accessory rather than inventing a visual.
Setting a budget is the only step that can complete while this screen is
showing: any transaction replaces the screen with `52:2`, and the account step
has no feature to complete.

### Requirement: Home renders the loading dashboard from node 52:547

The Home tab SHALL provide a loading state matching Figma node `52:547` and its
sibling annotation frame `52:630`.

#### Scenario: Loading Home composition
- **WHEN** Home content is loading
- **THEN** the screen uses `AppBar`, `BottomNav` and `Skeleton`
- **AND** no zero-valued balance is rendered as a substitute for loading data

#### Scenario: The app bar does not disappear while loading
- **WHEN** Home moves from loading to loaded
- **THEN** the app bar is present in both states and does not appear, vanish or
  change height across the transition

Annotation `52:630` states: *"AppBar and BottomNav render immediately; only the
content area is skeletonised."* Merged code rendered no app bar in the loading
state, which produced exactly the layout jump the annotation forbids.

#### Scenario: Skeletons mirror the loaded layout
- **WHEN** the loading state is rendered
- **THEN** its skeletons match the authored composition at `52:547` — three
  `Card`, four `Circle`, six `Line` and four `Row`
- **AND** the skeleton block occupies the same regions as the balance card, the
  quick actions, the two section headings, the two budget cards and the
  transaction rows it stands in for

### Requirement: Home renders the over-budget alert from node 57:414

The Home tab SHALL provide an over-budget alert state matching Figma node
`57:414` and its sibling annotation frame `57:612`.

#### Scenario: Over-budget Home composition
- **WHEN** the over-budget alert state is rendered
- **THEN** the screen uses `AppBar`, `BalanceCard`, `Banner`, `BottomNav`,
  `BudgetCard`, `DateGroupHeader`, `SectionHeader` and `TransactionRow`
- **AND** the alert is not communicated by colour alone

#### Scenario: The alert triggers on any budget over its limit
- **WHEN** any active budget for the current period exceeds 100% of its limit
- **THEN** the over-budget alert state is shown
- **AND** when no active budget exceeds its limit, the default state is shown

#### Scenario: The over-limit card sorts first
- **WHEN** the over-budget alert state is rendered
- **THEN** the over-limit `BudgetCard` is ordered before budgets that are on
  track, per annotation `57:612`

#### Scenario: The banner names one category
- **WHEN** several budgets are over their limits
- **THEN** the banner names only the worst category, per annotation `57:612`
- **AND** it does not enumerate every over-limit category

#### Scenario: This state has no quick actions
- **WHEN** the over-budget alert state is rendered
- **THEN** no quick-actions row is rendered, because `57:414` does not author one

### Requirement: Home does not invent missing TransactionRow variants

Home SHALL use only TransactionRow variants supported by the domain unless a
separate domain decision adds more.

#### Scenario: Unsupported transaction row variant
- **WHEN** nodes `52:2` or `57:414` require a transfer or pending transaction row
- **THEN** implementation stops and reports the node id and variant
- **AND** the UI does not invent transfer or pending semantics
