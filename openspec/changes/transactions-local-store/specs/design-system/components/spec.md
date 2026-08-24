## ADDED Requirements

### Requirement: Transaction row

The design system SHALL provide a row presenting one transaction: its category,
its note or category name, the time of day, and its signed amount.

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
