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
Coverage SHALL be enforced by a check that reads the source tree, not by a list
maintained by hand.

The requirement's substance is unchanged. What changed is that it is now
enforceable: the guard asserted a hardcoded list of six component names, so a
component missing from the gallery could not fail it. Button (45 variants),
PaginationDots, OnboardingIllustration and TransactionRow were all absent while
the test passed — TransactionRow since before this change.

#### Scenario: The gallery covers everything
- **WHEN** the gallery route is opened
- **THEN** it renders every implemented component in every variant, grouped by
  component, with each variant labelled by its Figma variant name

#### Scenario: A new component is not added to the gallery
- **WHEN** a public widget class is declared under
  `lib/design_system/{atoms,molecules,organisms}` and no gallery section covers it
- **THEN** verification fails, naming the file

#### Scenario: A component is deliberately not in the gallery
- **WHEN** a widget renders nothing of its own — a layout constraint with no
  Figma node
- **THEN** it may be exempted, and the exemption SHALL state its reason in the
  test

#### Scenario: A variant must build what its label says
- **WHEN** a gallery variant's label names a style, size, state or position
- **THEN** the widget it builds SHALL match that label, and no two variants of a
  component SHALL build the same thing

Counting variants is not the same as rendering different ones. Pointing all 45
Button variants at a single primary/md/normal button, labels untouched, passed
the whole gallery suite — the exact defect a gallery exists to expose.

### Requirement: Transaction row

The design system SHALL provide a row presenting one transaction: its category,
its note or category name, the time of day, and its signed amount.

Its Figma source is node **`29:70`**, which authors four variants.

The previous wording of this requirement said "Figma contains **no** transaction
row and no screen frames, so this component's layout is a decision this project
makes". Both halves were false. `get_metadata` without a node id returns an
incomplete page list, that list was read as the file, and the conclusion was
written into a requirement and an ADR. Node `29:70` is a transaction row with
four variants, and `5:14` is twelve finished screens. The requirement is corrected
here rather than left to be discovered a third time.

The implementation still diverges from `29:70` — disc 32 against 40, height 56
against ≥64, gutter 16 against 20, no `· account` meta line, and the Transfer and
Pending variants absent because the domain has no concept for either. That
reconciliation is **not** in this change; it is recorded in
`docs/design-system/figma-map.md` as outstanding.

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

#### Scenario: The divergence from Figma is recorded, not silent
- **WHEN** the implementation differs from `29:70`
- **THEN** each difference is listed in `docs/design-system/figma-map.md`

### Requirement: Button

The design system SHALL provide a button covering the full variant set of Figma
node `13:2`: five styles (primary, secondary, tertiary, ghost, destructive) × three
sizes (sm, md, lg) × three states (default, disabled, loading).

Variants SHALL be resolved through lookup tables rather than conditional
branches, so an unhandled combination is a compile error rather than a fallback.

#### Scenario: Every combination resolves
- **WHEN** each of the 45 combinations is built
- **THEN** each renders without throwing, at the height its size defines
- **AND** its background, its label colour and its label type style are asserted
  **on the rendered widget**, not on the lookup table

The emphasis is the correction. The tables were asserted directly and were
correct; nothing checked they were wired to anything. Repointing the label colour
to an unrelated token, and collapsing `lg`'s label style onto `sm`'s, each passed
the entire suite.

#### Scenario: Loading does not resize the button
- **WHEN** a button enters the loading state
- **THEN** its width is unchanged, because the label is still laid out and hidden
  rather than removed

#### Scenario: A disabled button is inert
- **WHEN** a disabled or loading button is activated
- **THEN** no callback fires

#### Scenario: The size table cannot drift
- **WHEN** a size's height, horizontal padding or icon size changes
- **THEN** verification fails against the authored values

Padding and icon size were pinned nowhere: `sm`'s padding could go from 14 to 40,
and every icon size collapse to 24, with the whole suite green. The icon test
compared the rendered size to the enum it came from — the implementation against
itself. Note that pinning them here stops them drifting; it does **not** make
them verified against Figma. `docs/design-system/figma-map.md` records that these
particular numbers were never read from a node.

#### Scenario: Only the bordered style has a border
- **WHEN** any style is rendered in the normal or disabled state
- **THEN** only `tertiary` has one, and its colour is the strong border token
  when interactive and the subtle one when disabled

### Requirement: Pagination dots

The design system SHALL provide a pagination indicator from Figma node `70:223`
in which the active position differs from the inactive ones **in width as well as
in colour**, so position is legible without colour perception.

#### Scenario: Position is readable in greyscale
- **WHEN** the indicator is rendered at any position
- **THEN** exactly one dot is active
- **AND** width alone identifies which

### Requirement: Onboarding illustration

The design system SHALL provide the decorative illustration from Figma node
`71:59` — a hairline ring, a filled halo, a centre glyph and four accent dots —
themed by a chart-palette slot rather than by a colour passed in.

It SHALL be drawn from tokens rather than shipped as an image, so
`tool/check_design_tokens.dart` can see inside it. That gate cannot inspect an
SVG.

#### Scenario: Geometry holds at any width
- **WHEN** the illustration is rendered narrower than the 353px Figma authors
- **THEN** the ring, halo and glyph remain concentric
- **AND** both axes scale by the same factor

This scenario exists because they did not. Only horizontal positions were scaled,
so the three were concentric at exactly 353px and at no other width — about 20px
apart at 280px wide. The component had no test file at all; its 100% line
coverage came from another test rendering it in passing.

#### Scenario: A wide screen does not get a magnified illustration
- **WHEN** the available width exceeds 353px
- **THEN** the illustration holds its authored size and centres
