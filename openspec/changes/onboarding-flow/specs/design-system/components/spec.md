## Purpose

The three components this change added, and a correction to how the gallery
requirement is enforced.

## ADDED Requirements

### Requirement: Button

The design system SHALL provide a button covering the full variant set of Figma
node `13:2`: five styles (primary, secondary, tertiary, ghost, danger) × three
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

## MODIFIED Requirements

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
