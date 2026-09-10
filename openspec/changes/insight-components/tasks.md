## 1. Shared Value Type

- [x] 1.1 `lib/design_system/molecules/chart_series.dart`: the `ChartSeries`
  value type from design D2 — a label, a `Money` amount and a chart slot,
  immutable and equatable. Include the currency-mismatch check the specs require
  so both charts inherit it rather than each re-implementing it.
  Verify: `test/design_system/molecules/chart_series_test.dart` covers equality,
  a mismatched currency being reported, zero, negative and near-maximum amounts;
  `bash tool/verify.sh --change insight-components` passes.

## 2. ChartLegendItem

- [x] 2.1 `lib/design_system/molecules/chart_legend_item.dart` from `47:47` —
  all nine slots (`1`–`8` and `Other`), swatch 10, label filling and
  truncating, percentage and amount. Takes a `Money`, formats it itself.
  `Other` uses `textTertiary`, transcribed from `47:42`.
  Verify: `test/design_system/molecules/chart_legend_item_test.dart` asserts one
  test per slot that the swatch is that slot's palette colour while the three
  text roles are identical across slots, plus a long label truncating without
  displacing the figures.
- [x] 2.2 Register all nine slots in the gallery with a count test.
  Verify: `test/app/gallery_test.dart` fails if fewer than nine are registered.

## 3. DonutChart

- [x] 3.1 `lib/design_system/organisms/donut_chart.dart` — the ring from `47:49`
  with a fresh `Paint` per arc (design D4), the centre's label/value/period, and
  the ring thickness recorded as observed from the exported asset (D5).
  Verify: `test/design_system/organisms/donut_chart_test.dart` asserts the
  painted arcs with an ordered `paints..arc(color:)` sequence, and **a mutation
  swapping two segment colours must fail it** — the `budget-components` lesson.
- [x] 3.2 The eight-segment cap and the `Other` fold, with percentages.
  Verify: nine categories give eight coloured segments plus a neutral `Other`;
  eight give no `Other`; the segment sum equals the supplied sum and equals the
  centre total.
- [x] 3.3 The legend, rendered unconditionally and never suppressible (D1).
  Verify: a source-level check that the constructor exposes no legend parameter —
  the same technique `near_limit_threshold_test.dart` now uses, since an
  always-empty diagnostics list proves nothing — plus a test that every segment
  has exactly one legend row whose colour matches its arc.
- [x] 3.4 Boundary behaviour: no categories, one category, a zero amount, all
  zeros, a negative amount, near-maximum amounts, mixed currencies.
  Verify: each spec scenario has a test; nothing throws and no arc exceeds a
  full turn.
- [x] 3.5 Gallery registration with a count test.
  Verify: `test/app/gallery_test.dart`.

## 4. LineChart

- [x] 4.1 `lib/design_system/organisms/line_chart.dart` from `48:76` — title,
  subtitle, three gridlines, two series with end markers, y labels, and the
  two-item legend whose swatch is a line. Two named series, not a list (D6);
  fresh `Paint` per draw (D4).
  Verify: `test/design_system/organisms/line_chart_test.dart` asserts an ordered
  `paints` sequence — gridlines before series — and a mutation reversing that
  order must fail it.
- [x] 4.2 The single zero-based axis: no second axis, no per-series scale, no
  axis minimum in the API, and both series scaled to one maximum.
  Verify: a source-level check that no such parameter exists, plus a test that
  two series in a narrow band well above zero still render against a zero
  baseline with labels stating the range.
- [x] 4.3 Boundary behaviour: empty series, a single point, all zeros, very
  large values, series of unequal length, mixed currencies.
  Verify: each spec scenario has a test; the all-zeros case must not divide by
  zero and unequal lengths must be reported rather than plotted.
- [x] 4.4 Gallery registration with a count test.
  Verify: `test/app/gallery_test.dart`.

## 5. BottomSheet

- [x] 5.1 `lib/design_system/organisms/bottom_sheet.dart` from `59:211` — grab
  handle, header with title and a 44px close, caller-supplied content, and the
  bottom inset taken from `MediaQuery` rather than the authored 34 (D7).
  Verify: `test/design_system/organisms/bottom_sheet_test.dart` asserts the
  sheet's height follows short content, that taller content scrolls while the
  header stays reachable, that the close control meets 44px, and that the inset
  responds to a device inset rather than being fixed.
- [x] 5.2 Gallery registration.
  Verify: `test/app/gallery_test.dart`.

## 6. Radio

- [x] 6.1 `lib/design_system/atoms/moneta_radio.dart` from `25:238` — all four
  variants at 22×22, disabled ignoring taps.
  Verify: `test/design_system/atoms/moneta_radio_test.dart` covers each variant's
  token-derived appearance and that a disabled radio fires no callback.
- [x] 6.2 The row composition that carries the group rule and the whole-row tap
  target (D8), driven by one selected value so two rows cannot both read
  selected.
  Verify: rendering a group from one value selects exactly one; tapping anywhere
  on a row reports it; a second row cannot be selected simultaneously.
- [x] 6.3 Gallery registration with a count test for all four variants.
  Verify: `test/app/gallery_test.dart`.

## 7. Close-Out

- [x] 7.1 `docs/design-system/figma-map.md`: mark the five components done with
  their nodes and variant counts; add the Charts page components not built and
  why (`BarChart` belongs to Budgets `04.07`, `Sparkline` is instanced nowhere on
  page 07); record the donut's ring thickness as **observed from the exported
  asset**, not transcribed; and record that `#AA7705` and `#7C8595` were
  confirmed as `chart` slot 7 and `textTertiary`, so no token was added.
  Verify: the map names every component this change implemented, and the
  provenance table distinguishes measured from transcribed values.
- [x] 7.2 Update deviation 12: annotation `81:498` verifies it. Record that
  *"delta colour follows MEANING, not sign"* confirms the existing `StatTile`
  decision and identifies the green "+12.4% spent" sample as the error, so the
  entry stops being an unverified candidate.
  Verify: the deviation table no longer calls it unverified and cites `81:498`.
- [x] 7.3 Record the two accessibility rules in
  `docs/design-system/figma-map.md` as deviations-with-reasons — a legend that
  cannot be suppressed and an axis that cannot be doubled — since both are
  places where the component is deliberately less flexible than a caller might
  want.
  Verify: both entries name their annotation node.
- [ ] 7.4 Update `docs/ai-workflow/evidence-log.md` with this change's verify
  runs and commits.
  Verify: the entries match `git log`.
- [ ] 7.5 Run the full gate and the `figma-fidelity` agent against `47:48` and
  `48:76`.
  Verify: `bash tool/verify.sh --change insight-components` passes, its evidence
  file is cited in the final commit, and the fidelity report is recorded.
