## ADDED Requirements

### Requirement: One period selection drives every Insights screen

The Insights screens SHALL offer the four periods `77:32` authors — this month,
3 months, 6 months and year — and changing the period SHALL change the data and
not the layout.

Annotation `77:291`: *"month · 3M / 6M / Year change the period, not the
layout"*.

#### Scenario: Every period is offered
- **WHEN** an Insights screen is shown
- **THEN** all four periods are selectable and exactly one is selected

#### Scenario: The layout survives a period change
- **WHEN** the period changes
- **THEN** the same sections appear in the same order
- **AND** only the figures and the period label differ

#### Scenario: The period is shared across screens
- **WHEN** the period is changed on one Insights screen and another is opened
- **THEN** the second screen shows the same period

#### Scenario: A period resolves to a window ending now
- **WHEN** a period is resolved against a clock
- **THEN** its window ends at that instant and starts at the beginning of the
  earliest included month
- **AND** the window is computed in UTC

### Requirement: An empty period shows an empty state, not an empty chart

When the selected period contains no spending, a screen SHALL show an
`EmptyState` instead of a chart.

Annotation `77:291`: *"empty period shows an EmptyState instead of a 0%
donut"*. A ring with no segments and a legend with no rows is a chart claiming
to describe data that is not there.

#### Scenario: No spending in the period
- **WHEN** the period contains no expense
- **THEN** an empty state is shown and no chart is rendered

#### Scenario: Spending appears
- **WHEN** the period contains at least one expense
- **THEN** the chart is shown and the empty state is not

#### Scenario: Income alone is not spending
- **WHEN** the period contains income but no expense
- **THEN** the spend chart still shows its empty state, because there is no
  spending to describe

### Requirement: Insights overview ranks spend by category and names the top merchants

`07.01` SHALL implement node `77:2`: the period switcher, a `DonutChart` of
spend by category for the period, and the three largest single transactions
below it.

#### Scenario: Categories are ranked and capped by the chart
- **WHEN** the overview is shown for a period with spending
- **THEN** the donut receives one datum per spending category, and the donut's
  own eight-segment cap and neutral `Other` fold apply

#### Scenario: The centre reports the period's total
- **WHEN** the overview is shown
- **THEN** the donut's centre total equals the period's total spend
- **AND** its period label names the selected period

#### Scenario: The top three are the three largest
- **WHEN** the overview is shown
- **THEN** exactly the three largest expenses in the period are listed, largest
  first

#### Scenario: Fewer than three
- **WHEN** the period contains one or two expenses
- **THEN** that many rows are listed and nothing is padded

### Requirement: Cash flow shows income against expenses on one axis

`07.02` SHALL implement node `77:294`: the period switcher, a
`MonetaLineChart`, two `StatTile`s, and a per-month list of net figures.

#### Scenario: One point per month, both series equal in length
- **WHEN** cash flow is shown
- **THEN** both series carry one point per month in the period, oldest first
- **AND** the two series have the same number of points

#### Scenario: The tiles report the period, not the month
- **WHEN** cash flow is shown
- **THEN** one tile reports total income for the period and one total expenses

#### Scenario: A month with no activity is still a month
- **WHEN** a month inside the period has no transactions
- **THEN** it contributes a zero point to both series rather than being skipped,
  so the x positions stay aligned with the calendar

#### Scenario: The per-month list is newest first
- **WHEN** the month list is shown
- **THEN** months are listed newest first, each with its net and its
  income/expense split

### Requirement: Category breakdown reuses ProgressBar as its bar mark

`07.03` SHALL implement node `77:440` with `MonetaProgressBar` as the bar,
ranked largest first, and SHALL NOT introduce a chart component.

Annotation `77:587`: *"ProgressBar is reused as the bar mark rather than adding
a HorizontalBarChart component; one series means one hue, so every bar is the
same colour and rank is carried by length and order."*

#### Scenario: Rank is carried by length and order
- **WHEN** the breakdown is shown
- **THEN** categories are listed largest first
- **AND** each bar's fraction is that category's share of the largest, so the
  first bar is full

#### Scenario: One series, one hue
- **WHEN** the breakdown is shown
- **THEN** every bar is drawn in the same colour

#### Scenario: No new chart component
- **WHEN** the breakdown's source is inspected
- **THEN** it composes `MonetaProgressBar` and declares no painter of its own

### Requirement: The period picker is a bottom sheet of radio options

`07.05` SHALL implement node `81:508`: a `MonetaBottomSheet` whose content is a
`MonetaRadioGroup` of the period options, with the current period selected.

#### Scenario: The current period is selected
- **WHEN** the picker opens
- **THEN** exactly one option is selected, and it is the active period

#### Scenario: Choosing a period applies it
- **WHEN** an option is chosen
- **THEN** the period changes and the picker closes

#### Scenario: Dismissing changes nothing
- **WHEN** the picker is closed without choosing
- **THEN** the period is unchanged

### Requirement: Insights reports a read failure rather than showing zero

When the transactions cannot be read, an Insights screen SHALL show an error
state distinct from its empty state.

#### Scenario: The repository fails
- **WHEN** reading transactions returns a failure
- **THEN** an error state is shown
- **AND** it is distinguishable from "this period has no spending"

### Requirement: Insights aggregation boundaries

The aggregation SHALL be correct for degenerate ledgers.

#### Scenario: An empty ledger
- **WHEN** there are no transactions at all
- **THEN** every aggregate is zero and nothing throws

#### Scenario: Only income
- **WHEN** the ledger holds income and no expense
- **THEN** spend aggregates are zero and the cash-flow income series is not

#### Scenario: A single transaction
- **WHEN** the ledger holds one expense
- **THEN** it is 100% of its category and of the total

#### Scenario: Very large amounts
- **WHEN** amounts near the maximum integer minor units are present
- **THEN** totals stay exact and no percentage exceeds 100

#### Scenario: A currency mismatch
- **WHEN** the ledger holds more than one currency
- **THEN** the mismatch is reported rather than summed
