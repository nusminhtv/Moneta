## Why

`📱 07 Insights & Reports` (`5:20`) has six finished screens, and five of the
component sets they instance do not exist. No Insights screen can be built
honestly until they do — the alternative is approximating a chart, which is how
this repository's invented spacing scale happened.

Two of the five carry rules that are **accessibility requirements, not
styling**. Annotation `77:284`, on the donut: *"the DonutChart legend is part of
the component and not optional: two of the eight chart slots fall below 3:1
against the dark surface, so the visible labels ARE the required contrast
relief."* A caller who hides the legend to save space does not make the chart
denser; they make two of its eight categories unreadable. Annotation `77:430`,
on the line chart: *"ONE y-axis only … a dual-axis chart would let the two lines
cross wherever the scales were chosen to make them cross."* Both belong in the
type, not in a review checklist.

The user-visible outcome of this change alone is a gallery that renders every
authored variant of five new components. Screens come next, in
`insights-feature`.

## What Changes

Five component sets, each at its **full** authored variant count:

- **`ChartLegendItem`** (`47:47`) — 9 variants: `Slot=1`…`8` plus `Other`.
  353 wide, 8 gap, 5 vertical padding; a 10×10 swatch, then a label that fills
  and truncates, a percentage, and an amount. Only the swatch carries the series
  colour; all three text roles wear text tokens.
- **`DonutChart`** (`47:48`) — 353×482. A 208×208 ring of up to eight filled
  annular segments, a centre reading label / value / period, and a **mandatory**
  legend of `ChartLegendItem` rows. Segments cap at eight; a ninth category
  folds into a neutral `Other`.
- **`LineChart`** (`48:76`) — 353×226. Title, subtitle, a 353×140 plot with
  three gridlines, two series each ending in a 9×9 marker, y labels outside the
  plot, and a **mandatory** two-item legend whose swatch is a 14×3 line rather
  than a dot. One shared y-axis, always from zero.
- **`BottomSheet`** (`59:211`) — 393 wide: a 20px handle area with a 40×4 grab
  handle, a 60px header with a title and a 44×44 close, a caller-supplied
  content area, and the bottom safe inset. Its height comes from its content.
- **`Radio`** (`25:238`) — 4 variants: selected × disabled, 22×22.

Each is registered in the gallery at its full variant count, with a count test,
per the existing per-component pattern.

**No new tokens.** Verified rather than assumed: the donut's segment fill
`#AA7705` is `chart` slot 7 in `MonetaChartPalette`, and the `Other` swatch is
`#7C8595`, which is `textTertiary`. Both were read out of the exported SVG
assets, the method deviation 4 established for chart colours.

## Capabilities

### New Capabilities

None. This change adds components to an existing capability.

### Modified Capabilities

- `design-system/components`: adds requirements for `ChartLegendItem`,
  `DonutChart`, `LineChart`, `BottomSheet` and `Radio`, including the two
  accessibility rules that must be unrepresentable to violate — a suppressible
  legend and a second y-axis.

## Non-goals

Each of these is out of scope for a reason read from the file, not for
convenience.

- **`BarChart`** (`48:34`). It is instanced on Budgets `04.07`, and on no page 07
  screen: neither the Screen Index row for 07.03 nor annotation `77:587` lists
  it. It belongs to whichever change builds Budgets — history.
- **`Sparkline`** (`48:94`). On the Charts page, instanced nowhere on page 07.
- **A horizontal bar chart.** Annotation `77:587` forbids it outright:
  *"ProgressBar is reused as the bar mark rather than adding a
  HorizontalBarChart component; one series means one hue, so every bar is the
  same colour and rank is carried by length and order."* 07.03 needs no new
  component.
- **Any screen, route, domain or aggregation.** `insights-feature` owns those.
  This change adds nothing under `lib/features` and nothing to the router.
- **Token changes.** None are needed; see above.
- **`TextField` work.** 07.06 wants `TextField/Filled` with `icon/mail`, and
  `MonetaTextField` already takes a `leadingIcon`.
- **Weakening any gate** to accommodate a chart.

## Impact

- **Modules touched:** `lib/design_system/atoms` (`Radio`),
  `lib/design_system/molecules` (`ChartLegendItem`),
  `lib/design_system/organisms` (`DonutChart`, `LineChart`, `BottomSheet`), the
  gallery catalog and describer, and `docs/design-system/figma-map.md`. Single
  layer: `design_system` plus its gallery in `lib/app`. Nothing under
  `lib/core`, `lib/data` or `lib/features`.
- **Dependencies:** none added. Both charts are drawn with `CustomPainter` and
  the existing token set.
- **Schema migration:** none.
- **Gates affected:** design-token checks over new painting code, gallery
  completeness and per-component variant counts, architecture, tests and
  coverage, through `bash tool/verify.sh --change insight-components`.
- **Figma nodes consumed:** components `47:47`, `47:2`, `47:42`, `47:48`,
  `47:49`, `48:76`, `59:211`, `25:238`; screens `77:2`, `77:294`, `77:440`,
  `81:399`, `81:508`, `81:654`; annotations `77:284`, `77:430`, `77:587`,
  `81:498`, `81:644`, `81:810`. All read 2026-09-09.
- **Documentation debt this change discharges:** annotation `81:498` settles
  deviation 12 in `docs/design-system/figma-map.md`, which had flagged
  `StatTile`'s green "+12.4% spent" sample as an unverified *candidate* for the
  file's twelve deliberate mistakes. The annotation states the rule — *"delta
  colour follows MEANING, not sign"* — so the existing decision was right and
  the sample is the error.
