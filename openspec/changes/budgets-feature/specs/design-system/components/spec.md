## ADDED Requirements

### Requirement: The near-limit threshold is data-driven

Every component that derives a budget status SHALL accept the threshold at which
"near the limit" begins, defaulting to 0.8.

Annotation `04.04`: *"'Alert me at 80%' is what drives BudgetCard's NearLimit
state — the 80% threshold is configurable here, so the component's warning
colour is data-driven, not hardcoded."*

`budget-components` shipped `BudgetStatus.nearLimitThreshold` as a constant and
wired `MonetaCircularProgress` to it. That was wrong against the design before
this change opened; it is corrected here rather than left for the screens to work
around.

The status SHALL remain **derived**. A caller may move the boundary; it may not
pass a status that contradicts the numbers.

#### Scenario: A budget's own threshold moves the boundary
- **WHEN** a fraction of 0.7 is classified with a threshold of 0.6
- **THEN** the status is near-limit
- **AND** the same fraction with the default 0.8 is on-track

#### Scenario: Over the limit ignores the threshold
- **WHEN** a fraction above 1.0 is classified with any threshold
- **THEN** the status is over

#### Scenario: A threshold of 1.0 means warn only at the limit
- **WHEN** the threshold is 1.0 and the fraction is 0.99
- **THEN** the status is on-track
- **AND** at exactly 1.0 it is near-limit, because the limit is reached and not
  exceeded

#### Scenario: The bar, the ring and the card agree at a moved boundary
- **WHEN** all three are given the same fraction and the same non-default
  threshold
- **THEN** they render the same status colour

#### Scenario: There is still no way to pass a status
- **WHEN** the public API of the bar, the ring and the card is inspected
- **THEN** none accepts a status directly

## MODIFIED Requirements

### Requirement: Budget card

The budget card SHALL present one category's spend against its limit, with a
progress bar and a status note, and SHALL make its over-limit state survive
greyscale.

The threshold at which the warning state begins SHALL be a parameter defaulting
to 0.8, not a constant.

#### Scenario: Under 80% of the limit
- **WHEN** spend is below 80% of the limit
- **THEN** the amount, note and bar use the income colour
- **AND** the card border is the subtle border colour

#### Scenario: At or above 80% but at or below the limit
- **WHEN** spend is at least 80% of the limit and does not exceed it
- **THEN** the amount, note and bar use the warning colour

#### Scenario: A budget with a non-default threshold warns at its own boundary
- **WHEN** a card with a threshold of 0.5 is 60% spent
- **THEN** it uses the warning colour
- **AND** an identical card left at the default 0.8 uses the income colour

#### Scenario: Above the limit
- **WHEN** spend exceeds the limit
- **THEN** the amount, note and bar use the expense colour
- **AND** the card border is the expense colour, so the state is distinguishable
  without relying on hue

#### Scenario: The bar never overflows its track
- **WHEN** spend is far above the limit
- **THEN** the bar fills its track exactly and does not paint outside it

#### Scenario: A zero limit does not break the bar
- **WHEN** the limit is zero
- **THEN** the bar renders empty rather than dividing by zero
- **AND** the card is treated as over limit when any amount has been spent

#### Scenario: A long category name truncates
- **WHEN** the category name is longer than the available width
- **THEN** it truncates with an ellipsis on a single line
- **AND** the amount on the right is not displaced or clipped

### Requirement: Progress bar

The progress bar SHALL render a fraction of a track, with the fill colour derived
from the fraction, in the sizes the design defines.

The threshold at which the fill turns warning SHALL be a parameter defaulting to
0.8, not a constant.

#### Scenario: The fill is proportional
- **WHEN** the bar is given a fraction
- **THEN** the filled width is that fraction of the track width

#### Scenario: Out-of-range fractions are clamped
- **WHEN** the bar is given a fraction below zero or above one
- **THEN** it renders empty or full respectively, and never paints outside the
  track

#### Scenario: A moved threshold changes the fill colour
- **WHEN** a bar at 0.7 is given a threshold of 0.6
- **THEN** the fill is the warning colour
- **AND** the same bar at the default threshold is the income colour
