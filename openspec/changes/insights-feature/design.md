## Context

- Every component these screens need exists: `DonutChart`, `MonetaLineChart`,
  `ChartLegendItem`, `MonetaBottomSheet`, `MonetaRadio*`, plus `StatTile`,
  `MonetaSegmentedControl`, `MonetaProgressBar`, `SectionHeader`,
  `TransactionRow`, `EmptyState`, `CategoryIcon` and `MonetaAppBar`.
- `TransactionRepository` already lists and summarises by `TransactionQuery`,
  and `demo-data` can fill it with fifteen months.
- `tool/check_architecture.dart`: `features/insights` may import `core`,
  `design_system`, `data` and itself — **not** `features/transactions`. The
  transaction types it needs are reached through `lib/app`, the same way
  `features/notifications` already does.
- `MonetaSegmentedControl` asserts 2–4 labels. Four periods fit exactly.

## Goals / Non-Goals

Goals: the aggregation is pure and testable without a database; the screens are
dumb; an empty period is visibly different from a failed read.

Non-goals: 07.04 and 07.06 (see `proposal.md` — deferred, not dropped); any
change to `lib/design_system`; export of any kind.

## Decisions

### D1 — A pure aggregation layer, separate from the screens

`InsightsPeriod` (an enum with a window) and `InsightsSummary` (category
totals, monthly income/expense series, top transactions) live in
`features/insights/domain` and are computed by a pure function from a list of
transactions and a clock.

Alternative: aggregate inside each screen's controller. Rejected — the
interesting content of this change *is* the arithmetic, and a screen is the
most expensive place to test arithmetic. `lib/features/insights/domain` also
lands in the ≥85% coverage band, which is where this belongs.

### D2 — The feature does not import `features/transactions`

The architecture checker forbids it. `Transaction` and `TransactionQuery` are
transaction-feature types, so the aggregation takes **its own** minimal input
type — a list of `InsightsEntry` (amount, direction, category, occurredAt, id,
note) — and `lib/app/insights_providers.dart` maps repository rows into it.

This is the same shape `features/budgets` already uses with `SpendEntry`, and
it is deliberate rather than a workaround: the aggregation depends on six
fields, so taking six fields makes that true in the type.

### D3 — Periods are anchored to whole months

`thisMonth`, `threeMonths`, `sixMonths` and `year` all end **now** and start at
the first instant of the earliest included month, in UTC.

Whole months rather than rolling 90/180 days: the cash-flow chart plots one
point per month, and a rolling window would put a partial month at both ends and
make the first and last points structurally smaller than the rest — which reads
as a trend that is not there.

### D4 — An empty period and a failed read are different screens

`77:291` requires an `EmptyState` for an empty period. A failed read gets its own
error state. Collapsing them is the defect `transactions` already has a
requirement about — "an empty wallet and an unreadable one are different facts".

### D5 — 07.03 derives its bar fractions from the largest category, not the total

`77:587` says rank is carried by **length and order**. A share-of-total fraction
would make the top bar 30%-full and waste two-thirds of the width; a
share-of-largest fraction makes the first bar full and every other bar a visible
proportion of it. The percentage *label* still reads share-of-total, because that
is the number a reader wants.

Recorded because the two fractions differ and the screen shows both.

### D6 — The period picker is presented by the screen, not by the sheet

`MonetaBottomSheet` is a plain widget by design (D7 of `insight-components`).
`07.05` is reached by tapping the period switcher's label, and the screen calls
`showModalBottomSheet` with the sheet as its child, so the scrim belongs to the
screen exactly as `81:525` draws it.

## Risks / Trade-offs

- **Aggregating fifteen months on every rebuild** → the summary is computed in a
  provider keyed by period, so it is recomputed when the period or the ledger
  changes and not on every frame. With 1,174 transactions the work is a single
  pass; measured if it ever looks slow rather than optimised now.
- **Two screens deferred** → named in the proposal and in `tasks.md` group 6, not
  omitted. The router still routes only what exists.
- **`check_design_tokens` over four new screens** → all spacing from
  `MonetaSpacing`, all colour from `context.moneta`.
