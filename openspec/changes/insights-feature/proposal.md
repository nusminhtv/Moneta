## Why

`📱 07 Insights & Reports` has six screens and the app ships a placeholder. Every
component they need now exists (`insight-components` finished its charts once
Figma access returned), and `demo-data` can fill them with fifteen months of
ledger — so the screens are the only thing between this app and the feature that
explains where the money went.

## What Changes

- **07.01 Insights — overview.** A four-way period switcher, a `DonutChart` of
  spend by category, and the top three merchants below it. Annotation `77:287`:
  *"The donut answers the shape of spending; top merchants answer who took it."*
- **07.02 Cash flow — trend.** `MonetaLineChart` over the chosen period, two
  `StatTile`s, and a per-month net list.
- **07.03 Category breakdown — bars.** Ranked categories as `MonetaProgressBar`
  marks. Annotation `77:587` forbids a new chart component here: *"ProgressBar is
  reused as the bar mark rather than adding a HorizontalBarChart component; one
  series means one hue, so every bar is the same colour and rank is carried by
  length and order."*
- **07.05 Insights — period picker.** The period switcher's "more" route, as a
  `MonetaBottomSheet` of `MonetaRadioGroup` options.
- **An `insights` domain**: a period, and the aggregation each screen needs,
  derived from transactions through the existing repository.

## Non-goals

- **07.04 Month comparison** and **07.06 Export report** are deferred, and named
  here rather than quietly dropped. 07.04 is a two-column comparison table with
  per-row deltas; 07.06 needs file export, a destination `TextField` and a
  share sheet. Neither is on the path to "see where the money went", both are
  more work than the four screens above put together, and the user asked for
  blockers to be skipped and revisited. Tracked in `tasks.md` group 6.
- **A new chart component.** `77:587` forbids the obvious one.
- **Changing any design-system component.** This change composes; it does not
  edit `lib/design_system`.
- **Export, sharing or PDF generation** of any kind.

## Capabilities

### New Capabilities

- `insights`: the period a user is looking at, the aggregations each screen
  shows, and what each screen does when the period is empty.

### Modified Capabilities

None. `transactions` already specifies listing and summarising; this change
reads through it.

## Impact

- **Modules touched:** `lib/features/insights/{domain,presentation}` (new),
  `lib/app/insights_providers.dart` and `lib/app/router.dart` for composition,
  `docs/design-system/figma-map.md`.
- **Dependencies:** none. **Schema migration:** none.
- **Gates:** architecture (a new feature directory, which may import only
  `core`, `design_system`, `data` and itself), design tokens over four new
  screens, tests and coverage — `lib/features/insights/domain` lands in the
  ≥85% band via `tool/coverage_critical.txt`.
- **Figma nodes consumed:** screens `77:2`, `77:294`, `77:440`, `81:508`;
  annotations `77:284`, `77:430`, `77:587`, `81:644`. All read 2026-09-10.
