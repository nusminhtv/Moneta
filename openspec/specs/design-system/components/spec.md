# design-system/components Specification

## Purpose
Defines the behaviour of Moneta's shared UI components — what each one shows, the
full set of states it must support, and which state decisions the component owns
rather than delegating to its caller.

## Requirements

### Requirement: Components own derived state, callers do not

A component whose appearance depends on data SHALL compute that appearance from
the data it is given. A caller SHALL NOT be able to select an appearance that
contradicts the data.

#### Scenario: Budget colour follows spend, not a caller's choice
- **WHEN** a budget component is given a spent amount and a limit
- **THEN** it selects its own colour: income colour below 80% of the limit,
  warning colour from 80% up to the limit, expense colour above the limit
- **AND** its public interface offers no way to pass a colour or a state name

#### Scenario: Category appearance follows the category
- **WHEN** a component displays a spend category
- **THEN** the tint and glyph are determined by the category alone
- **AND** the same category renders identically everywhere it appears

### Requirement: Components accept domain types

A component that displays a monetary amount SHALL accept the money type, not a
pre-formatted string, so that formatting cannot diverge between callers.

#### Scenario: An amount is passed as money
- **WHEN** a component displays an amount
- **THEN** its interface takes the money type and formats it internally
- **AND** the rendered text matches that currency's formatting rules

#### Scenario: Two currencies are mixed
- **WHEN** a component is given amounts in different currencies for the same
  calculation
- **THEN** the failure is raised rather than silently rendering a wrong total

### Requirement: Full variant coverage

Every component derived from a Figma component set SHALL implement every variant
in that set. A partially implemented component set is not complete.

#### Scenario: Every Figma variant is reachable
- **WHEN** a Figma component set defines N variants
- **THEN** all N are reachable through the component's public interface
- **AND** each has a test asserting its distinguishing visual property

### Requirement: Balance card

The balance card SHALL present a total balance, a safe-to-spend line and income
and expense totals for the period, on the brand gradient, with a control that
hides every figure.

#### Scenario: Default state shows the figures
- **WHEN** the card is shown with balance, safe-to-spend, income and expense
  amounts
- **THEN** all four are rendered with the amount and label type styles on the
  brand gradient
- **AND** income is prefixed with a plus sign and expense with a minus sign

#### Scenario: Masked state hides every figure
- **WHEN** the card is masked
- **THEN** no digit from any of the four amounts is present in the rendered output
- **AND** the labels, the gradient and the layout are unchanged
- **AND** the mask control shows the inverse icon

#### Scenario: Masking is reversible from the card
- **WHEN** the mask control is activated
- **THEN** the card reports the request to its caller
- **AND** the card does not itself decide to persist the preference

#### Scenario: A zero balance is a normal state
- **WHEN** the balance is zero
- **THEN** it renders as a formatted zero, not as an empty or placeholder card

### Requirement: Budget card

The budget card SHALL present one category's spend against its limit, with a
progress bar and a status note, and SHALL make its over-limit state survive
greyscale.

#### Scenario: Under 80% of the limit
- **WHEN** spend is below 80% of the limit
- **THEN** the amount, note and bar use the income colour
- **AND** the card border is the subtle border colour

#### Scenario: At or above 80% but at or below the limit
- **WHEN** spend is at least 80% of the limit and does not exceed it
- **THEN** the amount, note and bar use the warning colour

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

### Requirement: Bottom navigation

The bottom navigation SHALL present four destinations plus a central add action,
indicate exactly one active destination, and reserve the device's bottom safe area.

#### Scenario: Exactly one destination is active
- **WHEN** the bar is shown for a destination
- **THEN** that destination's icon and label use the brand-on-surface colour and
  every other destination uses the tertiary text colour
- **AND** exactly one destination is in the active state

#### Scenario: The add action is not a destination
- **WHEN** the central add action is activated
- **THEN** it reports an add request, distinct from destination selection
- **AND** activating it does not change which destination is active

#### Scenario: Selecting a destination reports it
- **WHEN** a destination is activated
- **THEN** the bar reports that destination to its caller and does not navigate
  by itself

#### Scenario: The bar respects the bottom safe area
- **WHEN** the bar is rendered on a device with a bottom inset
- **THEN** the tab row sits above the inset and the bar's background extends
  through it

### Requirement: Progress bar

The progress bar SHALL render a fraction of a track, with the fill colour derived
from the fraction, in the sizes the design defines.

#### Scenario: The fill is proportional
- **WHEN** the bar is given a fraction
- **THEN** the filled width is that fraction of the track width

#### Scenario: Out-of-range fractions are clamped
- **WHEN** the bar is given a fraction below zero or above one
- **THEN** it renders empty or full respectively, and never paints outside the
  track

### Requirement: Icons

The application SHALL render the Figma icon set from the exported vector assets,
addressable by name, at the sizes the design uses.

#### Scenario: An icon is requested by name
- **WHEN** an icon name from the Figma set is requested
- **THEN** the corresponding exported vector is rendered at the requested size
  and tinted with the requested colour

#### Scenario: The icon set is complete
- **WHEN** the icon catalogue is enumerated
- **THEN** it contains every icon present on the Figma iconography page — 50 —
  and each entry resolves to an asset that exists in the bundle

#### Scenario: Every stroked icon keeps the design stroke weight
- **WHEN** any icon drawn with strokes is inspected
- **THEN** its stroke weight is 1.75, the weight the design is drawn at
- **AND** a re-export at a different weight fails verification rather than
  shipping

#### Scenario: A multi-colour brand mark is not tinted
- **WHEN** an icon that carries its own colours is rendered with a requested tint
- **THEN** the tint is ignored and the icon's own colours are preserved
- **AND** every other icon in the set does honour the requested tint

#### Scenario: An unknown icon name is not substituted
- **WHEN** an icon is looked up by a name that is not in the set
- **THEN** the lookup reports absence rather than returning a placeholder icon

### Requirement: Component gallery

The application SHALL provide a route that renders every design-system component
in every variant, so fidelity can be checked against Figma in a running app.

#### Scenario: The gallery covers everything
- **WHEN** the gallery route is opened
- **THEN** it renders every implemented component in every variant, grouped by
  component, with each variant labelled by its Figma variant name

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
