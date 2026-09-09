## 1. The threshold becomes data-driven

- [x] 1.1 `BudgetStatus.fromFraction` and `fromSpend` gain a
      `nearLimitThreshold` defaulting to 0.8; `MonetaProgressBar`,
      `MonetaCircularProgress` and `BudgetCard` gain the parameter and pass it
      through. Tests: a moved boundary changes each widget's colour, all three
      agree at a non-default threshold, none accepts a status.

## 2. Budget domain

- [x] 2.1 `lib/features/budgets/domain/budget.dart`: `Budget`, `BudgetPeriod`,
      validated construction returning `Result`. Limit `Money`, threshold a
      ratio in (0, 1].
- [x] 2.2 `budget_window.dart`: the current window from period + start + clock,
      including the 31 Jan → February anchor case.
- [x] 2.3 `budget_progress.dart`: spend, carry-in, effective limit, fraction,
      status, daily allowance, skipped-currency count. Allowance rounds down.
- [x] 2.4 `budget_repository.dart`: the interface, returning `Result`.
- [x] 2.5 Tests to ≥85%: every scenario in the budgets spec, including zero and
      negative limits, thresholds out of range, half-open boundaries, rollover
      one deep, over-budget allowance, and a future start date.

## 3. Storage

- [x] 3.1 Migration to schema version 3: `budgets` table with a unique index on
      (category, period). Test that v2 databases upgrade and keep their data.
- [x] 3.2 `BudgetDao` and `SqliteBudgetRepository`, reading spend by joining the
      existing transactions table rather than storing it.
- [x] 3.3 Tests to ≥85%: round-trip, duplicate rejection, delete, and a budget
      whose spend changes when a transaction is deleted.

## 4. Overview and empty — 66:91, 66:277

- [x] 4.1 `lib/app/budget_providers.dart` deriving from the transaction
      controller, so a new transaction moves the budgets the same way it moves
      Home.
- [x] 4.2 `BudgetsScreen`: period switcher, total ring, cards worst first;
      empty state when there are none.
- [x] 4.3 Route inside the shell with Home active; shell keeps Home lit.
- [x] 4.4 Tests: ordering including a tie, the ring is total-over-total not an
      average, Home stays the active tab, empty state.

## 5. Create flow — 66:378, 66:488

- [x] 5.1 Step 1: category grid, action disabled until one is chosen.
- [x] 5.2 Step 2: amount, period, the three options from `66:534`
      (Starts / Rolls over unused / Alert me at), submit.
- [x] 5.3 Tests: nothing written until submit, zero amount blocked with a
      message, duplicate category refused.

## 6. Detail — 67:359, 67:524

- [x] 6.1 Detail screen: ring, two stat tiles including the daily allowance,
      the contributing transactions, banner when over.
- [x] 6.2 Tests: on-track and over states, the listed transactions are exactly
      the counted ones, skipped foreign currency disclosed.

## 7. Wire up and record

- [x] 7.1 Home's first-run checklist "Set one budget" gets its destination,
      null since `a9d3a8f`.
- [x] 7.2 `figma-map.md`: six screens done, `04.07` recorded as **deferred**,
  and the threshold correction added to the deviations table.

  It said "blocked on `BarChart`" until 2026-09-09. `BarChart` is `48:34` on
  `🧩 Components / Charts` (`5:12`) — a fourth component page nobody had
  queried, so the screen was never blocked on a missing component. Corrected in
  `proposal.md`, `design.md` and `figma-map.md`; this line had been left behind.

  **Known gaps recorded rather than fixed here**, both found by the second
  `change-verifier` pass and both wider than this change:

  - A failed budget read resolves to an empty list (`budget_providers.dart`),
    so a storage failure renders as a wallet with no budgets and offers
    "Create a budget" — the same lie the period-switcher fix removed, from a
    different cause. `BudgetsRouteScreen` also renders its loading skeleton
    forever on `AsyncError`, making a database that cannot open
    indistinguishable from one still opening. Fixing it properly means deciding
    how the app surfaces storage failure, which Home shares; it needs its own
    change rather than a local patch here.
  - `budgetPeriodLabels` calls `.toLocal()` on a UTC date-only window boundary
    before formatting. Harmless at `TZ=Asia/Ho_Chi_Minh`, wrong in any zone
    behind UTC, and the same shape as the `startLabel` call in
    `create_budget_amount_screen.dart` that was already left open. Both belong
    in one pass over date-only boundaries.
