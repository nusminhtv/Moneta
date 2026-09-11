# transactions Specification

## Purpose
Defines what a Moneta transaction is and how it is recorded, read back,
filtered, summarised and removed, so that the figures shown to a user are the
figures that were stored.

## Requirements

### Requirement: A transaction records an amount, a direction, a category and a time

The system SHALL store, for each transaction, an exact amount, whether it is
money in or money out, a spend category, the instant it occurred, and an
optional note.

#### Scenario: A recorded transaction reads back unchanged
- **WHEN** a transaction is recorded and then read back
- **THEN** every field is identical, including the amount to the minor unit and
  the instant to the second

#### Scenario: Amounts are exact
- **WHEN** an amount is stored and read back
- **THEN** it is exact to the minor unit, with no rounding drift, for values up
  to at least a trillion minor units

#### Scenario: The amount is always a positive magnitude
- **WHEN** a transaction is recorded
- **THEN** its amount is a positive magnitude and its direction carries the sign
- **AND** a zero or negative amount is rejected as a validation failure, because
  direction, not sign, is what distinguishes income from expense

#### Scenario: Time is stored in UTC
- **WHEN** a transaction recorded in one time zone is read in another
- **THEN** the instant is unchanged
- **AND** the value read back is in UTC

#### Scenario: A note is optional and bounded
- **WHEN** a transaction is recorded without a note
- **THEN** it reads back with no note rather than an empty string
- **AND** a note longer than the permitted length is rejected as a validation
  failure rather than silently truncated

#### Scenario: Every transaction has a stable identity
- **WHEN** a transaction is recorded
- **THEN** it is assigned an identifier that is unique and does not change
- **AND** recording two transactions with identical field values produces two
  distinct records, because a person can legitimately buy the same coffee twice

### Requirement: Transactions are listed newest first

Reading transactions SHALL return them ordered by their instant, most recent
first, with a stable order among transactions sharing an instant.

#### Scenario: Ordering
- **WHEN** transactions are read
- **THEN** they are ordered by instant descending

#### Scenario: Ties are ordered stably
- **WHEN** two transactions share the same instant
- **THEN** their relative order is the same on every read

#### Scenario: An empty database is an empty list, not a failure
- **WHEN** transactions are read on first run
- **THEN** an empty list is returned successfully
- **AND** this is distinguishable by the caller from a storage failure

### Requirement: Transactions can be filtered

Reading SHALL support restricting results by category and by date range, in any
combination.

#### Scenario: Filtering by category
- **WHEN** a read is restricted to a set of categories
- **THEN** only transactions in those categories are returned

#### Scenario: Filtering by date range
- **WHEN** a read is restricted to a range
- **THEN** only transactions at or after the start and strictly before the end
  are returned
- **AND** the boundary instants behave exactly that way — inclusive start,
  exclusive end — so adjacent ranges neither overlap nor drop a transaction

#### Scenario: A filter matching nothing
- **WHEN** a filter matches no transaction
- **THEN** an empty list is returned successfully

#### Scenario: An inverted range
- **WHEN** a range whose end is before its start is supplied
- **THEN** a validation failure is reported rather than an empty list, because
  an empty list would hide the caller's bug

### Requirement: A period is summarised without loading every transaction

The system SHALL report total income, total expenses and net balance for a
period, computed by the database rather than by loading rows into memory.

#### Scenario: Summary figures
- **WHEN** a period contains income and expense transactions
- **THEN** income is the sum of income amounts, expenses the sum of expense
  amounts, and the net balance is income minus expenses

#### Scenario: Summarising an empty period
- **WHEN** a period contains no transactions
- **THEN** income, expenses and net balance are all zero and the result is a
  success

#### Scenario: The summary does not scale with row count
- **WHEN** the period contains many transactions
- **THEN** the summary is produced by an aggregate query, not by reading every
  row into memory

#### Scenario: Large totals do not lose precision
- **WHEN** the summed amounts are very large
- **THEN** the totals are exact to the minor unit

### Requirement: A transaction can be deleted, and the deletion can be undone

The system SHALL delete a transaction by identity and SHALL let the user restore
the most recent deletion.

#### Scenario: Deleting
- **WHEN** a transaction is deleted
- **THEN** it no longer appears in any read, and the change survives a restart

#### Scenario: Deleting something that is not there
- **WHEN** a delete names an identifier that does not exist
- **THEN** a not-found failure is reported rather than reporting success

#### Scenario: Undo restores the same transaction
- **WHEN** a deletion is undone
- **THEN** the transaction reappears with its original identifier and every
  original field value, in its original position in the ordering

#### Scenario: Undo expires
- **WHEN** the undo window passes without the user acting
- **THEN** the deletion is permanent and no undo is offered

### Requirement: The list groups transactions by day

The transaction list SHALL group transactions under day headings, with the
day's net total shown alongside each heading.

#### Scenario: Grouping
- **WHEN** the list is shown
- **THEN** transactions are grouped by the calendar day of their instant in the
  device's local time zone, most recent day first

#### Scenario: The day total is the day's net
- **WHEN** a day contains both income and expenses
- **THEN** the heading shows the net for that day

#### Scenario: Days with no transactions are not shown
- **WHEN** a period contains days with no transactions
- **THEN** no heading is rendered for those days

### Requirement: The list has an explicit empty state and an explicit error state

The transaction list SHALL distinguish, on screen, having no transactions from
having failed to read them.

#### Scenario: Empty
- **WHEN** there are no transactions
- **THEN** an empty state invites the user to record their first one
- **AND** no error is shown

#### Scenario: Storage failure
- **WHEN** reading fails
- **THEN** an error state is shown with a retry action
- **AND** it is visually distinct from the empty state, because "nothing here"
  and "we could not look" mean different things

#### Scenario: Retry after a failure
- **WHEN** the user retries and the read succeeds
- **THEN** the list replaces the error state

### Requirement: Recording a transaction validates before writing

The add form SHALL reject invalid input before any write, and SHALL report why.

#### Scenario: A zero or empty amount
- **WHEN** the amount is empty, zero, or not a number
- **THEN** the form reports the problem and nothing is written

#### Scenario: An amount with too many decimals for the currency
- **WHEN** the amount has more fraction digits than the currency allows
- **THEN** the form reports the problem and nothing is written

#### Scenario: A future-dated transaction
- **WHEN** the chosen instant is in the future
- **THEN** the form reports the problem and nothing is written, because a
  balance that includes money not yet spent is wrong

#### Scenario: A successful record
- **WHEN** valid input is submitted
- **THEN** the transaction is written, the form closes, and the new transaction
  is visible in the list without a manual refresh

### Requirement: Money parses what Money formats

`Money.parse` SHALL accept the output of `Money.digits()` for every currency,
so that the two halves of the class agree. Today they do not: `digits()` groups
VND with `.` because `vi_VN` does, and `parse` reads `.` as a decimal point.

#### Scenario: Every currency round-trips through its own digits
- **WHEN** an amount is formatted with `digits()` and parsed back for each
  currency in turn
- **THEN** the result equals the original amount
- **AND** this is asserted over `Currency.values` rather than for VND alone, so
  a currency added later is covered the day it is added

#### Scenario: The currency's own grouping separator is accepted
- **WHEN** `1.500.000` is parsed as VND
- **THEN** it is 1,500,000 đồng
- **AND** `1,500.00` parsed as USD is 150,000 cents

#### Scenario: A comma stays acceptable everywhere
- **WHEN** `1,250,000` is parsed as VND, whose separator is a dot
- **THEN** it is 1,250,000 — a shipped contract, and what someone types on a US
  keyboard

#### Scenario: A decimal separator is only the currency's own
- **WHEN** `1.5` is parsed as VND
- **THEN** it is a `FormatException`, **not** 15 and **not** 1.5 — VND has no
  decimals, so `.` can only be grouping, and `5` is not a group of three
- **AND** `12.34` parsed as USD is 1,234 cents, because `.` is USD's decimal
  separator

#### Scenario: Malformed grouping is refused rather than guessed at
- **WHEN** `1.50.000`, `1,23,456`, `.500` or `1.500.00` is parsed as VND
- **THEN** each is a `FormatException`, because a separator that is not
  separating groups of three is a typo and not an amount

#### Scenario: What was already refused stays refused
- **WHEN** `abc`, `''`, `12.345` as USD, or a value with two decimal separators
  is parsed
- **THEN** each is a `FormatException`

#### Scenario: Negatives and no grouping still work
- **WHEN** `-5.00` is parsed as USD and `1500000` as VND
- **THEN** they are −500 cents and 1,500,000 đồng

### Requirement: A currency knows how its locale writes it

`Currency` SHALL expose its grouping separator, its decimal separator and
whether its symbol leads the number, each **derived** from the locale's own
`NumberFormat` symbols rather than transcribed into a table.

#### Scenario: The separators are the locale's
- **WHEN** VND and USD are inspected
- **THEN** VND groups with `.` and USD with `,`
- **AND** USD's decimal separator is `.`

#### Scenario: The symbol's side is the locale's
- **WHEN** each currency is inspected
- **THEN** USD reports that its symbol leads and VND reports that it does not,
  which matches where `format()` actually puts it — asserted against
  `format()`'s own output, so the two cannot drift

#### Scenario: A currency with no decimals has no decimal separator
- **WHEN** VND is inspected
- **THEN** it reports no decimal separator, because a currency with zero
  decimals cannot have one

### Requirement: The amount field groups digits as they are typed

The add-transaction sheet's amount field SHALL show the amount grouped in the
currency's own style while it is being typed, and SHALL show which currency it
is in.

#### Scenario: Typing digits groups them
- **WHEN** `1500000` is typed into the field with VND selected
- **THEN** the field reads `1.500.000`

#### Scenario: What is displayed is what is saved
- **WHEN** the grouped text is submitted
- **THEN** the transaction's amount is 1,500,000 đồng — the parser accepts what
  the formatter produced, which is the requirement above being used rather than
  merely held

#### Scenario: Deleting a digit regroups the rest
- **WHEN** a digit is removed from `1.500.000`
- **THEN** the field regroups what is left rather than leaving a stale
  separator

#### Scenario: The caret does not jump to the end
- **WHEN** a digit is typed in the middle of an existing amount
- **THEN** the caret stays with the digit the user was typing at, counting by
  digits rather than by characters, because inserting a separator moves every
  character after it

#### Scenario: A decimal currency keeps its decimals typeable
- **WHEN** `1234.5` is typed with USD selected
- **THEN** the field reads `1,234.5` and the decimal part is not grouped or
  dropped

#### Scenario: The currency is shown on the side its locale puts it
- **WHEN** the field is rendered for VND
- **THEN** the symbol `₫` is shown after the number
- **AND** for USD it is shown before, matching `Currency.symbolLeads`

#### Scenario: An empty field stays empty
- **WHEN** the field holds nothing
- **THEN** no separator, no zero and no symbol-only text is inserted, so the
  placeholder is what is seen
