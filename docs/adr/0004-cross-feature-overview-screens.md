# 0004. Where a cross-feature overview screen lives

- **Status:** Accepted (revised after audit — see *Revision history*)
- **Date:** 2026-08-24
- **Change:** home-overview

## Context

The Home overview is the first screen that needs data it does not own. Figma
calls `BalanceCard` the "Home hero"; it needs a period summary, and the list
below it needs recent transactions. Budgets and goals will want to appear there
too.

`tool/check_architecture.dart` states:

```
'features': ['core', 'design_system', 'data', 'self'],
'app':      ['core', 'design_system', 'data', 'features', 'app'],
```

So `lib/features/home` **may not import** `lib/features/transactions`. That is
not an oversight to route around — cross-feature imports are the specific thing
the rule exists to prevent, because they are how two features quietly fuse into
one. But an overview screen is, by definition, about more than one feature.

Two facts about the current code shape every option below. Both were confirmed
by reading it, not assumed:

1. **`Transaction` itself is unusable in `features/home`.** It lives in
   `features/transactions/domain`, so *any* option that puts it in a Home type
   fails the gate. A probe file importing it produces
   `✗ architecture: 1 violation(s)`. Home needs its own recent-item type and a
   mapper regardless of which option wins.
2. **The shared providers are in the wrong place already.** `clockProvider`,
   `walletCurrencyProvider` and `appDatabaseProvider` sit in
   `features/transactions/presentation/transaction_providers.dart`. Home needs
   all three and may not import them. They have to move to `lib/data` under every
   option. This is not a cost of any one option; it is a pre-existing defect that
   Home is the first caller to expose.

## Options considered

### Option A — Home lives in `lib/app`

`app` may import anything, so the problem disappears by construction.

- Cost: `lib/app` holds wiring — a router, a shell, a theme binding. A screen with
  derived state is a different kind of thing, and `lib/app` matches nothing in
  `tool/coverage_critical.txt`, so period-bounds and masking logic would sit under
  the 70% floor rather than the 85% one.

### Option B — Move the shared reads down into `lib/data`

Relocate `TransactionRepository` and `Transaction` into `lib/data`.

- Cost: this drains feature domains into a shared bucket. It works once, then
  budgets need it, then goals, and `lib/data` becomes the real domain layer while
  `features/*/domain` holds nothing. The rule would still pass while what it
  protects had dissolved.

### Option C — Home lives inside `features/transactions/presentation`

- Cost: Home is not about transactions, and the moment a budget card appears the
  same wall is hit one level down. Buys nothing, mislabels the code.

### Option D — Home declares a data port; `lib/app` supplies the adapter

`features/home/domain` declares `HomeDataSource`; `lib/app` implements it against
`TransactionRepository`.

- Cost: an interface, an adapter, a provider override and a fake, plus one hop for
  a reader.
- Benefit claimed in the first version of this ADR: coverage. **That claim was
  wrong** — see *Why the first version of this ADR was wrong*.

### Option E — Widen `_allowedImports` so features may import features

Rejected. `CLAUDE.md` rule 5 forbids weakening a gate without explicit agreement,
and this widening deletes the guarantee rather than adjusting it: once any feature
may import any feature, the checker stops saying anything at all.

### Option F — Pure value types in `features/home/domain`, assembled in `lib/app`

`features/home/domain` holds only data and derivation:

```dart
final class HomePeriod    { /* month bounds, inclusive start, exclusive end */ }
final class RecentEntry   { /* id, title, Money, direction, category, instant */ }
final class HomeSnapshot  { /* balance, income, expenses, recent; safeToSpend */ }
```

No interface. A provider in `lib/app` reads `TransactionRepository`, maps rows to
`RecentEntry`, and constructs the `HomeSnapshot`. The Home controller depends on
that provider's value, not on an abstraction.

- Cost: the controller's test overrides a provider that returns a `HomeSnapshot`
  rather than injecting a fake port. Functionally the same substitution, one fewer
  type to maintain.
- Benefit: identical coverage properties to Option D — the derivation being tested
  is in `features/home/domain` either way — with no interface that has exactly one
  implementation.

## Decision criteria

| Criterion | Weight | Why |
| --- | --- | --- |
| Keeps the architecture rule meaningful | high | It is the only machine check on coupling |
| Derivation logic sits where the 85% gate reaches it | high | Month bounds and safe-to-spend are where an off-by-one hides |
| Home is testable without a database | high | Otherwise every UI test needs SQLite |
| Abstractions earn their keep | medium | An interface with one implementation is a liability, not a seam |
| Scales to the next overview surface | medium | Budgets and goals are queued behind this |

## Decision

**Option F.** `features/home/domain` holds `HomePeriod`, `RecentEntry` and
`HomeSnapshot` as pure value types; a provider in `lib/app` assembles the snapshot
from `TransactionRepository`. No `HomeDataSource` interface.

Supporting moves, both required by *any* option and now owned by this change:

- `RecentEntry` in `features/home/domain`, carrying only `core` types
  (`Money`, `TransactionDirection`, `SpendCategory`) plus an id, a title and an
  instant. The `Transaction → RecentEntry` mapper lives in `lib/app`.
- `clockProvider`, `idGeneratorProvider`, `walletCurrencyProvider` and
  `appDatabaseProvider` move from `features/transactions/presentation` to
  `lib/data/app_providers.dart`. Riverpod is a package, not a layer, so `lib/data`
  may hold providers; `lib/core` stays Flutter-free.

## Why the first version of this ADR was wrong

The first version chose Option D and said the deciding factor was the coverage
gate, not flexibility. The `spec-auditor` agent took that apart, and it was right
on all three counts:

1. **`tool/coverage_critical.txt` is a five-line substring list.** Adding
   `lib/app/` to it is *tightening* a gate, which rule 5 explicitly permits. A
   deciding factor that a one-line config edit dissolves is not a deciding factor.
2. **The argument was half-wrong about its own option.** It named "period-bounds
   and masking logic", but masking lives in `features/home/presentation/`, which
   matches neither `/domain/` nor `/data/` — the exact exposure Option A was
   rejected for. Option D fixed coverage for the value types only, which Option F
   also does.
3. **Option F was never scored.** Because it was missing, the ADR never had to
   answer why a port beats it — and the port's only remaining argument was the
   flexibility rationale that the ADR's own counter-argument called speculative
   generality.

Recorded rather than quietly reversed. The failure mode is worth naming: the ADR
reached a defensible *conclusion* (derivation belongs in `features/home/domain`)
and then reverse-engineered a rigorous-sounding reason for a *different*
decision (the port) that the conclusion did not require.

## Consequences

- One fewer type than the port design, and no fake to keep in step with a real
  implementation.
- Adding budgets to Home means adding a field to `HomeSnapshot` and a read to the
  assembling provider. Still no new import edges.
- `lib/app` gains a mapper and an assembler. If either starts making decisions
  rather than translating, the derivation is in the wrong place and Option D
  becomes worth reconsidering — that is the trigger, not a schedule.
- The architecture checker is unchanged. Nothing was widened.
- The provider relocation means `features/transactions` **is** modified by this
  change, and its tests with it. The `home-overview` proposal originally claimed
  the opposite; that claim is corrected.

## Strongest counter-argument

Option A is still fewer moving parts than F: no `features/home` at all, one file
in `lib/app`, and `lib/app/` added to `coverage_critical.txt` to keep the 85%
threshold. That is genuinely simpler, and the only thing F buys over it is that
`features/home/domain` is a directory whose *name* says the logic is domain logic.

F wins on a weaker argument than the first version of this ADR pretended to have:
`lib/app` is the composition root, and a composition root that also owns the
month-boundary arithmetic and the safe-to-spend rule is doing two jobs. That is a
judgement about where things belong, not a constraint the tooling imposes — and it
should be read as such.

## Revisit when

- A second overview surface lands and the assembling provider in `lib/app` has
  grown branching logic — that is the signal the derivation drifted out of
  `features/home/domain`.
- Or `features/home/domain` never gains anything beyond these three types, in
  which case the counter-argument was right and collapsing F into A is small.

## Revision history

- **v1, 2026-08-24** — chose Option D (port + adapter), citing the coverage gate.
- **v2, 2026-08-24** — `spec-auditor` returned `NOT READY`; the coverage argument
  did not survive it and Option F was missing entirely. Rewritten with six
  options, Option F chosen, and the original error kept above rather than deleted.
  Audit: `docs/ai-workflow/audits/2026-08-24-home-overview-spec-audit.md`.
