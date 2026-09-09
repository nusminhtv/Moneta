## ADDED Requirements

### Requirement: Budgets is a sub-screen of Home, not a tab

The budget screens SHALL render inside the application shell with **Home** as the
active destination.

Annotation `04.01`: *"Bottom nav stays on Home because Budgets is a Home
sub-screen, not a tab."* Getting the active tab wrong for a screen is called a
real defect by `39:243`'s own description.

#### Scenario: The overview keeps Home lit
- **WHEN** the budgets overview is shown
- **THEN** the bottom navigation's active destination is Home
- **AND** no fifth destination appears

#### Scenario: The detail screen keeps Home lit
- **WHEN** a budget's detail is shown
- **THEN** the active destination is still Home

#### Scenario: The create flow has no bottom navigation
- **WHEN** either create step is shown
- **THEN** no bottom navigation is rendered, matching `66:378` and `66:488`,
  which draw a bottom safe area and no bar

### Requirement: The overview lists budgets worst first

The overview (`66:91`) SHALL show a period switcher, a total ring, and one card
per budget ordered by fraction used, descending.

#### Scenario: An over-limit budget is above the fold
- **WHEN** four budgets are shown and one is over its limit
- **THEN** it is the first card

#### Scenario: The total ring summarises all of them
- **WHEN** the overview is rendered
- **THEN** the ring's fraction is total spend over total limit across the
  budgets shown, not an average of their fractions

#### Scenario: The period switcher changes the window
- **WHEN** a segment is selected
- **THEN** every card recomputes against that period's window
- **AND** exactly one segment is selected

The switcher selects **which period to look at**, not which kind of budget to
show. `66:117` labels its three segments `Jul`, `Aug`, `Sep`. A budget's period
is fixed when it is created, so there is nothing to switch between; filtering by
it made a segment able to empty a list of real budgets.

#### Scenario: Each budget steps by its own period
- **WHEN** the selected segment is one period back and budgets use different
  periods
- **THEN** a weekly budget recomputes against the previous week and a monthly
  one against the previous month
- **AND** no budget is omitted for using a period other than the selected one

#### Scenario: Segment labels name the periods when they can
- **WHEN** every budget shares one period
- **THEN** the labels name the **calendar period** at each offset — the calendar
  month for monthly, the calendar year for yearly, and the calendar week by its
  Monday for weekly
- **AND** when periods are mixed, or there are no budgets to read a period from,
  the labels are relative instead, because a month name beside a weekly window
  would be wrong

This said "the start date for weekly", which is not implementable. The label row
is reached whenever budgets share a period *type*, never a common anchor, so two
weekly budgets anchored on the 2nd and the 7th arrive with different window
starts and one label cannot name both. Left as written, it was satisfied by
labelling today's date shifted by whole weeks — "Sep 10" over a week beginning
Sep 7.

#### Scenario: A label may not coincide with the window a card shows
- **WHEN** a budget's anchor falls inside a calendar period rather than on its
  boundary
- **THEN** its card still recomputes against its own window
- **AND** the segment label still names the calendar period, which may begin
  earlier than that window

A budget anchored on the 20th has windows spanning two calendar months. The label
names one of them. This is a consequence of one label row serving every budget on
the screen, and is stated so that it is not later mistaken for the defect it
replaced.

#### Scenario: A budget younger than the selected period
- **WHEN** a budget did not exist during the selected period
- **THEN** it is absent from that period rather than shown against its opening
  window
- **AND** its absence does not read as the wallet having no budgets

### Requirement: An empty period is distinguished from an empty wallet

The overview SHALL distinguish having no budgets at all from having none in the
period being looked at.

#### Scenario: No budgets in this period, but budgets exist
- **WHEN** the selected period contains no budgets and budgets exist elsewhere
- **THEN** the screen says so and offers no create action
- **AND** the period switcher remains reachable, so a period with data can be
  chosen
- **AND** `66:277`'s first-run copy and its create action are not shown, because
  offering to create a budget to someone who has three is the wrong answer

### Requirement: The empty state offers the one action that helps

With no budgets, the overview SHALL show the empty state of `66:277` with a
primary action that starts the create flow.

#### Scenario: No budgets
- **WHEN** there are no budgets
- **THEN** the empty state is shown with an action
- **AND** no period switcher, ring or card is rendered

### Requirement: Creating a budget takes two steps and can be abandoned

The create flow SHALL collect a category (`66:378`), then an amount, period and
options (`66:488`), and SHALL NOT write anything until the final action.

#### Scenario: Leaving step 2 writes nothing
- **WHEN** the user reaches step 2 and goes back
- **THEN** no budget exists

#### Scenario: Step 2 cannot be reached without a category
- **WHEN** no category is chosen
- **THEN** the step-1 action is disabled

#### Scenario: A zero amount cannot be submitted
- **WHEN** the amount is zero
- **THEN** the submit action is disabled and the amount input shows its error
  state with a message

#### Scenario: An unavailable category is disabled, not hidden
- **WHEN** step 1 is shown
- **THEN** income categories are rendered and disabled, not removed
- **AND** a category that already has a budget for this period is also disabled
- **AND** the grid still lists every category, so the user is not left
  wondering where one went

#### Scenario: The reason a category is disabled is written down
- **WHEN** any category in the grid is disabled
- **THEN** the screen states why in copy below the grid
- **AND** the reason is not left to be inferred from the dimming, which a
  low-vision user may not see at all

#### Scenario: A disabled category cannot be selected
- **WHEN** a disabled category is activated
- **THEN** the selection does not change and the step-1 action stays disabled

#### Scenario: A duplicate budget for a category is refused
- **WHEN** a budget already exists for the chosen category and period
- **THEN** creating a second one fails with a validation message naming the
  existing one, rather than silently producing two budgets that split the same
  spend

### Requirement: The detail screen leads with the daily allowance

The detail screen (`67:359` / `67:524`) SHALL show the ring, two stat tiles, and
the transactions that make up the spend.

Annotation `04.05`: *"The number the user actually needs is the daily allowance —
the limit alone does not tell them what they can spend today."*

#### Scenario: On track
- **WHEN** a budget is below its threshold
- **THEN** the ring uses the income colour and no banner is shown

#### Scenario: Over limit
- **WHEN** spend exceeds the limit
- **THEN** a banner appears above the ring, matching `67:548`
- **AND** the ring uses the expense colour

#### Scenario: The over-limit banner names the date
- **WHEN** the banner is shown
- **THEN** it states when the budget was passed
- **AND** a banner that only says the budget is over fails this

#### Scenario: The daily-allowance tile is replaced, not made negative
- **WHEN** a budget is over its limit
- **THEN** no daily-allowance tile is shown
- **AND** a tile reading "Over by" with the amount takes its place

Annotation `04.06`: *"there is no daily-allowance tile here — it would be
negative and meaningless, so it is replaced by 'Over by'. Swapping a tile rather
than showing a negative number is a deliberate choice."*

#### Scenario: The listed transactions are the ones counted
- **WHEN** the detail lists transactions
- **THEN** every listed transaction is one that contributed to the spend
- **AND** a transaction excluded for being income, another category, or a
  foreign currency is not listed

#### Scenario: Skipped foreign-currency transactions are disclosed
- **WHEN** the window contains a transaction in another currency
- **THEN** the screen says how many were not counted
- **AND** it does not silently under-report
