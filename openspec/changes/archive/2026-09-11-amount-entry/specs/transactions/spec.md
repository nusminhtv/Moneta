## ADDED Requirements

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
