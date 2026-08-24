# 0001. Local persistence layer

- **Status:** Accepted
- **Date:** 2026-08-24
- **Change:** cross-cutting (bootstrap)

## Context

Moneta is local-first: the on-device database is the source of truth, with no
backend to reconcile against. That makes the persistence choice hard to reverse —
it shapes the repository interfaces, the test strategy, and every future
migration.

Constraints that actually apply here:

- Money is stored as integer minor units (`lib/core/money.dart`), so the store
  only needs integers, text and timestamps. No decimal type is required.
- `tool/check_architecture.dart` forbids `lib/data` from importing anything but
  `core` and `data`, so whatever we pick must not leak generated types into
  `features/*/domain`.
- The coverage gate requires ≥85% line coverage on `*/data/`, so the database
  must be testable on the plain Dart VM without a simulator.
- Reporting queries (spend by category and month, budget rollups) are aggregate
  queries. They are the reason this is a database question and not a
  key-value-store question.

## Options considered

### Option A — `sqflite` with hand-written SQL

Raw SQLite with a thin DAO layer. Migrations are explicit `ALTER`/`CREATE`
statements keyed by schema version. Tests run on the VM via
`sqflite_common_ffi`.

- Cost: SQL is written and reviewed by hand; no compile-time checking of column
  names. Mapping rows to entities is manual boilerplate.
- Makes harder later: large schema refactors touch several hand-written mappers.
- Wrong if: the query surface grows past a few dozen statements, at which point
  the absence of compile-time checking starts costing real bugs.

### Option B — `drift` (code-generated, type-safe SQL)

Declarative table definitions, generated DAOs, compile-time-checked queries,
generated migration helpers, in-memory `NativeDatabase.memory()` for tests.

- Cost: `build_runner` in the loop. Generated `*.g.dart` files are excluded from
  analysis, which means a meaningful share of the data layer stops being checked
  by our own gates. Every schema edit becomes edit → regenerate → verify.
- Makes harder later: nothing much; drift scales up well.
- Wrong if: the codegen step ends up fighting the verification gate, or the
  generated surface leaks into layers that are supposed to be pure.

### Option C — `Isar` / `Hive` (object store, no SQL)

Store entities as objects, query with a Dart API.

- Cost: aggregate reporting queries become in-Dart loops over the full
  collection, which is exactly the workload this app has. Isar's Flutter-3.4x
  maintenance situation is an additional risk for a store we cannot migrate off
  easily.
- Wrong if: reporting stays trivially small — which is not the plan.

### Option D — do nothing yet (in-memory repositories, decide later)

Ship the UI against in-memory fakes and defer the choice.

- Cost: defers the only decision that is genuinely hard to reverse, and lets the
  repository interfaces be shaped by whatever the fakes happen to make easy.

## Decision criteria

| Criterion | Weight | Why it matters here |
| --- | --- | --- |
| VM-testability without a simulator | high | The coverage gate runs on every change and in CI |
| Fit for aggregate reporting queries | high | Insights and budgets are the product |
| Amount of code the gates can actually check | high | Generated code is excluded from analysis |
| Loop latency per schema change | medium | Schema churn is expected early |
| Compile-time query safety | medium | Valuable, but SQL here is small and reviewable |
| Reversibility | medium | Mitigated by the repository interface either way |

## Decision

**Option A — `sqflite` with hand-written SQL and hand-written mappers**, behind
repository interfaces defined in each feature's `domain/`.

The deciding factor is the third criterion. This project's whole approach is that
AI-authored code is trusted only insofar as gates check it; a codegen-heavy data
layer moves a large part of that code outside the analyzer and outside the
design-token and architecture checkers. Given that the SQL surface here is small
and the money type is already integer-only, hand-written SQL keeps the checked
fraction of the codebase high at a cost we can afford.

Repository interfaces live in `domain/` and return `Result<T>`, so the store is
swappable: the migration path to drift is "reimplement the DAOs", not "rewrite
the app".

## Consequences

- `sqflite` + `path` in `dependencies`; `sqflite_common_ffi` in `dev_dependencies`
  so data-layer tests run on the VM.
- Migrations are explicit and versioned in `lib/data`, with a test per migration
  step asserting the resulting schema and preserved rows.
- Row↔entity mapping is hand-written and must be covered by tests; a mapper
  without a round-trip test is a gate failure, not a style preference.
- No `build_runner` in the verification loop.

## Strongest counter-argument

Hand-written SQL has no compile-time protection against a renamed column, and
the failure mode is a runtime exception on a specific query path rather than a
build error. Drift would eliminate that class of bug outright. The mitigation
here — a test per query — is weaker than a type system, and depends on the tests
actually being written. If a column-rename bug reaches a checkpoint despite the
coverage gate, that is direct evidence this decision was wrong.

## Revisit when

- The DAO layer exceeds roughly 40 distinct statements, or
- a schema rename causes a runtime failure that reached a checkpoint, or
- sync with a backend enters scope (which changes the migration story entirely).
