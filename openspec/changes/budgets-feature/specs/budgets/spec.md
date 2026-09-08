## ADDED Requirements

### Requirement: A budget records a limit, not a balance

The system SHALL store a budget as a category, a limit in `Money`, a period, a
start date, a rollover flag and an alert threshold. It SHALL NOT store spend.

Spend is derived from the transactions already in the database on every read, so
a budget and the transactions it measures cannot disagree. A stored total drifts
the first time a transaction is edited or deleted.

#### Scenario: A budget is created with everything 04.04 collects
- **WHEN** a budget is created for Food, 4,000,000 ₫, monthly, starting 1 Sep
  2026, no rollover, alert at 80%
- **THEN** all six values round-trip through storage unchanged
- **AND** the limit is an integer minor-unit `Money`, never a `double`

#### Scenario: Deleting a transaction changes the budget's spend
- **WHEN** a transaction inside a budget's window is deleted
- **THEN** the budget's spend falls by that amount on the next read
- **AND** nothing about the budget row changed

#### Scenario: A limit of zero is rejected
- **WHEN** a budget is created with a limit of 0
- **THEN** the result is a validation failure
- **AND** the message says a budget with no limit cannot be over or under it

#### Scenario: A negative limit is rejected
- **WHEN** a budget is created with a negative limit
- **THEN** the result is a validation failure

#### Scenario: A threshold outside 0 to 1 is rejected
- **WHEN** a budget is created with an alert threshold of 0, 1.5 or -0.2
- **THEN** the result is a validation failure
- **AND** a threshold of exactly 1.0 is accepted, meaning "warn me only when I
  reach the limit"

### Requirement: The period window is computed from the start date

The system SHALL compute the current window of a budget from its period and
start date, in UTC, using an injected `Clock`.

#### Scenario: A monthly window runs start-day to start-day
- **WHEN** a monthly budget starts on 1 Sep 2026 and now is 20 Sep 2026
- **THEN** the window is 1 Sep 2026 inclusive to 1 Oct 2026 exclusive

#### Scenario: A monthly window anchored late in the month survives February
- **WHEN** a monthly budget starts on 31 Jan and now is in February
- **THEN** the window ends on the last day February has, not on 3 March
- **AND** the following window starts on 31 March again, so a short month does
  not permanently shift the anchor

#### Scenario: Weekly and yearly windows
- **WHEN** the period is weekly, the window is seven days from the anchor
- **AND** when yearly, it is the same date one year on

#### Scenario: A budget whose start is in the future has no current window
- **WHEN** a budget starts next month and now is today
- **THEN** its progress reports zero spent against the full limit
- **AND** the window reported is the first one, not a window in the past

### Requirement: Spend counts only what the budget measures

Spend SHALL be the sum of **expense** transactions in the budget's category
whose `occurredAt` falls inside the window and whose currency matches the
budget's.

#### Scenario: Income in the same category is not spend
- **WHEN** a refund is recorded as income in the budget's category
- **THEN** it does not reduce the spend
- **AND** it does not increase it

#### Scenario: Another category is not counted
- **WHEN** an expense in a different category falls inside the window
- **THEN** the spend is unchanged

#### Scenario: A foreign-currency transaction is skipped, not converted
- **WHEN** a USD expense sits in a VND budget's category and window
- **THEN** it is not added to the spend
- **AND** the progress reports how many transactions were skipped, so a screen
  can say so rather than quietly under-reporting

#### Scenario: The window boundaries are half-open
- **WHEN** a transaction occurs at exactly the window start
- **THEN** it counts
- **AND** one at exactly the window end belongs to the next window, counted once
  in total across the two

### Requirement: Daily allowance

`BudgetProgress` SHALL report the daily allowance that `04.05` defines:
`(limit - spent) / days remaining`, recomputed against the injected clock.

#### Scenario: Mid-window
- **WHEN** 1,000,000 ₫ of a 4,000,000 ₫ monthly budget is spent and 10 days
  remain
- **THEN** the daily allowance is 300,000 ₫

#### Scenario: The last day of the window
- **WHEN** the window ends today
- **THEN** days remaining is 1, not 0
- **AND** the allowance is the whole remainder rather than a division by zero

#### Scenario: Over budget
- **WHEN** spend exceeds the limit
- **THEN** the daily allowance is zero, not negative
- **AND** the progress still reports the true fraction, so the screen can say by
  how much

#### Scenario: The allowance is money, not a double
- **WHEN** a remainder does not divide evenly by the days remaining
- **THEN** the allowance is rounded **down** to a whole minor unit, because an
  allowance rounded up is one the user cannot actually afford every day

### Requirement: Rollover carries one period, and says so

When `rollsOver` is set, the effective limit for a window SHALL be the budget's
limit plus any unspent amount from the **immediately preceding** window.

Annotation `04.04`: *"Rollover changes next period's limit, not this one's."*

The carry SHALL NOT be accumulated recursively across all history. A recursive
carry means every read walks every window since the budget was created, which is
unbounded work on a screen that renders on every app open. `BudgetProgress`
SHALL expose the carried amount separately so a screen can show it rather than
presenting an inflated limit with no explanation.

#### Scenario: Unspent amount raises the next window's limit
- **WHEN** a monthly budget of 4,000,000 ₫ with rollover had 1,000,000 ₫ unspent
  last month
- **THEN** this month's effective limit is 5,000,000 ₫
- **AND** the carried 1,000,000 ₫ is reported separately from the 4,000,000 ₫

#### Scenario: Overspending does not carry a debt forward
- **WHEN** last window went 500,000 ₫ over
- **THEN** the carry is zero, not negative
- **AND** the effective limit is the plain limit

#### Scenario: Rollover off carries nothing
- **WHEN** `rollsOver` is false and last window was underspent
- **THEN** the effective limit equals the limit and the carry is zero

#### Scenario: The carry is one window deep, not all of them
- **WHEN** a budget has been underspent for three consecutive windows
- **THEN** the carry is the previous window's remainder only
- **AND** the progress reports this, so the number is explainable

### Requirement: Budgets are ranked worst first

A list of budgets SHALL be ordered by fraction of limit used, descending.

Annotation `04.01`: *"cards sort by percentage used descending, so an
over-limit budget can never be below the fold."*

#### Scenario: The over-limit budget leads
- **WHEN** budgets at 120%, 45% and 82% are listed
- **THEN** the order is 120%, 82%, 45%

#### Scenario: Ties are ordered stably
- **WHEN** two budgets sit at the same fraction
- **THEN** their relative order is deterministic across repeated reads

#### Scenario: A budget with no spend still appears
- **WHEN** a budget has no transactions in its window
- **THEN** it is listed at 0%, last
- **AND** it is not omitted
