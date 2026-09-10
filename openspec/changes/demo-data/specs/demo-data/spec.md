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
- **AND** the real database is opened exactly once, by one connection, as it
  was before this capability

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

#### Scenario: A seeding failure is reported, and the result is not called complete
- **WHEN** a repository reports a failure part way through seeding
- **THEN** the failure is surfaced and seeding stops
- **AND** the demo ledger is not marked seeded, so the next activation seeds it
  again rather than presenting a partial dataset as complete

### Requirement: Seeding completeness is recorded in the demo ledger

The demo database SHALL carry a marker written only after the whole dataset has
been written successfully. Activation SHALL seed when the marker is absent and
SHALL NOT seed when it is present.

"Does the demo database have any transactions?" is not the same question: a seed
that fails after the first row leaves transactions behind, and would then never
be retried. And the marker cannot be a preference — preferences live in the
control database, which is shared, so it would claim the *real* ledger was
seeded.

#### Scenario: A completed seed is not repeated
- **WHEN** demo mode is turned on twice with a successful seed in between
- **THEN** the dataset is generated once

#### Scenario: A failed seed is retried
- **WHEN** seeding fails part way and demo mode is turned on again
- **THEN** seeding runs again

#### Scenario: The marker describes the ledger it is in
- **WHEN** the marker is written
- **THEN** it is stored in the demo database, not the control database
- **AND** turning demo mode off does not make the real ledger appear seeded

### Requirement: The dataset is deterministic

Given the same clock and the same identifier source, the generator SHALL produce
equal data on every run.

Randomness that varies between runs makes a screenshot unreproducible and a test
unwritable. The generator therefore uses its own arithmetic rather than
`dart:math`'s `Random`, whose sequence is not guaranteed stable across Dart
releases.

**The identifier source is part of this.** The production `IdGenerator` is
`Random.secure()` plus the wall clock, so a dataset built with it is not
reproducible. The generator SHALL take its identifier source as a parameter, and
the seeder SHALL pass a seeded one.

#### Scenario: Two runs at the same instant agree
- **WHEN** the dataset is generated twice with the same fixed clock and the same
  seeded identifier source
- **THEN** the two datasets are equal field for field, in the same order,
  including identifiers

#### Scenario: The generator does not reach for a global
- **WHEN** the generator's signature is inspected
- **THEN** the clock and the identifier source are both parameters
- **AND** neither `DateTime.now()` nor an unseeded random source is reachable
  from it

#### Scenario: The dataset is anchored to the clock, not to a fixed calendar
- **WHEN** the dataset is generated at two different instants a month apart
- **THEN** each spans the same number of whole months up to its own clock's
  month
- **AND** neither contains a transaction dated after its clock

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

#### Scenario: Every expense category appears in the current month
- **WHEN** the current month's transactions are grouped by category
- **THEN** every expense category the application defines is present
- **AND** their totals are distinct, so a ranked chart has an unambiguous order

The donut's eight-segment cap and neutral `Other` fold are deliberately **not**
exercised by this dataset and cannot be: `SpendCategory` declares eight
categories, one of which is income, so at most seven can carry expense, and the
cap is eight. Reaching the fold would mean adding categories to `lib/core`,
which is a different proposal. The fold stays covered by
`donut_chart_test.dart`, which supplies its own categories.

#### Scenario: Amounts are whole, positive minor units before construction
- **WHEN** the generator's raw amounts are inspected, before any domain object
  is built from them
- **THEN** each is a whole number of minor units in the wallet's currency,
  greater than zero

Asserted on the raw values on purpose. `Transaction.create` already rejects a
non-positive amount and forces UTC, so asserting these on the finished objects
would test `transaction.dart` and pass for a generator that emitted nothing at
all.

#### Scenario: A large amount is present
- **WHEN** the dataset is inspected
- **THEN** at least one transaction is large enough to exercise the widest
  amount the screens must render, and the fifteen-month total is larger still
- **AND** both render without overflowing

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

### Requirement: A write in flight when the ledger changes is discarded

Changing the active ledger SHALL discard every pending write and every undoable
deletion held in memory. No record captured against one ledger SHALL be written
to the other.

This is the one path by which the file separation is not enough on its own.
Deleting a transaction leaves a `PendingUndo` holding that record in memory for
five seconds; without this requirement, deleting a demo transaction, turning
demo mode off, and pressing undo inserts a demo record into the real ledger
through the ordinary repository path.

#### Scenario: A pending undo does not survive the swap
- **WHEN** a transaction is deleted in demo mode and demo mode is turned off
  inside the undo window
- **THEN** the pending undo is gone and undo is not offered
- **AND** the real ledger gains no row

#### Scenario: The same holds in the other direction
- **WHEN** a transaction is deleted with demo mode off and demo mode is turned
  on inside the undo window
- **THEN** the pending undo is gone and the demo ledger gains no row

#### Scenario: In-ledger undo still works
- **WHEN** a transaction is deleted and undone without the ledger changing
- **THEN** undo restores it exactly as before

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

#### Scenario: Reset fails
- **WHEN** the demo database cannot be deleted or recreated
- **THEN** a storage `AppFailure` is reported
- **AND** demo mode is left in a state the application can open — either the
  previous demo database or an unseeded one — never a closed connection with no
  database behind it

#### Scenario: An empty demo ledger is an empty ledger, not an error
- **WHEN** every record in the demo ledger has been deleted by hand
- **THEN** the screens show their ordinary empty states
- **AND** the demo indication is still shown

### Requirement: Activation is safe on any starting state

Turning demo mode on SHALL work regardless of what exists on disk.

#### Scenario: No real database has ever been created
- **WHEN** demo mode is turned on before the real database file exists
- **THEN** the control database is created first, so the setting has somewhere
  to live
- **AND** activation succeeds

#### Scenario: A demo database left by an older build
- **WHEN** the demo database exists at a lower schema version
- **THEN** it is migrated forward like any other database, not deleted

#### Scenario: A demo database newer than the application
- **WHEN** the demo database's schema version is higher than the application's,
  which happens after a downgrade
- **THEN** the storage failure is surfaced rather than crashing the app on
  launch
- **AND** the user can leave demo mode or reset it, because the setting that
  selects it lives in a database that still opens

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

### Requirement: The demo controls are reachable and say what they are

The application SHALL offer a surface carrying the ledger selection and, in demo
mode, the reset. It SHALL name both ledgers rather than leaving one implied, and
SHALL state that the surface itself is provisional.

#### Scenario: The control reports which ledger is active
- **WHEN** the surface is shown
- **THEN** exactly one of "real ledger" and "demo ledger" reads as selected,
  and it is the active one

#### Scenario: Choosing the other ledger changes the active ledger
- **WHEN** the inactive ledger is chosen
- **THEN** the setting is written, and the active database becomes that ledger's

#### Scenario: Reset asks before it acts
- **WHEN** reset is invoked
- **THEN** confirmation is requested before anything is deleted
- **AND** declining leaves the demo ledger untouched

#### Scenario: The surface says it is provisional
- **WHEN** the surface is shown
- **THEN** it states that it is not the designed settings screen, so a reviewer
  does not compare it against Figma

### Requirement: Demo mode is visibly demo mode

While demo mode is active the application SHALL say so on screen, wherever data
is shown.

A user who cannot tell which ledger they are looking at can mistake dummy
figures for their own finances, which is the one genuinely harmful outcome this
capability makes possible.

#### Scenario: An always-visible indication
- **WHEN** demo mode is active
- **THEN** an indication is visible on every route that shows ledger data —
  Home, Transactions, Budgets and Budget detail — without the user having to
  open settings
- **AND** it cannot be dismissed

#### Scenario: The indication is absent otherwise
- **WHEN** demo mode is off
- **THEN** nothing suggests the data is anything but real
