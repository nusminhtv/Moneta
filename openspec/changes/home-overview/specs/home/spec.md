## Purpose

Defines what the Home overview shows for a period, how its derived figures are
computed, and how it behaves when the data behind it cannot be read.

Scope note: this capability deliberately does **not** restate behaviour already
owned elsewhere in the spec set. Transaction ordering and range semantics belong
to `transactions`; the balance card's masked rendering and the row's signed
amounts belong to `design-system/components`; database failure reporting and
durability belong to `storage/local-database`. Home's requirements are only the
ones about *composing* those things.

## ADDED Requirements

### Requirement: The period is the current local month

Home SHALL show period figures for the current calendar month in the device's
local time zone. The period bounds SHALL be passed to the store as a range whose
semantics are already defined by the `transactions` capability.

#### Scenario: Month bounds
- **WHEN** Home is opened
- **THEN** the period start is the first instant of the current local month and
  the period end is the first instant of the next local month

#### Scenario: December rolls over
- **WHEN** the current local month is December
- **THEN** the period end is the first instant of January of the following year

#### Scenario: A month containing a daylight-saving transition
- **WHEN** the current local month contains a DST transition
- **THEN** the period still spans exactly that calendar month, with no hour
  gained or lost at either boundary
- **AND** the bounds are computed from calendar fields, not by adding a duration

#### Scenario: Bounds are converted for storage
- **WHEN** the period is used to read from the store
- **THEN** its bounds are expressed in UTC, because that is what the store
  compares against

### Requirement: A transaction's position in time is its occurrence, not its entry

Every Home figure and list SHALL be determined by when a transaction **occurred**,
never by when it was recorded.

#### Scenario: A backdated transaction
- **WHEN** a transaction is recorded today but occurred in the previous month
- **THEN** it counts toward the previous month's period, not this month's

#### Scenario: The recent list
- **WHEN** the recent list is built
- **THEN** it is ordered by occurrence, so a transaction entered late appears at
  its own position in time rather than at the top

### Requirement: Total balance is the net of everything that has already happened

Home SHALL show total balance as the net of all transactions whose occurrence is
at or before now, and SHALL exclude any transaction occurring strictly later than
now. A transaction occurring at exactly the current instant SHALL be included.

#### Scenario: Balance ignores the displayed period
- **WHEN** transactions exist both inside and outside the displayed period
- **THEN** total balance includes all of them, subject to the rule below
- **AND** period income and expenses include only those inside the period

#### Scenario: A transaction occurring at exactly this instant is included
- **WHEN** a transaction's occurrence equals the current instant
- **THEN** it contributes to total balance
- **AND** this instant is reachable in practice: the add form stamps occurrence
  from the same clock, so under a fixed clock a just-recorded transaction occurs
  at exactly now

#### Scenario: A future-dated transaction is excluded
- **WHEN** a transaction occurs strictly later than now
- **THEN** it does not contribute to total balance
- **AND** this matches the `transactions` capability's stated reason for
  rejecting future-dated entries — a balance that includes money not yet spent is
  wrong

#### Scenario: Balance and period net can disagree in sign
- **WHEN** the period's income exceeds its expenses but earlier months were
  negative overall
- **THEN** total balance is negative while the period net is positive, and both
  are shown as they are

#### Scenario: First run
- **WHEN** no transactions exist
- **THEN** total balance, period income and period expenses are each a formatted
  zero in the wallet currency, not blank and not a placeholder

#### Scenario: Very large totals are exact
- **WHEN** the summed amounts reach a trillion minor units
- **THEN** the total is exact to the minor unit
- **AND** the same figure read twice returns the same value, so nothing has
  wrapped between reads

### Requirement: Safe-to-spend is period income minus period expenses, floored at zero

Home SHALL derive safe-to-spend from the displayed period only, and SHALL NOT
present it as a negative amount.

#### Scenario: Income exceeds expenses
- **WHEN** the period's income is greater than its expenses
- **THEN** safe-to-spend is the difference

#### Scenario: Expenses equal income
- **WHEN** the period's expenses equal its income
- **THEN** safe-to-spend is zero

#### Scenario: Expenses exceed income
- **WHEN** the period's expenses are greater than its income
- **THEN** safe-to-spend is zero, not the negative difference — "safe to spend
  −2,000,000 ₫" is not a meaning the phrase has
- **AND** the overspend is not otherwise signalled here; that is a budget concern

#### Scenario: An empty period
- **WHEN** the period contains no transactions
- **THEN** safe-to-spend is zero

### Requirement: Safe-to-spend is labelled with the last day of the period

Home SHALL tell the user which date the safe-to-spend figure runs until, and that
date SHALL be the last day *within* the period, not the exclusive end bound.

#### Scenario: The displayed date
- **WHEN** the period ends at the first instant of the next month
- **THEN** the date shown is the final day of the current month **in the device's
  local time zone**
- **AND** it is not the first day of the next month, which is outside the period
- **AND** it is not the final UTC day of the period, which in a zone ahead of UTC
  is a day earlier — for UTC+7 the period ends at 31 Aug 17:00 UTC, so a
  UTC-based calculation yields 30 August and is wrong

#### Scenario: The card receives a date, not a string
- **WHEN** the balance card is given the period end
- **THEN** it receives a date value and formats it itself, so Home cannot
  disagree with the rest of the application about how dates are written

### Requirement: The overview lists the five most recent transactions

Home SHALL show at most five transactions, the most recent by occurrence, below
the hero card. The list SHALL NOT be restricted to the displayed period.

#### Scenario: Fewer than five exist
- **WHEN** three transactions exist
- **THEN** all three are shown

#### Scenario: More than five exist
- **WHEN** nine transactions exist
- **THEN** exactly five are shown, and they are the five most recent by occurrence

#### Scenario: Recency is not period-bounded
- **WHEN** the most recent transaction occurred before the displayed period began
- **THEN** it still appears in the recent list
- **AND** it does not contribute to period income or expenses

#### Scenario: No transactions at all
- **WHEN** none exist
- **THEN** the recent section shows an empty state inviting the first record
- **AND** the hero card is still shown, with zero figures

### Requirement: The recent list carries only shared types

The Home feature's own types SHALL NOT reference another feature's types.

#### Scenario: A recent entry's shape
- **WHEN** a recent entry is inspected
- **THEN** it carries an identifier, a display title, a money amount, a
  direction, a category and an occurrence instant, all of which are shared types

#### Scenario: The architecture gate
- **WHEN** the architecture check runs
- **THEN** no file under `features/home` imports another feature

### Requirement: Hiding the figures hides every amount on the screen

Home SHALL let the user hide the figures, and hiding SHALL cover the hero card's
four amounts **and** every amount in the recent list.

#### Scenario: Hiding
- **WHEN** the user activates the mask control
- **THEN** no digit belonging to any monetary amount is rendered anywhere on the
  screen
- **AND** a masked hero card beside an unmasked "−1,250,000 ₫" would defeat the
  purpose, so the list is masked too

#### Scenario: Non-amount content stays visible
- **WHEN** the figures are hidden
- **THEN** category names, transaction titles and the layout are unchanged

#### Scenario: The choice is durable
- **WHEN** the figures are hidden and the application is closed and reopened
- **THEN** they are still hidden, without the user acting again

#### Scenario: Revealing is equally durable
- **WHEN** the user reveals the figures and the application is closed and
  reopened
- **THEN** they are shown

#### Scenario: The preference has never been set
- **WHEN** Home loads and no preference is stored
- **THEN** the figures are shown

#### Scenario: The preference cannot be read
- **WHEN** reading the stored preference reports a storage failure
- **THEN** the figures are shown, and the overview still renders
- **AND** the failure does not produce an error state, because a display
  preference is not worth failing a screen over

#### Scenario: The preference store itself is unavailable
- **WHEN** the database cannot be opened at all, so the preference store cannot be
  constructed
- **THEN** the figures are shown and Home renders whatever the snapshot read
  produced
- **AND** if that same unavailability also failed the snapshot read, the error
  state comes from the snapshot — an unopenable database is one failure, not two,
  and it is reported by the read that actually needed data

#### Scenario: The preference cannot be written
- **WHEN** the user toggles the mask and storing the choice fails
- **THEN** the on-screen state follows the user's action for this session
- **AND** the failure is surfaced to the user rather than silently discarded

### Requirement: Failures are reported, never rendered as zeros

Home SHALL distinguish, on screen, having no data from having failed to read it.

#### Scenario: A storage failure while loading
- **WHEN** any read needed for the overview reports a storage failure
- **THEN** an error state is shown with a retry action
- **AND** no hero card with zero figures is shown, because a balance of zero is a
  claim about the user's money

#### Scenario: Partial failure is still failure
- **WHEN** one of the reads succeeds and another fails
- **THEN** the error state is shown rather than a partially-filled overview

#### Scenario: Retry succeeds
- **WHEN** the user retries and the reads succeed
- **THEN** the overview replaces the error state

#### Scenario: Retry fails again
- **WHEN** the retry also fails
- **THEN** the error state remains and no partial figures appear

#### Scenario: A validation failure is a defect, not a user-facing state
- **WHEN** constructing the period query would report a validation failure
- **THEN** that is a programming error in Home, not a state the user can reach
- **AND** it is caught by test rather than rendered

### Requirement: Amounts in more than one currency are refused, not added

Home SHALL NOT display a figure derived from amounts in differing currencies.

#### Scenario: The store reports a summary in an unexpected currency
- **WHEN** a figure read from the store is denominated in a currency other than
  the wallet's
- **THEN** a **storage** failure is reported and the error state is shown
- **AND** no total is displayed, because adding unlike currencies produces a
  number that is wrong without looking wrong
- **AND** the kind is storage rather than validation because the input came from
  the store, not from a caller — Home asked for the right thing and got data it
  cannot trust, which is the same situation as an unreadable row

#### Scenario: The mismatch is caught before any arithmetic
- **WHEN** figures are read from the store
- **THEN** their currencies are checked against the wallet currency before a
  snapshot is constructed
- **AND** because that check precedes construction, the snapshot's own figures are
  same-currency by construction and its derivations cannot raise a currency
  exception

#### Scenario: Negative stored amounts
- **WHEN** the store is read
- **THEN** no transaction can carry a negative magnitude, because the
  `transactions` capability forbids it at construction — so Home has no such case
  to handle, and asserts that rather than guarding it

### Requirement: A newly recorded transaction appears without a manual refresh

When a transaction is recorded while Home is the current screen, Home SHALL
reflect it without the user acting again.

#### Scenario: Recording from the overview
- **WHEN** the user records a transaction from the add action while on Home
- **THEN** the recent list and the period figures include it once the sheet closes

#### Scenario: A failed record changes nothing
- **WHEN** recording fails
- **THEN** Home is unchanged

### Requirement: The overview is composed from existing components

Home SHALL be built from the existing design-system components rather than new
one-off widgets.

#### Scenario: The hero card
- **WHEN** Home renders its hero
- **THEN** it is the balance card from Figma node `40:161`, in its `State=Default`
  variant when revealed and its `State=Masked` variant when hidden

#### Scenario: The recent rows
- **WHEN** Home renders a recent transaction
- **THEN** it is the shared transaction row, in its masked or unmasked form to
  match the hero card

#### Scenario: No Figma frame exists for the screen itself
- **WHEN** the arrangement of hero card, section heading and list is reviewed
- **THEN** it is understood to be a decision recorded in the design docs, because
  the Figma file contains no Home frame to transcribe
