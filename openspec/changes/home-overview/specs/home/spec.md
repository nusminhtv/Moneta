## Purpose

Defines the four Home tab states authored on `📱 02 Home & Dashboard`: default,
empty, loading and over-budget alert.

## ADDED Requirements

### Requirement: Home renders the default dashboard from node 52:2

The Home tab SHALL provide a default dashboard state matching Figma node `52:2`
and its sibling annotation frame.

#### Scenario: Default Home composition
- **WHEN** the default Home state is rendered
- **THEN** the screen uses `AppBar`, `BalanceCard`, `BottomNav`, `BudgetCard`,
  `DateGroupHeader`, `IconButton`, `SectionHeader` and `TransactionRow`
- **AND** the Home tab is the active bottom navigation destination

### Requirement: Home renders the empty dashboard from node 52:372

The Home tab SHALL provide an empty state matching Figma node `52:372` and its
sibling annotation frame.

#### Scenario: Empty Home composition
- **WHEN** the empty Home state is rendered
- **THEN** the screen uses `AppBar`, `BottomNav`, `EmptyState` and `ListRow`
- **AND** the empty state is visually distinct from the loading state

### Requirement: Home renders the loading dashboard from node 52:547

The Home tab SHALL provide a loading state matching Figma node `52:547` and its
sibling annotation frame.

#### Scenario: Loading Home composition
- **WHEN** Home content is loading
- **THEN** the screen uses `AppBar`, `BottomNav` and `Skeleton`
- **AND** no zero-valued balance is rendered as a substitute for loading data

### Requirement: Home renders the over-budget alert from node 57:414

The Home tab SHALL provide an over-budget alert state matching Figma node
`57:414` and its sibling annotation frame.

#### Scenario: Over-budget Home composition
- **WHEN** the over-budget alert state is rendered
- **THEN** the screen uses `AppBar`, `BalanceCard`, `Banner`, `BottomNav`,
  `BudgetCard`, `DateGroupHeader`, `SectionHeader` and `TransactionRow`
- **AND** the alert is not communicated by colour alone

### Requirement: Home does not invent missing TransactionRow variants

Home SHALL use only TransactionRow variants supported by the domain unless a
separate domain decision adds more.

#### Scenario: Unsupported transaction row variant
- **WHEN** nodes `52:2` or `57:414` require a transfer or pending transaction row
- **THEN** implementation stops and reports the node id and variant
- **AND** the UI does not invent transfer or pending semantics
