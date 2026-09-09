## Context

See `proposal.md` — Why. Constraints that shape the approach:

- Both charts must be drawn, not composed. There is no chart dependency and the
  proposal adds none, so `CustomPainter` is the only route.
- `tool/check_design_tokens.dart` forbids raw design values outside
  `tokens|theme`. Painting code is where geometry naturally wants to be a
  literal, so every value has to arrive from a token or a parameter.
- The `budget-components` review is fresh and directly relevant: swapping
  `arcColor` and `trackColor` in `MonetaCircularProgress` left all 1196 tests
  green, because the painter mutated one shared `Paint` and the recording canvas
  therefore reported the same colour twice. That mistake is available to be
  repeated in two new painters.
- The eight-slot chart palette is already token-backed as `MonetaChartPalette`,
  with `base(slot)` and `subtle(slot)`, and was validated as a set.

## Goals / Non-Goals

Design-level goals beyond the proposal's scope:

- Make the two accessibility rules **unrepresentable to violate**, not merely
  defaulted correctly.
- Keep both charts free of any knowledge of budgets, transactions or categories,
  so `insights-feature` supplies data and the components stay in
  `design_system`.

Non-goals at design level:

- Animation. Nothing in the file authors a transition for either chart.
- Interaction inside the charts — no tap-a-segment, no tooltip. No annotation
  asks for it, and `07.01` reaches detail through `TransactionRow`s below the
  chart instead.
- Golden tests. This repository has none, and introducing the first goldens
  inside a change about charts would make chart correctness depend on a new
  harness. Structure and canvas assertions instead; noted as a gap.

## Decisions

### D1 — The legend is a child of the chart, not a sibling

**Chosen:** `DonutChart` and `LineChart` each render their own legend
internally. The public API takes data and exposes no legend parameter.

Alternatives:

- *A `showLegend` flag defaulting to true.* Rejected: annotation `77:284` makes
  the legend a contrast requirement for two of the eight slots. A flag turns an
  accessibility guarantee into a caller's convenience, and the first cramped
  screen turns it off.
- *A separate `ChartLegend` widget screens compose beside the chart.* Rejected
  for the same reason plus a worse failure mode — a screen can then show a
  legend whose rows disagree with the arcs, which is harder to notice than no
  legend at all.

`ChartLegendItem` stays a public component because it is an authored component
set with nine variants and must appear in the gallery. It being public does not
make the donut's legend optional; the donut simply does not accept one.

### D2 — One `ChartSeries` value type, in `design_system`

Both charts need "a named quantity with a slot". Options were a record per
chart, a shared value type, or each chart taking parallel lists.

**Chosen:** a small immutable value type in `design_system`, carrying a label, a
`Money` amount and a chart slot. Parallel lists (`labels`, `amounts`, `slots`)
were rejected outright: three lists of possibly different lengths is a defect
waiting to be written, and the spec requires a mismatch to be *reported*.

It lives in `design_system`, not `core`: `MonetaChartPalette` is a design-system
concept, and `lib/core` may import nothing but `core`.

### D3 — Percentages and folding are computed by the component

The eight-segment cap, the `Other` fold and the percentages are the donut's own
arithmetic, derived from the amounts it is given.

Alternative: have `insights-feature` pre-fold and pass eight segments plus a
pre-summed `Other`. Rejected — the spec requires that the segment sum equals the
supplied sum and that the centre total agrees. If folding happens upstream, each
caller can get it wrong independently, and the guarantee moves out of the type
into a convention. The donut is also the only place that knows the cap is eight.

This keeps the component "takes domain types, not pre-formatted strings":
`Money` in, formatting and percentages inside.

### D4 — Two `Paint` objects per painter, never one mutated

Every painter in this change builds a fresh `Paint` per draw call.

This is not a style preference. Skia copies a `Paint` at the call site, so a
shared mutated instance renders correctly on a device — and a recording canvas
keeps the reference, so `paints..arc(color:)` sees the last colour on every
entry and cannot discriminate. That is exactly how the ring's colour requirement
went unguarded through a whole change. Both new painters will be asserted with
ordered `paints` sequences, and the fresh-`Paint` rule is what makes those
assertions capable of failing.

### D5 — Donut geometry is measured from the exported assets, and labelled

The segments are exported as filled annular paths rather than as strokes, so
there is no stroke width to read. The ring's outer radius is 104 of the 208 box,
and the Food segment's path runs from `y=0` to `y=39.52` at twelve o'clock,
giving a ring thickness of ≈39.5 and an inner radius of ≈64.5.

That is a measurement off an exported SVG, which is the method deviation 4
established for chart colours — better than guessing, weaker than a variable.
It is recorded as **observed from the exported asset** in `figma-map.md`, not as
transcribed from a style, and the thickness reaches the painter as a token-backed
value rather than a literal in `paint()`.

Two colours were confirmed exactly this way and need no token: the segment fill
`#AA7705` is `chart` slot 7, and the `Other` swatch `#7C8595` is `textTertiary`.

### D6 — `LineChart` takes two named series, not a list

The signature names an income series and an expense series rather than accepting
`List<ChartSeries>`.

Alternative: a list, for generality. Rejected: a list invites a third series,
and the moment there are three the shared-axis argument in annotation `77:430`
stops being about two lines. Two named parameters also make "series of unequal
length" a comparison of two things rather than a scan, and make a second y-axis
syntactically absent rather than merely unused.

### D7 — `BottomSheet` is a widget, not a `showModalBottomSheet` wrapper

**Chosen:** a plain widget that lays out handle, header, content and safe inset,
with no presentation behaviour of its own.

Alternative: a helper that calls `showModalBottomSheet`. Rejected for this
change — the scrim on `07.05` is drawn by the screen, the sheet is a sibling of
it in the frame, and a component that shows itself cannot be rendered in the
gallery, which every component here must be. How the sheet is *presented*, and
whether a `bg/overlay` token is needed for the scrim, belongs to
`insights-feature`.

Its height follows content via intrinsic sizing; the bottom inset comes from
`MediaQuery.padding.bottom`, not the authored 34, for the same reason
`MonetaAppBar` refuses to paint a fake status bar.

### D8 — `Radio` is the atom; the group rule is enforced where the group is

`Radio` renders one control and reports taps. "Exactly one selected" is a
property of a group, which a single control cannot enforce.

The spec's group scenario is satisfied by a `RadioRow`-style composition driven
by a single selected value — one source of truth, so two rows cannot both read
selected. That composition also carries the whole-row tap target the spec
requires, which the 22×22 control cannot provide on its own.

Considered and rejected: an assert inside `Radio` (it cannot see its siblings),
and a `RadioGroup<T>` inheriting-widget (more machinery than five options on one
sheet justify, and the gallery would then need a fake group to render an atom).

## Risks / Trade-offs

- **A painter's geometry drifts from Figma and no test notices** → the donut's
  ring thickness and the line chart's gridline positions are asserted against
  the recorded canvas, and the values are recorded in `figma-map.md` as observed
  from exported assets so a future reader knows their provenance is weaker than
  a token.
- **`paints` matchers are brittle to draw order** → that is deliberate here.
  Order *is* the requirement for the donut (track before arcs) and the line
  chart (gridlines before series), and `budget-components` shipped a test named
  for order that did not assert it.
- **No goldens, so type metrics inside the charts are unverified** → the
  placeholder font makes any width assertion meaningless, so the specs are
  written as structural claims (a label truncates, the figures stay visible) and
  the gap is recorded rather than papered over with a false assertion.
- **Eight-slot folding could silently reorder a caller's data** → the spec
  requires largest-first and requires the sums to match; both are testable and
  both are asserted.
- **`check_design_tokens.dart` on new painting code** → no `Color(0x…)`,
  no literal `EdgeInsets`, no `BorderRadius.circular`. Geometry arrives as
  parameters or from `MonetaSpacing`/`MonetaRadii`; colours arrive from
  `context.moneta`. Where a genuinely component-local constant is unavoidable it
  is a named `static const` with a `figma-map.md` row, not an inline literal.
- **`check_architecture.dart`** → everything lands in `design_system`, which may
  import only `core` and `design_system`. `ChartSeries` living in
  `design_system` rather than `core` is what keeps that true, since it references
  a chart slot.

## Migration Plan

None. Five additive components, no persistence, no schema, no public API
changed. Nothing to roll back beyond the commits.

## Open Questions

- Whether `Sparkline` (`48:94`) is instanced anywhere outside page 07. It is not
  needed by this change either way; if a later page uses it, it joins that
  change. Answering it does not affect these specs, this approach or these tasks.
