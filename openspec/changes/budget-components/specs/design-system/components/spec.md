## ADDED Requirements

### Requirement: Circular progress ring

The design system SHALL provide a ring progress indicator covering the full
variant set of Figma node `25:272`: three states (`Under`, `Near`, `Over`)
across three sizes (`Sm` 48, `Md` 72, `Lg` 120).

The state SHALL be **derived from the fraction**, not passed in, using the same
`BudgetStatus.fromFraction` that `MonetaProgressBar` uses. A ring and a bar
showing the same budget cannot then disagree about whether it is over.

`Sm` SHALL show no label. `Md` and `Lg` SHALL show a percentage label derived
from the same fraction that drives the arc — `Md` in `label/md`, `Lg` in
`display/amount-md`, as Figma authors them.

Figma gives `CircularProgress` no TEXT property; its labels are direct instance
overrides, which annotation `04.01` records as ledger entry I10. The component
SHALL NOT accept a label string, so a ring whose label contradicts its arc is
not expressible.

#### Scenario: The colour follows the same rule as the bar
- **WHEN** a ring is given 0.4, then 0.9, then 1.2
- **THEN** its arc is the income, warning and expense colour respectively
- **AND** each matches the fill colour `MonetaProgressBar` gives the same
  fraction

#### Scenario: Each size renders at its authored diameter
- **WHEN** `Sm`, `Md` and `Lg` are rendered
- **THEN** they occupy 48, 72 and 120 logical pixels square

#### Scenario: Small shows no label
- **WHEN** a `Sm` ring is given 0.62
- **THEN** no text is rendered
- **AND** the same fraction at `Md` renders "62%"

#### Scenario: The label cannot disagree with the arc
- **WHEN** the component's public API is inspected
- **THEN** it exposes no parameter that sets the label text

#### Scenario: An over-budget arc stops at full
- **WHEN** a ring is given 1.4
- **THEN** the arc sweeps a full turn and no further
- **AND** the label reads "140%", because the number is the fact the ring is
  hiding

#### Scenario: A degenerate fraction does not throw
- **WHEN** a ring is given NaN, negative infinity, or -0.5
- **THEN** it renders an empty arc and does not throw

### Requirement: Segmented control

The design system SHALL provide a segmented control (`36:168`) composed of
segment items (`36:167`), covering both item variants: selected and unselected.

A selected segment SHALL be filled with the raised surface and carry primary
text; an unselected segment SHALL paint no fill and carry secondary text. The
fill is a luminance difference, so selection survives greyscale.

The control SHALL accept 2 to 4 segments. Figma's note on `36:161` is explicit
that a variant per segment-count × active-index "explodes fast", so segment
count SHALL NOT be a variant.

Segments SHALL share the width equally, because the design's own instances are
112.33 wide inside a 353 track — a value no author types, which is what an
equal division of the remaining space looks like when it is written down.

#### Scenario: Exactly one segment is selected
- **WHEN** a control with three segments and `selectedIndex` 1 is rendered
- **THEN** the second segment has the raised-surface fill and primary text
- **AND** the other two paint no fill and carry secondary text

#### Scenario: Segments divide the track equally
- **WHEN** a control with three segments is laid out in a 353px column
- **THEN** the three segments have equal widths
- **AND** each segment's width is independent of its label's length

#### Scenario: Selecting a segment reports its index
- **WHEN** the third segment is tapped
- **THEN** `onChanged` is called once with 2
- **AND** tapping the already-selected segment still reports its index, so a
  caller may treat it as a refresh

#### Scenario: The touch target clears the minimum
- **WHEN** any segment is rendered
- **THEN** its hit area is at least 44 logical pixels tall, even though the
  segment itself is drawn 36 tall inside a 44 track

### Requirement: Stat tile

The design system SHALL provide a KPI tile covering all three variants of Figma
node `35:137`: `Up`, `Down` and `Flat`.

The delta SHALL be signalled by an arrow **and** a colour, never by colour
alone — `35:114`'s description requires this in as many words. `Flat` SHALL show
no arrow and tertiary text, which is itself the third distinguishable state.

The tile SHALL take a `Money` value, not a formatted string, per the rule that
design-system widgets take domain types.

#### Scenario: Direction drives both the arrow and the colour
- **WHEN** `Up`, `Down` and `Flat` are rendered
- **THEN** `Up` shows an up-right arrow in the income colour, `Down` a
  down-left arrow in the expense colour, and `Flat` no arrow in tertiary text
- **AND** removing the arrow from `Up` or `Down` leaves colour as the only
  signal, which a test SHALL fail on

#### Scenario: Two tiles fit the content column
- **WHEN** two tiles are placed side by side in a 353px column with a 12px gap
- **THEN** neither overflows
- **AND** the pair fills the column

#### Scenario: A long value does not overflow the tile
- **WHEN** a tile is given an amount of 999,999,999,999 ₫ and a long label
- **THEN** nothing overflows and the tile's height is unchanged from the short
  case, or grows — it does not clip

### Requirement: Amount input

The design system SHALL provide the hero amount display of Figma node `36:76`
in both states: `Default` and `Error`.

The amount SHALL render with tabular figures, as `36:64` requires, so the number
does not shift width as digits are typed.

Figma's own description of `36:76` says the error variant "differs by colour
only". The Dart component SHALL NOT reproduce that: an error SHALL require a
message, so the state always carries a signal that survives greyscale.

The caret is decorative. It SHALL be hidden from assistive technology.

#### Scenario: Error is not signalled by colour alone
- **WHEN** the error state is rendered
- **THEN** the amount is the expense colour
- **AND** a message is displayed
- **AND** the type does not allow an error state with no message

#### Scenario: Digits do not shift as they are typed
- **WHEN** the amount changes from 111,111 to 888,888
- **THEN** the rendered width is unchanged

#### Scenario: The currency glyph follows the amount
- **WHEN** a `Money` in VND is displayed
- **THEN** the glyph is ₫ and it uses `heading/h2`
- **AND** a `Money` in USD displays $ instead

#### Scenario: The caret is decorative
- **WHEN** the semantics tree is read
- **THEN** the caret contributes no node

### Requirement: Every new component is in the gallery

Each component added by this change SHALL be registered in the gallery in every
variant Figma authors, with `expectedVariants` matching the Figma count.

#### Scenario: The variant counts match Figma
- **WHEN** the gallery's sections are checked against their `expectedVariants`
- **THEN** circular progress has 9, the segment item 2, the stat tile 3 and the
  amount input 2
- **AND** registering any of them with fewer variants fails the gate
