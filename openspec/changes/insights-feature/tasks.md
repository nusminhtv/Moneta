## 1. The Insights Domain

- [x] 1.1 `lib/features/insights/domain/insights_period.dart`: the four periods
  from `77:32` with their windows, resolved against a `Clock` in UTC and
  anchored to whole months (D3).
  Verify: `test/features/insights/domain/insights_period_test.dart` covers each
  period's window; a mid-month clock; a January clock crossing the year; and
  that every window ends at the clock.
- [x] 1.2 `lib/features/insights/domain/insights_entry.dart` — the feature's own
  minimal input (D2), because `features/insights` may not import
  `features/transactions`.
  Verify: architecture stays green, and a test asserts the type carries exactly
  the fields the aggregation reads.
- [x] 1.3 `lib/features/insights/domain/insights_summary.dart`: the pure
  aggregation — category totals ranked, monthly income/expense series with a
  zero point for a silent month, period totals, and the top three expenses.
  Verify: `test/features/insights/domain/insights_summary_test.dart` covers
  ranking, the zero-filled month, top-three with fewer than three, an empty
  ledger, income-only, a single transaction, near-maximum amounts and a currency
  mismatch.

## 2. 07.01 Insights — Overview

- [x] 2.1 `lib/features/insights/presentation/insights_overview_screen.dart`
  from `77:2`: period switcher, `DonutChart`, `SectionHeader`, top three
  `TransactionRow`s.
  Verify: the donut's centre total equals the period total; exactly the three
  largest are listed; the layout is unchanged across all four periods
  (`77:291`).
- [x] 2.2 The empty and error states (`77:291`, D4).
  Verify: an empty period renders `EmptyState` and **no** chart; a failed read
  renders an error state distinguishable from the empty one; and income-only
  still reads as empty spending.

## 3. 07.02 Cash Flow — Trend

- [x] 3.1 `lib/features/insights/presentation/cash_flow_screen.dart` from
  `77:294`: `MonetaLineChart`, two `StatTile`s, per-month net rows.
  Verify: both series have one point per month and equal length; a silent month
  contributes zero rather than being skipped; months are listed newest first.
- [x] 3.2 Empty and error states.
  Verify: as 2.2.

## 4. 07.03 Category Breakdown — Bars

- [x] 4.1 `lib/features/insights/presentation/category_breakdown_screen.dart`
  from `77:440`, with `MonetaProgressBar` as the bar mark.
  Verify: largest first; the first bar is full and the rest are its proportion
  (D5); every bar the same colour; and a source-level check that the screen
  declares no `CustomPainter` — `77:587` forbids the component this screen
  looks like it wants.

## 5. 07.05 Period Picker

- [x] 5.1 `lib/features/insights/presentation/period_picker_sheet.dart` from
  `81:508`: `MonetaBottomSheet` + `MonetaRadioGroup`, presented by the screen
  (D6).
  Verify: the active period is the selected option; choosing one applies it and
  closes; dismissing changes nothing.

## 6. Composition, And What Is Deferred

- [x] 6.1 `lib/app/insights_providers.dart`: maps repository rows to
  `InsightsEntry` and exposes the summary per period; `lib/app/router.dart`
  replaces the Insights placeholder.
  Verify: `test/app/router_test.dart` reaches Insights and its sub-routes; the
  architecture gate stays green.
- [x] 6.2 `docs/design-system/figma-map.md`: record page 07 with which screens
  are built and which are deferred, and why.
  Verify: the entry names `07.04` and `07.06` as deferred with their reasons,
  so a reader does not read silence as absence.
- [ ] 6.3 **Deferred, deliberately: 07.04 Month comparison (`81:399`) and
  07.06 Export report (`81:654`).** Not started. 07.04 is a two-column
  comparison with per-row deltas; 07.06 needs file export, a destination field
  and a share sheet. Both are named in `proposal.md` under Non-goals.
  Verify: this task stays unticked until they are built, and the map says so.
- [x] 6.4 Run the full gate.
  Verify: `bash tool/verify.sh --change insights-feature` passes.

## 7. Added Scope, Taken Deliberately

- [x] 7.1 `MonetaProgressBar.series` — a new named constructor in
  `lib/design_system`, which `proposal.md` said this change would not touch.
  **Surfaced rather than absorbed**, as the apply workflow requires.

  `77:587` asks for two things the existing constructor cannot do at once:
  *reuse ProgressBar as the bar mark*, and *one series means one hue*. The
  default constructor derives its colour from the fraction, so 07.03's longest
  bar — full by construction — would come out in the near-limit **warning**
  colour while shorter bars came out green. `80:407` settles it: every bar on
  `77:440` is filled `chart/1`.

  The addition takes a `ChartSlot`, not a `Color`, for the reason
  `ChartLegendItem` does: the eight-slot palette was validated as a set. The
  existing constructor is unchanged and all 16 of its tests still pass.
