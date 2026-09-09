## ADDED Requirements

### Requirement: ChartLegendItem implements all nine authored slots

`ChartLegendItem` SHALL implement the full Figma variant set from node `47:47`:
`Slot=1` through `Slot=8`, plus `Slot=Other`.

A slot is chosen, never a colour. The component's own description: *"only the
swatch carries the series colour"*, and the eight-slot palette was validated as a
set, so a caller picking a colour could place two adjacent series outside the
validated contrast band.

#### Scenario: Slot coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all nine legend slots are registered and distinguishable

#### Scenario: The swatch carries identity and the text does not
- **WHEN** a legend row is rendered for any slot
- **THEN** the swatch is that slot's chart colour
- **AND** the label, percentage and amount are drawn in text tokens, identical
  across every slot

#### Scenario: The neutral slot is not a ninth colour
- **WHEN** `Slot=Other` is rendered
- **THEN** its swatch is the neutral `textTertiary`, transcribed from `47:42`
- **AND** it is not any of the eight chart slots

#### Scenario: A long category name does not push out the figures
- **WHEN** a label is longer than the row can show
- **THEN** the label truncates
- **AND** the percentage and the amount remain fully visible, because a clipped
  amount is a lost amount

#### Scenario: Amounts are money, not strings
- **WHEN** a legend row is given an amount
- **THEN** it accepts a `Money` value and formats it itself

### Requirement: DonutChart always ships its legend

`DonutChart` SHALL implement node `47:48`, and SHALL render its legend
unconditionally. There SHALL be no parameter, flag or subclass by which a caller
can suppress it.

Annotation `77:284`: *"the DonutChart legend is part of the component and not
optional: two of the eight chart slots fall below 3:1 against the dark surface,
so the visible labels ARE the required contrast relief."* A hidden legend does
not make the chart denser; it makes two of its eight categories unreadable.

#### Scenario: The legend cannot be turned off
- **WHEN** the public API of the donut is inspected
- **THEN** it exposes no way to hide, empty or replace the legend
- **AND** a rendered donut with two or more segments always shows one legend row
  per segment

#### Scenario: Ring and legend agree
- **WHEN** a donut is rendered with several segments
- **THEN** every segment in the ring has exactly one legend row
- **AND** each row's slot colour equals its segment's colour

### Requirement: DonutChart caps at eight segments and folds the rest

`DonutChart` SHALL show at most eight coloured segments. Categories beyond the
eighth SHALL be combined into a single neutral `Other` segment whose amount is
their sum.

#### Scenario: Nine categories
- **WHEN** nine categories are supplied
- **THEN** eight coloured segments are shown, largest first
- **AND** a ninth neutral `Other` segment carries the sum of the remainder
- **AND** the legend shows nine rows, the last of them `Other`

#### Scenario: Eight categories exactly
- **WHEN** exactly eight categories are supplied
- **THEN** eight coloured segments are shown and no `Other` segment appears

#### Scenario: The folded total is not lost
- **WHEN** categories are folded into `Other`
- **THEN** the sum of every segment equals the sum of every supplied category
- **AND** the centre total equals that same sum

### Requirement: DonutChart boundary inputs

`DonutChart` SHALL render without throwing for degenerate data, and SHALL NOT
present a misleading chart in place of absent data.

#### Scenario: No categories
- **WHEN** an empty category list is supplied
- **THEN** the donut renders an empty ring with no segments and no legend rows
- **AND** it does not draw a full ring in any single colour

#### Scenario: One category
- **WHEN** one category is supplied
- **THEN** it occupies the whole ring
- **AND** the legend still renders its single row, reporting 100%

#### Scenario: A zero-amount category
- **WHEN** a category's amount is zero
- **THEN** it contributes no visible arc
- **AND** it does not cause a division by zero in the percentages

#### Scenario: Every amount is zero
- **WHEN** every supplied amount is zero
- **THEN** no arc is drawn and every percentage reads zero
- **AND** nothing throws

#### Scenario: A negative amount
- **WHEN** a negative amount is supplied
- **THEN** it is treated as contributing nothing rather than sweeping backwards

#### Scenario: A very large amount
- **WHEN** amounts near the maximum integer minor units are supplied
- **THEN** percentages and the centre total remain finite and correct
- **AND** no arc exceeds a full turn

#### Scenario: Mixed currencies
- **WHEN** categories in more than one currency are supplied
- **THEN** the donut reports a currency mismatch rather than summing them

### Requirement: LineChart has one shared axis, always from zero

`LineChart` SHALL implement node `48:76` with a single y-axis shared by both
series, whose minimum is always zero.

Annotation `77:430`: *"ONE y-axis only. Income and expenses share a scale on
purpose — a dual-axis chart would let the two lines cross wherever the scales
were chosen to make them cross. The axis starts at zero, which is why the lines
sit in the upper half."*

#### Scenario: A second axis is not representable
- **WHEN** the public API of the line chart is inspected
- **THEN** it exposes no second axis, no per-series scale and no axis minimum
- **AND** both series are plotted against the same maximum

#### Scenario: The baseline is zero even when the data is far from it
- **WHEN** both series sit in a narrow band well above zero
- **THEN** the axis still starts at zero and the lines sit in the upper part of
  the plot
- **AND** the axis labels state the range, so the gap reads as information
  rather than as a rendering fault

#### Scenario: The legend is mandatory
- **WHEN** a line chart is rendered
- **THEN** it shows one legend entry per series
- **AND** there is no way for a caller to suppress it

#### Scenario: Series are told apart by more than colour
- **WHEN** the two series are rendered
- **THEN** each carries a named legend entry
- **AND** identity does not rest on hue alone

### Requirement: LineChart boundary inputs

`LineChart` SHALL render without throwing for degenerate series, and SHALL
report a mismatch rather than plotting data it cannot place honestly.

#### Scenario: Empty series
- **WHEN** both series are empty
- **THEN** the gridlines and axis labels render and no line is drawn
- **AND** nothing throws

#### Scenario: A single point
- **WHEN** a series holds one point
- **THEN** its marker is drawn and no line segment is attempted

#### Scenario: All values zero
- **WHEN** every value in both series is zero
- **THEN** the axis maximum does not become zero, and no division by zero occurs
- **AND** both lines render along the baseline

#### Scenario: Very large values
- **WHEN** values near the maximum integer minor units are supplied
- **THEN** points stay inside the plot and the axis labels remain readable

#### Scenario: Series of unequal length
- **WHEN** the two series have different point counts
- **THEN** the chart reports the mismatch rather than plotting them against
  different x positions

#### Scenario: Values are money
- **WHEN** series values are supplied
- **THEN** they are `Money` in a single currency, and a currency mismatch is
  reported rather than plotted

### Requirement: BottomSheet is sized by its content

`BottomSheet` SHALL implement node `59:211` — a grab handle, a header carrying a
title and a close control, a caller-supplied content area, and the bottom safe
inset — and its height SHALL follow its content.

Annotation `81:644`: *"the sheet height is computed from its slot content, not
guessed."*

#### Scenario: Short content
- **WHEN** the sheet is given content shorter than the screen
- **THEN** the sheet is only as tall as its handle, header, content and safe
  inset require

#### Scenario: Content taller than the screen
- **WHEN** the sheet is given content taller than the available height
- **THEN** the content scrolls
- **AND** the header and its close control remain reachable

#### Scenario: The safe inset comes from the device
- **WHEN** the sheet is rendered on a device reporting a bottom inset
- **THEN** the inset is taken from the device rather than from a fixed value,
  because the authored 34px describes one handset

#### Scenario: The close control is reachable
- **WHEN** the sheet is rendered
- **THEN** its close control meets the 44px touch target

### Requirement: Radio implements all four authored variants

`Radio` SHALL implement the full Figma variant set from node `25:238`: selected
and unselected, each enabled and disabled, at 22×22.

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all four radio variants are registered and distinguishable

#### Scenario: A disabled radio does not respond
- **WHEN** a disabled radio is tapped
- **THEN** its value does not change and no callback fires

#### Scenario: Exactly one of a group is selected
- **WHEN** a group of radios is rendered from a single selected value
- **THEN** exactly one is selected
- **AND** two radios in one group cannot both report selected

#### Scenario: The control is not the only tap target
- **WHEN** a radio is presented as a row with a title and a supporting line
- **THEN** the whole row is tappable, not only the 22px control
