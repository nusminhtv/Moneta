## Why

Home is the last placeholder destination — it currently renders the words "Not
built yet". It is also where the two most finished components in the design
system have been sitting unused: `BalanceCard`, which Figma explicitly calls the
"Home hero", and `TransactionRow`. The data they need already exists, stored and
summarised, since `transactions-local-store`.

There is a second reason to do this now. Home is the first screen that needs data
it does not own, so it is the first real test of the rule that a feature may not
import another feature. That tension is decided in
[ADR 0004](../../../docs/adr/0004-cross-feature-overview-screens.md) rather than
routed around.

The user-visible outcome: opening the app shows this month's balance, safe-to-spend,
income and expenses on the gradient hero card, with the most recent transactions
below it; hiding the figures with the eye control keeps them hidden after the app
is closed and reopened.

## What Changes

- **Schema migration v2**: a `settings` key/value table, and a `PreferencesStore`
  in `lib/data` for small durable values that belong to no single feature. This is
  the first migration applied to a database that already has rows, which is the
  case the v1 tests could only simulate.
- **New capability `home`** as a feature slice:
  - `domain/`: `HomeSnapshot` (what the screen shows), `HomePeriod` (the month
    boundaries, inclusive start and exclusive end), and a `HomeDataSource` port
    returning `Result<T>`.
  - `presentation/`: a controller that loads the snapshot and owns the mask
    preference, plus `HomeScreen` composing `BalanceCard` and a recent-transaction
    list, with distinct empty and error states.
- **New adapter in `lib/app`**: the single implementation of `HomeDataSource`,
  reading through `TransactionRepository`. Per ADR 0004 this is the only place
  allowed to know about both features, and it is one file rather than an import
  edge anything can widen later.
- **Balance derivation**: total balance is the net of *all* transactions ever, not
  of the displayed month — a month's net is not a balance. Safe-to-spend is
  derived and its definition is pinned in the spec, because "safe to spend" is
  exactly the kind of phrase that means three things to three people.
- **Mask persistence**: the eye control's state survives a restart.
- **App wiring**: Home's route stops being a placeholder.

## Capabilities

### New Capabilities
- `home`: what the overview shows, how its period is bounded, how balance and
  safe-to-spend are derived, and what happens when reads fail.
- `storage/preferences`: durable key/value settings — what is guaranteed about
  reading, writing and absent keys.

### Modified Capabilities
- `storage/local-database`: adds the requirement that a migration applied to a
  database containing rows preserves them. v1 could only be tested against an
  empty database because there was no earlier version.

## Non-goals

- **No budgets on Home.** `BudgetCard` stays without a caller. Budgets need their
  own table, limits, and period rollover; putting a fixture-driven budget card on
  a screen otherwise showing real data would be worse than leaving it off.
- **No month switching.** The current month only. The period type is built to
  take any range so the control is additive later.
- **No account breakdown**, no `AccountCard`, no accounts at all.
- **No Insights or Profile screens.** Still placeholders.
- **No charts.** `chart/1..8` tokens exist and stay unused here.
- **No pull-to-refresh**, no background refresh, no notifications.
- **No multi-currency.** Still VND only; a mixed-currency store is an error, not
  a feature.

## Impact

- **Modules touched:** `lib/data` (migration v2 + preferences), `lib/features/home`
  (new), `lib/app` (adapter + route), plus tests. `lib/features/transactions` is
  **not modified** — Home reads it through the port, which is the point.
- **Dependencies:** none added.
- **Schema migration:** yes, v2. It runs against existing user data, so its test
  asserts rows written under v1 are still readable after the upgrade.
- **Gates affected:** `features/home/domain` becomes subject to the 85% coverage
  threshold. The adapter in `lib/app` is not, which ADR 0004 records as the reason
  the logic lives in `domain/` rather than in the adapter.
- **Figma nodes consumed:** `40:161` (BalanceCard, already implemented). No new
  Figma nodes — the screen layout is composed, and Figma has no screen frames.
