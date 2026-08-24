## MODIFIED Requirements

### Requirement: Balance card

The balance card SHALL present a total balance, a safe-to-spend line and income
and expense totals for the period, on the brand gradient, with a control that
hides every figure. It SHALL accept the safe-to-spend period's end as a date and
format that date itself.

#### Scenario: Default state shows the figures
- **WHEN** the card is shown with balance, safe-to-spend, income and expense
  amounts
- **THEN** all four are rendered with the amount and label type styles on the
  brand gradient
- **AND** income is prefixed with a plus sign and expense with a minus sign

#### Scenario: The period end is a date, not a string
- **WHEN** the card is constructed
- **THEN** it accepts the safe-to-spend period's end as a date value
- **AND** it does not accept a pre-formatted string, so two callers cannot write
  the same date differently

#### Scenario: The date is formatted consistently with the rest of the app
- **WHEN** the card renders the safe-to-spend line
- **THEN** the date is formatted through the same shared formatting the
  application uses elsewhere, in the device's local time zone

#### Scenario: Masked state hides every figure
- **WHEN** the card is masked
- **THEN** no digit from any of the four amounts is present in the rendered output
- **AND** the labels, the gradient and the layout are unchanged
- **AND** the mask control shows the inverse icon

#### Scenario: The period end is not a figure to hide
- **WHEN** the card is masked
- **THEN** the safe-to-spend date may still be shown, because it reveals nothing
  about how much money there is

#### Scenario: Masking is reversible from the card
- **WHEN** the mask control is activated
- **THEN** the card reports the request to its caller
- **AND** the card does not itself decide to persist the preference

#### Scenario: A zero balance is a normal state
- **WHEN** the balance is zero
- **THEN** it renders as a formatted zero, not as an empty or placeholder card

### Requirement: Transaction row

The design system SHALL provide a row presenting one transaction: its category,
its note or category name, the time of day, and its signed amount. The row SHALL
support a masked form in which the amount is hidden.

Figma contains **no** transaction row and no screen frames, so this component's
layout is a decision this project makes from existing tokens and `CategoryIcon`
rather than a transcription. The decision is recorded in `docs/adr/`.

#### Scenario: An expense row
- **WHEN** a row shows an expense
- **THEN** the amount is prefixed with a minus sign and uses the expense colour

#### Scenario: An income row
- **WHEN** a row shows income
- **THEN** the amount is prefixed with a plus sign and uses the income colour

#### Scenario: The category is shown by its disc
- **WHEN** a row is rendered
- **THEN** the category's tint and glyph come from the shared category binding,
  so a category looks the same here as in a budget card or a chart

#### Scenario: A row without a note
- **WHEN** a transaction has no note
- **THEN** the category name is shown in its place rather than blank space

#### Scenario: A long note
- **WHEN** the note is longer than the available width
- **THEN** it truncates on one line with an ellipsis
- **AND** the amount is neither displaced nor clipped

#### Scenario: The row takes domain types
- **WHEN** the row is constructed
- **THEN** it accepts the transaction's money value and direction, not a
  pre-formatted string, so formatting cannot diverge from the rest of the app

#### Scenario: A masked row hides its amount
- **WHEN** a row is masked
- **THEN** no digit belonging to the amount is present in the rendered output
- **AND** the sign is not shown either, because a visible plus or minus reveals
  whether money came in or went out

#### Scenario: A masked row keeps everything that is not money
- **WHEN** a row is masked
- **THEN** the category disc, the title and the time of day are unchanged
- **AND** the row occupies the same height, so masking does not reflow the list

#### Scenario: The mask width does not depend on the amount
- **WHEN** two masked rows show very different amounts
- **THEN** their masks are identical
- **AND** the width does not track the number of digits, because that would leak
  the magnitude the mask exists to hide

#### Scenario: A masked row still uses its direction colour
- **WHEN** a masked row is rendered
- **THEN** the mask uses a de-emphasised colour rather than the income or expense
  colour, because a green or red mask would reveal the direction the sign was
  hidden to conceal
