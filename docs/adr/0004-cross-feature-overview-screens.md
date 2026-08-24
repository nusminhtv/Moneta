# 0004. Where a cross-feature overview screen lives

- **Status:** Accepted
- **Date:** 2026-08-24
- **Change:** home-overview

## Context

The Home overview is the first screen that needs data it does not own. Figma
calls `BalanceCard` the "Home hero"; it needs a period summary, and the list
below it needs recent transactions. Both belong to the transactions feature.
Budgets and goals will want to appear there too.

`tool/check_architecture.dart` states:

```
'features': ['core', 'design_system', 'data', 'self'],
'app':      ['core', 'design_system', 'data', 'features', 'app'],
```

So `lib/features/home` **may not import** `lib/features/transactions`. That is
not an oversight to route around — cross-feature imports are the specific thing
the rule exists to prevent, because they are how two features quietly fuse into
one. But an overview screen is, by definition, about more than one feature. The
rule and the screen are in genuine tension, and this decides which way it bends.

A second constraint that turns out to matter: `tool/coverage_critical.txt` gates
`*/domain/` and `*/data/` at 85%. `lib/app` matches neither, so anything put
there is covered only by the 70% project floor.

## Options considered

### Option A — Home lives in `lib/app`

`app` may import anything, so the problem disappears by construction. Home is a
composition of feature surfaces, and a composition root is what `app` is.

- Cost: `lib/app` currently holds wiring only — a router, a shell, a theme
  binding. A screen with a controller and derived state is a different kind of
  thing, and `app` has no coverage gate, so the period-selection and
  masking logic would sit in the one place the strict threshold does not reach.
- Wrong if: Home's logic is more than assembly. It already is — choosing the
  current month's bounds, deriving safe-to-spend, persisting the mask.

### Option B — Move the shared reads down into `lib/data`

Relocate `TransactionRepository` and `Transaction` from the feature's `domain/`
into `lib/data`, which every feature may import.

- Cost: this drains feature domains into a shared bucket. It works once, and then
  budgets need it, and goals need it, and `lib/data` becomes the app's real domain
  layer with `features/*/domain` left holding nothing. The rule would still pass
  while the architecture it protects had dissolved.
- Wrong if: only one entity is ever shared. Two already are.

### Option C — Home lives inside `features/transactions/presentation`

No new feature, no new rule interaction.

- Cost: Home is not about transactions. The moment a budget card appears on it,
  the same wall is hit one level down — `features/transactions` cannot import
  `features/budgets` either. It buys nothing and mislabels the code.

### Option D — Home declares a port; `lib/app` supplies the adapter

`features/home/domain` defines what Home needs and nothing about where it comes
from:

```dart
abstract interface class HomeDataSource {
  Future<Result<HomeSnapshot>> load(DateTimeRange period);
}
```

`lib/app` — the only layer allowed to see both features — implements it against
`TransactionRepository` and registers it. Home's controller depends on the port.

- Cost: one interface and one adapter, and a reader has to follow one hop to see
  where the data comes from.
- Benefit: the rule stays intact and keeps meaning what it says; Home's logic
  lives in a `domain/` that the 85% gate covers; and the next surface that needs
  budgets adds a method to the port rather than an import. Home also becomes
  testable against a fake port with no transactions code in the test at all.

### Option E — Widen `_allowedImports` to let features import features

Rejected. `CLAUDE.md` rule 5 forbids weakening a gate to make code fit without
explicit agreement, and this particular widening deletes the guarantee rather
than adjusting it: once any feature may import any feature, the checker stops
saying anything.

## Decision criteria

| Criterion | Weight | Why |
| --- | --- | --- |
| Keeps the architecture rule meaningful | high | It is the only machine check on coupling |
| Scales to the next overview surface | high | Budgets and goals are queued behind this |
| Home logic stays inside a coverage-gated layer | high | Period bounds and masking are real logic |
| Indirection a reader must follow | medium | One hop is acceptable; three is not |
| Amount of code | low | An interface is cheap |

## Decision

**Option D.** `features/home` owns a `HomeDataSource` port in its `domain/`;
`lib/app` implements it against the transactions repository.

Concretely:

- `features/home/domain/home_snapshot.dart` — what Home displays.
- `features/home/domain/home_data_source.dart` — the port, returning `Result`.
- `features/home/presentation/` — controller and screen, depending on the port.
- `lib/app/home_data_source_impl.dart` — the adapter, plus its provider override.

`lib/app` gains one file that knows about two features. That is the honest place
for that knowledge, and it is one file rather than an import edge that anything
can add to later.

## Consequences

- Adding budgets to Home means adding a field to `HomeSnapshot` and a read to the
  adapter — no new import edges anywhere.
- Home is unit-testable against a fake `HomeDataSource`, with no database and no
  transactions code in the test.
- `lib/app` is no longer purely declarative. That should be watched: if the
  adapter grows real logic rather than translation, it is a sign the port is
  shaped wrong.
- The architecture checker is unchanged. Nothing was widened.

## Strongest counter-argument

For a screen that reads two values, Option A is one file and zero indirection,
and Option D's port is exactly the kind of interface that gets written once,
implemented once, and never varies — the textbook definition of speculative
generality. If budgets and goals never actually land on Home, D will have cost an
interface, an adapter, a provider override and a fake, to solve a problem that
had one caller.

The reason it still wins is the coverage gate, not the flexibility: under Option A
the period-bounds and masking logic sits in the one directory the 85% threshold
does not cover, and that logic is where an off-by-one in a month boundary would
hide.

## Revisit when

- A second overview surface lands and the port has still only ever had one
  implementation — that would be evidence the counter-argument was right, and
  collapsing D into A is a small change.
- Or the adapter starts making decisions rather than translating, which means the
  port is at the wrong altitude.
