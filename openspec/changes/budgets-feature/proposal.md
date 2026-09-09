## Why

`📱 04 Budgets` (`5:17`) is seven screens, and the app has no budget at all — no
entity, no table, no repository. `budget-components` built the four missing
design-system pieces; this builds the feature behind them.

Reading the annotations turned up a fact that contradicts code shipped three
commits ago. Annotation `04.04` says the 80% alert is **per budget**:

> `'Alert me at 80%'` is what drives BudgetCard's NearLimit state — the 80%
> threshold is configurable here, so the component's warning colour is
> data-driven, not hardcoded.

`BudgetStatus.nearLimitThreshold` is a hardcoded `0.8`, and `MonetaProgressBar`,
`BudgetCard` and the new `MonetaCircularProgress` all read it. That is wrong
against the design, and it was wrong before this change opened.

## What Changes

**A budget domain.** `Budget` carries what `04.04` collects: a category, a limit
in `Money`, a period, a start date, whether unused amount rolls over, and the
alert threshold. Nothing about it is a `double` except the threshold, which is a
ratio rather than an amount.

**Spend is never stored.** A budget's progress is computed from the transactions
already in the database, so a budget and the transactions it measures cannot
disagree. `BudgetProgress` is the computed view: window, spent, limit including
any carry-in, fraction, status, and the daily allowance `04.05` requires:

> daily allowance = (limit - spent) / days remaining, recomputed each day

**The near-limit threshold becomes data-driven.** `BudgetStatus.fromFraction`
gains a `nearLimitThreshold` parameter defaulting to 0.8, and the three widgets
that derive status gain an optional threshold. Status stays *derived* — no
caller can pass a status that contradicts the numbers — but the boundary is now
the budget's, as the annotation requires.

**Six of the seven screens.**

| Screen | Node | Note |
| --- | --- | --- |
| 04.01 Overview | `66:91` | sorted by fraction descending, worst first |
| 04.02 Empty | `66:277` | |
| 04.03 Create step 1 — category | `66:378` | |
| 04.04 Create step 2 — amount, period, options | `66:488` | |
| 04.05 Detail — on track | `67:359` | |
| 04.06 Detail — over limit | `67:524` | same screen, a banner and a state |

**04.07 Budgets — history is deferred.** It instances a `BarChart` (`67:712`),
and this change did not build it.

The original reason given here was that the component "appears on none of the
three component pages", which was true and was the wrong conclusion. **The
component exists**: `BarChart` is `48:34` on a *fourth* component page,
`🧩 Components / Charts` (`5:12`), found on 2026-09-09 by querying a node instead
of trusting the page listing — the same mistake this repository has now made
three times.

So `04.07` is **deferred, not blocked**. Nothing stands in the way of building it
except scheduling; it belongs with the Insights charts, which need the same page.
Recorded in `figma-map.md`.

**Budgets is not a tab.** Annotation `04.01`:

> Bottom nav stays on Home because Budgets is a Home sub-screen, not a tab.

So the routes live inside the shell and the shell keeps Home lit.

## Impact

- `lib/features/budgets/{domain,data,presentation}/` — new feature
- `lib/data/database/migrations.dart` — schema version 3, `budgets` table
- `lib/design_system/molecules/budget_status.dart`, `progress_bar.dart`,
  `lib/design_system/atoms/moneta_circular_progress.dart`,
  `lib/design_system/organisms/budget_card.dart` — threshold parameter
- `lib/app/router.dart`, `lib/app/shell.dart`, new `lib/app/budget_providers.dart`
- Home's first-run checklist gains its "Set one budget" destination, which has
  been null since `a9d3a8f` because Budgets did not exist
