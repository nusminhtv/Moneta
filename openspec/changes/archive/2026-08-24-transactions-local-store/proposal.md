## Why

Moneta currently renders a design system against fixtures. Nothing is stored, so
the app cannot answer the only question it exists to answer: where did the money
go. This change makes the device the source of truth.

It is also the first change that exercises the whole stack — `lib/data`,
a feature's `domain`, `data` and `presentation`, and `lib/app` — so it is where
the layer boundaries either hold or turn out to be wrong.

The user-visible outcome: record a transaction, see it in a date-grouped list
that survives restarting the app, filter it by category, and delete it. The home
balance stops being a fixture and starts being the sum of what is stored.

## What Changes

- **New database layer** `lib/data/`: a versioned SQLite database opened through
  a single entry point, an explicit migration runner, and shared DAO
  infrastructure. Migration `v1` creates the `transactions` table.
- **New capability `transactions`** as a feature slice:
  - `domain/`: a `Transaction` entity, a `TransactionDirection` (income or
    expense), a `TransactionQuery` describing a filtered read, and a
    `TransactionRepository` interface returning `Result<T>`.
  - `data/`: `TransactionDao` (SQL) and `SqliteTransactionRepository`, including
    row↔entity mapping and its round-trip test.
  - `presentation/`: a date-grouped list screen with empty and error states, an
    add form, swipe-to-delete with undo, and Riverpod controllers.
- **New derived read**: a period summary (total balance, income, expenses)
  computed by SQL aggregate rather than by loading every row, so the home
  surface stays correct as the table grows.
- **New design-system molecule `TransactionRow`**. Figma has no such component
  and no screen frames, so its layout is a **design decision this change makes**
  from the existing tokens and `CategoryIcon`, recorded in an ADR rather than
  presented as a transcription.
- **App wiring**: real routes for the transactions destination, the bottom
  navigation connected to the router, and the add action opening the form.

## Capabilities

### New Capabilities
- `transactions`: what a transaction is, how it is recorded, read back,
  filtered, aggregated and deleted, and what must remain true across restarts.
- `storage/local-database`: the persistence contract — versioning, migration,
  durability and failure reporting — independent of any one feature's tables.

### Modified Capabilities
- `design-system/components`: adds `TransactionRow` to the component set. No
  existing component's behaviour changes.

## Non-goals

- **No editing an existing transaction.** Create, read and delete only. Editing
  needs an audit story that is out of scope here.
- **No accounts.** Every transaction belongs to the implicit default account.
  Figma has an `AccountCard` with four types; wiring real accounts is its own
  change.
- **No budgets.** `BudgetCard` exists but nothing yet stores a limit.
- **No multi-currency.** Everything is VND. `Money` already supports more, and
  the schema stores a currency code, but no conversion exists and mixing
  currencies is an error rather than a feature.
- **No sync, no export, no attachments, no recurring transactions.**
- **No search.** Filtering is by category and date range only.
- **No Insights or Profile screens.**

## Impact

- **Modules touched:** `lib/data` (new), `lib/features/transactions` (new),
  `lib/design_system/molecules` (one addition), `lib/app` (routing), plus tests
  in all four. This is deliberately the first change to cross every layer.
- **Dependencies:** none added. `sqflite`, `path` and `sqflite_common_ffi` are
  already declared and currently unused.
- **Schema migration:** yes — this introduces schema version 1. There is no
  existing data to migrate, but the runner and its tests are built now, because
  retrofitting a migration story after the first release is how data gets lost.
- **Gates affected:** `tool/coverage_critical.txt` already requires ≥85% on
  `*/domain/` and `*/data/`; this change is the first code those patterns match.
- **Platform:** database tests run on the Dart VM via `sqflite_common_ffi`, so
  no simulator is needed in CI.
