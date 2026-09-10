## ADDED Requirements

### Requirement: Demo data and real data are never mixed

Demo data SHALL be stored in a database file separate from the real one. No
demo record SHALL ever be written to the real database, and no record SHALL
carry a marker distinguishing demo from real.

The separation is the file. A flag on a row is a filter every query has to
remember, and a query that forgets it puts dummy money in a real balance.

#### Scenario: Turning demo mode on leaves real data untouched
- **WHEN** demo mode is turned on and the seeded dataset is generated
- **THEN** the real database's contents are unchanged, row for row
- **AND** its schema version is unchanged

#### Scenario: Turning demo mode off restores the real ledger exactly
- **WHEN** demo mode is turned off after transactions were added in demo mode
- **THEN** every balance, budget and list is exactly what it was before demo
  mode was turned on
- **AND** nothing entered during demo mode appears

#### Scenario: No column tells the two apart
- **WHEN** the schema of either database is inspected
- **THEN** no table has a column marking a row as demo data
- **AND** the two schemas are identical, because both are built by the same
  migration set

#### Scenario: An install that never enables demo mode is unaffected
- **WHEN** demo mode has never been turned on
- **THEN** no second database file exists
- **AND** the application behaves exactly as it did before this capability

### Requirement: The dataset is written through the same repositories as manual entry

The seeder SHALL create its data by calling the same repository methods the
application's own forms call. It SHALL NOT write to tables directly.

This makes the dataset provably enterable by hand: demo data cannot be data the
application would refuse to accept, and the seeder cannot drift from a schema it
does not know about.

#### Scenario: Seeded records pass the same validation as typed ones
- **WHEN** the dataset is generated
- **THEN** every record was accepted by the repository that owns it
- **AND** a record the repository would reject is not written by another route

#### Scenario: A seeding failure is reported, not half-applied
- **WHEN** a repository reports a failure part way through seeding
- **THEN** the failure is surfaced and seeding stops
- **AND** the demo database is left in a state the application can open, not a
  partially seeded one presented as complete

### Requirement: The dataset is deterministic

Given the same clock, the seeder SHALL produce byte-identical data on every run
and on every machine.

Randomness that varies between runs makes a screenshot unreproducible and a
test unwritable. The generator therefore uses its own arithmetic rather than
`dart:math`'s `Random`, whose sequence is not guaranteed stable across Dart
releases.

#### Scenario: Two runs at the same instant agree
- **WHEN** the dataset is generated twice with the same fixed clock
- **THEN** the two datasets are identical in every field, including identifiers
  and ordering

#### Scenario: The dataset is anchored to the clock, not to a fixed calendar
- **WHEN** the dataset is generated at two different instants a month apart
- **THEN** both cover the same span *relative to* their clock, so the app always
  looks current
- **AND** neither contains a transaction dated in the future

### Requirement: The dataset covers what the screens need to show

The dataset SHALL contain enough history and variety that every existing screen
has something to display and every derived state is reachable.

#### Scenario: Enough history for a year-over-year comparison
- **WHEN** the dataset is generated
- **THEN** it spans at least fifteen whole months up to the current month
- **AND** every month in that span has transactions

#### Scenario: Every category is represented
- **WHEN** the dataset is inspected
- **THEN** every spend category the application defines appears
- **AND** the category totals are unequal, so a ranked chart has a real order

#### Scenario: Both directions of money
- **WHEN** the dataset is inspected
- **THEN** it contains both income and expense transactions
- **AND** the income arrives on a repeating cycle rather than at random

#### Scenario: Every budget state is reachable
- **WHEN** the dataset's budgets are evaluated against its transactions
- **THEN** at least one budget is over its limit, at least one is near its
  limit, and at least one is on track
- **AND** budgets of all three periods exist

#### Scenario: The donut's fold is exercised
- **WHEN** the current month's categories are charted
- **THEN** there are more than eight of them, so the eight-segment cap and the
  neutral `Other` fold are both visible rather than only tested

#### Scenario: Amounts are plausible for the wallet's currency
- **WHEN** any seeded amount is inspected
- **THEN** it is a whole number of minor units in the wallet's currency
- **AND** no amount is zero or negative

### Requirement: Manual entry works in demo mode

While demo mode is active, every action that creates, edits or deletes data
SHALL behave exactly as it does outside demo mode, writing to the demo
database.

#### Scenario: A transaction added in demo mode persists
- **WHEN** a transaction is recorded while demo mode is active
- **THEN** it appears in the list, counts towards balances and budgets, and
  survives a restart with demo mode still active

#### Scenario: A budget created in demo mode behaves normally
- **WHEN** a budget is created while demo mode is active
- **THEN** its progress is computed from the demo transactions like any other

#### Scenario: Seeded records are not privileged
- **WHEN** a seeded transaction is deleted while demo mode is active
- **THEN** it is deleted, and the deletion can be undone, exactly as for a
  manually entered one

### Requirement: The demo dataset can be reset, and only the demo dataset

Resetting SHALL discard the demo database's contents and regenerate the
dataset. No equivalent action SHALL exist for the real database.

#### Scenario: Reset returns the demo database to the seeded dataset
- **WHEN** reset is invoked after records were added and deleted in demo mode
- **THEN** the demo database holds exactly the seeded dataset again

#### Scenario: Reset is unavailable outside demo mode
- **WHEN** demo mode is off
- **THEN** no reset action is offered
- **AND** no code path can wipe the real database

### Requirement: The toggle survives its own effect

The setting that selects which database is active SHALL be stored in the control
database, which the toggle never swaps.

#### Scenario: The toggle persists across a restart
- **WHEN** demo mode is turned on and the application is restarted
- **THEN** demo mode is still on

#### Scenario: The toggle does not undo itself
- **WHEN** demo mode is turned on
- **THEN** the value read back afterwards is the value just written, not the
  value stored in the newly activated database

#### Scenario: Absence is distinguishable from off
- **WHEN** the setting has never been written
- **THEN** demo mode is off, and the absence is reported distinctly from a
  stored `false`

### Requirement: Demo mode is visibly demo mode

While demo mode is active the application SHALL say so on screen, wherever data
is shown.

A user who cannot tell which ledger they are looking at can mistake dummy
figures for their own finances, which is the one genuinely harmful outcome this
capability makes possible.

#### Scenario: An always-visible indication
- **WHEN** demo mode is active
- **THEN** an indication is visible on the application's main surfaces without
  the user having to open settings

#### Scenario: The indication is absent otherwise
- **WHEN** demo mode is off
- **THEN** nothing suggests the data is anything but real
