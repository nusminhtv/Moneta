## Purpose

Defines what the Home overview shows for a period, how its figures are derived,
and how it behaves when the data behind it cannot be read.

## ADDED Requirements

### Requirement: The overview covers a bounded period

Home SHALL show figures for an explicit period, bounded inclusive of its start
and exclusive of its end, so adjacent periods neither overlap nor drop a
transaction on the boundary.

#### Scenario: The default period is the current calendar month
- **WHEN** Home is opened
- **THEN** the period runs from the first instant of the current local month up
  to, but not including, the first instant of the next month

#### Scenario: A transaction exactly on the period start is included
- **WHEN** a transaction's instant equals the period start
- **THEN** it counts toward the period's income or expenses

#### Scenario: A transaction exactly on the period end is excluded
- **WHEN** a transaction's instant equals the period end
- **THEN** it does not count toward this period
- **AND** it counts toward the next one

#### Scenario: The period is derived in local time
- **WHEN** the device is in any time zone
- **THEN** the month boundaries are that zone's month boundaries, converted to
  UTC for querying

#### Scenario: A month containing a daylight-saving transition
- **WHEN** the current month contains a DST transition
- **THEN** the period still spans exactly that calendar month, with no hour
  gained or lost at either boundary

### Requirement: Total balance is all-time, not the period's net

Home SHALL show total balance as the net of every transaction ever recorded, and
income and expenses as the totals for the displayed period only.

#### Scenario: Balance ignores the period
- **WHEN** transactions exist both inside and outside the displayed period
- **THEN** total balance includes all of them
- **AND** income and expenses include only those inside the period

#### Scenario: A month's net is not presented as a balance
- **WHEN** the period's income exceeds its expenses but earlier months were
  negative overall
- **THEN** total balance may still be negative, and is shown as such

#### Scenario: First run
- **WHEN** no transactions exist
- **THEN** total balance, income and expenses are all a formatted zero, not blank
  and not a placeholder

### Requirement: Safe-to-spend has one stated definition

Home SHALL derive safe-to-spend as the period's income minus the period's
expenses, floored at zero, and SHALL NOT present a negative safe-to-spend.

#### Scenario: Income exceeds expenses
- **WHEN** the period's income is greater than its expenses
- **THEN** safe-to-spend is the difference

#### Scenario: Expenses exceed income
- **WHEN** the period's expenses are greater than or equal to its income
- **THEN** safe-to-spend is zero
- **AND** it is not shown as a negative amount, because "safe to spend −2,000,000"
  is not a meaning the phrase has

#### Scenario: A period with no transactions
- **WHEN** the period is empty
- **THEN** safe-to-spend is zero

### Requirement: The overview lists the most recent transactions

Home SHALL show a bounded number of the most recent transactions, newest first,
below the hero card.

#### Scenario: Fewer transactions than the limit
- **WHEN** fewer transactions exist than the limit
- **THEN** all of them are shown

#### Scenario: More transactions than the limit
- **WHEN** more exist than the limit
- **THEN** exactly the limit is shown, and they are the most recent ones

#### Scenario: The recent list is not restricted to the period
- **WHEN** the most recent transaction is older than the displayed period
- **THEN** it still appears in the recent list
- **AND** it does not affect the period's income or expenses

#### Scenario: No transactions at all
- **WHEN** none exist
- **THEN** the recent section shows an empty state inviting the first record
- **AND** the hero card is still shown, with zero figures

### Requirement: Hiding the figures survives a restart

Home SHALL let the user hide every figure on the hero card, and SHALL remember
that choice across restarts.

#### Scenario: Hiding
- **WHEN** the user activates the mask control
- **THEN** no digit from the balance, safe-to-spend, income or expenses is
  rendered

#### Scenario: The choice is durable
- **WHEN** the figures are hidden and the application is closed and reopened
- **THEN** they are still hidden, without the user acting again

#### Scenario: Revealing is equally durable
- **WHEN** the user reveals the figures and the application is closed and reopened
- **THEN** they are shown

#### Scenario: The preference cannot be read
- **WHEN** reading the stored preference fails
- **THEN** the figures are shown rather than hidden, and the screen still loads
- **AND** the failure does not prevent the overview from rendering, because a
  masking preference is not worth failing a screen over

### Requirement: Failures are reported, not shown as zeros

Home SHALL distinguish, on screen, having no data from having failed to read it.

#### Scenario: A read failure
- **WHEN** loading the overview fails
- **THEN** an error state is shown with a retry action
- **AND** no zero-valued hero card is shown, because a balance of zero is a claim
  about the user's money

#### Scenario: Retry succeeds
- **WHEN** the user retries and the read succeeds
- **THEN** the overview replaces the error state

#### Scenario: Retry fails again
- **WHEN** the retry also fails
- **THEN** the error state remains and no partial figures appear

### Requirement: The overview does not know where its data comes from

The Home feature SHALL depend on a declared data port and SHALL NOT depend on
any other feature.

#### Scenario: Home is testable without the transactions implementation
- **WHEN** the Home controller is exercised in a test
- **THEN** it can be driven entirely through a substitute data source
- **AND** the test requires no database and no transactions code

#### Scenario: The architecture gate stays satisfied
- **WHEN** the architecture check runs
- **THEN** no file under `features/home` imports another feature
