## Why

Home is the last placeholder destination — it currently renders the words "Not
built yet". It is also where the two most finished components in the design
system have been sitting unused: `BalanceCard`, which Figma explicitly calls the
"Home hero", and `TransactionRow`. The data they need already exists, stored and
summarised, since `transactions-local-store`.

Home is also the first screen that needs data it does not own, so it is the first
real test of the rule that a feature may not import another feature. That tension
is decided in [ADR 0004](../../../docs/adr/0004-cross-feature-overview-screens.md).

The user-visible outcome: opening the app shows this month's balance,
safe-to-spend, income and expenses on the gradient hero card, with the five most
recent transactions below it; recording a transaction updates both without a
manual refresh; and hiding the amounts with the eye control keeps them hidden
after the app is closed and reopened.

## Prerequisite

This change is **blocked** on a separate change, `design-system-corrections`,
which must land first. Two design-system components need API changes that are not
Home's to make:

- `BalanceCard` currently takes `safeToSpendUntil` as a **pre-formatted `String`**
  (`balance_card.dart:40`), which violates `CLAUDE.md`'s "design-system widgets
  take domain types, not pre-formatted strings". It must take a date and format it
  itself. This was introduced in `design-system-foundation` and is a correction,
  not a feature.
- `TransactionRow` has no masked form. Masking the hero card while the row below
  it still reads "−1,250,000 ₫" defeats the purpose, so the row needs the same
  treatment the card already has.

Both are `MODIFIED` deltas on `design-system/components` and belong to that
change, not this one.

## What Changes

- **Schema migration v2**: a `settings` key/value table, and a `PreferencesStore`
  in `lib/data`. This is the first migration this project applies to a database
  that already contains rows, which the v1 tests could only simulate.
- **Shared providers move out of the transactions feature.** `clockProvider`,
  `idGeneratorProvider`, `walletCurrencyProvider` and `appDatabaseProvider`
  currently live in `features/transactions/presentation/transaction_providers.dart`.
  Home needs three of them and may not import another feature, so they move to
  `lib/data/app_providers.dart`. This is a pre-existing misplacement that Home is
  the first caller to expose.
- **New capability `home`** as a feature slice:
  - `domain/`: `HomePeriod` (month bounds), `RecentEntry` (a recent transaction
    expressed only in shared types), and `HomeSnapshot` (balance, period income
    and expenses, recent entries, with safe-to-spend derived and floored at zero).
    No data-source interface — see ADR 0004.
  - `presentation/`: a controller and `HomeScreen`, composing `BalanceCard` and
    the recent list, with distinct empty and error states.
- **New assembler in `lib/app`**: a provider that reads `TransactionRepository`,
  maps `Transaction` to `RecentEntry`, and builds the `HomeSnapshot`. `lib/app` is
  the only layer allowed to see both features, and it holds translation only.
- **Balance semantics pinned**: total balance is the net of everything that has
  **already occurred** — future-dated transactions are excluded, matching the
  reason the `transactions` capability gives for rejecting them. Period income and
  expenses cover the displayed month only.
- **Masking covers every amount on screen**, hero card and recent list alike, and
  the choice survives a restart.

## Capabilities

### New Capabilities
- `home`: what the overview shows, how its period is bounded, how balance and
  safe-to-spend are derived, what masking covers, and what happens when reads
  fail.
- `storage/preferences`: durable key/value settings — absence versus value, the
  single stored boolean form, overwrite semantics, and declared keys.

### Modified Capabilities
None. Two earlier drafts of this proposal listed
`storage/local-database`; the requirement they wanted — that rows survive an
upgrade — is **already owned** by that capability
(`openspec/specs/storage/local-database/spec.md`, "rows written before the upgrade
are still readable afterwards"). What was missing was a test against a populated
database, not a requirement. That test is task 1.1.

## Non-goals

- **No budgets on Home.** `BudgetCard` stays without a caller. Budgets need their
  own table, limits and period rollover; a fixture-driven budget card on a screen
  otherwise showing real data would be worse than leaving it off.
- **No month switching.** Current month only. `HomePeriod` takes an arbitrary
  range so the control is additive later.
- **No accounts**, no `AccountCard`, no account breakdown.
- **No Insights or Profile screens.** Still placeholders.
- **No charts.** The `chart/1..8` tokens stay unused here.
- **No pull-to-refresh and no background refresh.** Home refreshes when a
  transaction is recorded, which is a different requirement and is specified.
- **No multi-currency.** Still VND only. Home *refuses* a mixed-currency figure
  rather than adding unlike amounts, but nothing converts between currencies.
- **No fix for the summary bug this change surfaced.** `TransactionDao.summarise`
  sums `amount_minor` with no currency predicate and stamps the wallet currency on
  the result, so a mixed store yields a silently wrong total. That is a defect in
  already-archived code and is tracked as its own change.

## Impact

- **Modules touched:** `lib/data` (migration v2, preferences, relocated
  providers), `lib/features/home` (new), `lib/app` (assembler, mapper, route),
  and — correcting an earlier claim in this proposal —
  **`lib/features/transactions/presentation` is modified**, because the shared
  providers move out of it, along with every test that overrides them. Riverpod
  binds overrides by object identity rather than by library, so those overrides
  keep working with only their imports changed — verified against the three call
  sites.
- **Dependencies:** none added. `intl` is already present for date formatting.
- **Schema migration:** yes, v2, applied to a database that may hold user data.
- **Gates affected:** `features/home/domain`, `lib/data/preferences` **and
  `lib/data/app_providers.dart`** come under the 85% coverage threshold — the last
  of those because `coverage_critical.txt` matches the bare substring `/data/`, so
  simply moving a provider into `lib/data` subjects it to a threshold it does not
  currently meet. Measured at 37.5% from the committed `lcov.info`, which is why
  the move ships with a test rather than only with import edits. `HomeScreen` is the first new screen layout since
  the token checker became load-bearing, so `EdgeInsets`/`BorderRadius` literals
  are the likeliest gate failure; `design.md` says how that is avoided.
- **Figma nodes consumed:** `40:161` (`BalanceCard`, already implemented, both
  variants). No new nodes — Figma has no Home frame, so the screen's arrangement
  is a recorded decision.

## Audit history

Two `spec-auditor` passes, both `NOT READY`, recorded in
`docs/ai-workflow/audits/`. The second narrowed from eleven findings to four and
confirmed the structural work — the architecture problem solved rather than
asserted away, the duplication removed, ADR 0004's argument made honest. What it
caught the second time was subtler and worth naming: three of the four product
decisions were stated correctly in prose while the *requirement* still let two
implementations disagree, and one task could not pass its own coverage gate.

The first version of these artifacts was reviewed by the `spec-auditor` agent and
returned `NOT READY`
(`docs/ai-workflow/audits/2026-08-24-home-overview-spec-audit.md`). Its two
blocking findings were that this proposal's claim "`lib/features/transactions` is
not modified" was false, and that ADR 0004's deciding argument did not survive
contact with `tool/coverage_critical.txt`. Both are corrected above and in ADR
0004 v2. The audit is kept rather than superseded.
