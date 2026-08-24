## Context

Home is the first screen that reads data it does not own.
[ADR 0004 v2](../../../docs/adr/0004-cross-feature-overview-screens.md) settles
where it lives — pure value types in `features/home/domain`, assembled by a
provider in `lib/app`, with no data-source interface. This document takes that as
given.

Two facts from the audit shape everything else, and both were verified against the
code rather than assumed:

- **`Transaction` cannot appear in `features/home`.** A probe file importing it
  produces `✗ architecture: 1 violation(s)`. Home needs its own recent-item type
  and a mapper, whatever else is decided.
- **The shared providers are already in the wrong place.** `clockProvider`,
  `walletCurrencyProvider` and `appDatabaseProvider` sit in
  `features/transactions/presentation`. Home may not import them, so they move.

## Goals / Non-goals

**Goals**: this month's figures on the existing hero card, five recent
transactions, masking that covers every amount and survives a restart, refresh on
record, honest empty and error states, and `features/home` free of any other
feature.

**Non-goals**: budgets, month switching, accounts, charts, pull-to-refresh,
Insights, Profile, currency conversion, and fixing the archived summary bug.

## Decisions

### D1 — `HomePeriod` is a value object, not two loose `DateTime`s

**Options.** (a) pass `start` and `end` around; (b) a value object that computes
its own bounds.

(a) puts month arithmetic at every call site, and the month boundary is exactly
where an off-by-one hides — inclusive start, exclusive end, and a DST month that
is 23 or 25 hours long.

**Chosen: (b).** `HomePeriod.currentMonth(Clock)` plus an arbitrary-range
constructor, so a month switcher later is a constructor rather than a refactor.

The bounds are built from calendar fields. `tasks.md` deliberately does **not**
prescribe the expression — the audit's point was that a task naming the
implementation leaves its test able only to re-assert that expression. The test
asserts the boundary instants, December rolling into January, and a DST month
spanning exactly one month.

`HomePeriod` also exposes `lastDayInclusive`, the final day *within* the period,
because the end bound is exclusive and "until 1 Sep" would be a date outside the
period the figure describes.

### D2 — Balance excludes what has not happened yet

Total balance is the net of transactions occurring **at or before now**; period
income and expenses cover the displayed month. Two aggregate reads, both bounded.

**Options.** (a) all-time with no upper bound; (b) bounded at now.

(a) is one fewer bound and was the first draft. The audit pointed out that the
archived `transactions` capability rejects future-dated entries with the stated
reason *"a balance that includes money not yet spent is wrong"* — so (a)
contradicts a rationale already in the spec set, and does so invisibly today only
because the add form is the sole write path.

**Chosen: (b).** `TransactionQuery.build(end: clock.nowUtc())` for the balance
read. It costs one bound and removes a disagreement between two capabilities.

The tempting shortcut — showing the period's net as the balance — is wrong in a
way that looks right: in the first month of use the two agree exactly, so it
survives casual testing. A test asserts a case where they differ in sign.

### D3 — Safe-to-spend is floored at zero, and the definition is in the spec

Period income minus period expenses, floored at zero.

The floor is a product decision, not arithmetic: `Money` holds negatives happily,
and "safe to spend −2,000,000 ₫" is not a meaning the phrase has. The alternative
— surfacing the overspend as a negative — conflates two messages, and the one
worth showing is a budget warning this change does not build.

### D4 — Preferences are a table in the database already open

**Options.** (a) `shared_preferences`; (b) a `settings` table as migration v2.

(a) is one line and conventional. It also adds a dependency, puts durable state in
a second store with different failure modes and no migration story, and cannot be
read alongside anything else.

**(b).** `settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)`. One place data
lives, one backup surface, no new dependency, and it exercises the migration
runner against real rows — which is worth something on its own.

Booleans are stored as the literal text `true` or `false` and **nothing else** is
accepted. The spec names the form, because the audit's point stands: `'1'` and
`'true'` are both reasonable, and a value written by one convention is malformed
to the other. A malformed value is a storage failure naming the key, not a silent
`false`.

### D5 — The mask preference must not be able to fail the screen

Snapshot loading and the mask preference are read separately, and only the
snapshot can produce an error state. A failed preference **read** falls back to
revealed.

Revealed, not hidden: hiding on failure looks like the safer default but makes an
unreadable preference indistinguishable from a working feature, and the user
cannot tell why their figures vanished.

A failed **write** is different — the user just acted, so the on-screen state
follows their action for the session and the failure is surfaced. Silently
discarding it would mean the setting appears to work and then does not survive a
restart.

### D6 — Everything crossing a boundary is a domain type

`HomeSnapshot` carries `Money`, `TransactionDirection`, `SpendCategory` and
`DateTime`. `BalanceCard` takes the period's last day as a `DateTime` and formats
it — which is why the prerequisite change exists. `TransactionRow` already takes
`Money` and a direction.

This is the decision the audit found contradicted: D6 claimed formatting stays in
the design system while `BalanceCard` required a pre-formatted string. The
contradiction is resolved by fixing the component, not by weakening D6.

### D7 — The recent list is not bounded by the period

The hero card is about a month; the list is about *recency*. A period-bounded list
would be empty for a user who recorded nothing this month while their history is
not, which reads as data loss.

So three reads: `summarise` bounded at now (balance), `summarise` bounded to the
month (income and expenses), and `list` with a limit and no range.

### D8 — Five recent entries, pinned in the spec

`recentLimit = 5`, stated as a requirement rather than only as a constant, because
a constant can only be asserted against itself.

Not read from Figma — there is no Home frame — so it is a decision, recorded in
`figma-map.md` alongside `TransactionRow`. Task 5.3 revisits it against a device
screenshot and says whether five was right.

### D9 — `RecentEntry` is Home's own type; the mapper lives in `lib/app`

`RecentEntry` carries an id, a display title, a `Money` amount, a direction, a
category and an occurrence instant — all shared types. `Transaction.displayTitle`
already resolves note-or-category-name, so the mapper reads it rather than
reimplementing the fallback.

**Options for the mapper's home.** (a) `lib/app`; (b) an extension in
`features/transactions`; (c) `lib/data`.

(b) makes the transactions feature know about Home, which is the coupling the rule
exists to prevent, only pointing the other way. (c) puts a presentation-shaped DTO
in the data layer. **(a)** — `lib/app` already sees both, and the mapper is
translation with no decisions in it. If it acquires branching logic, that is the
signal the derivation drifted out of `features/home/domain`.

### D10 — Shared providers move to `lib/data/app_providers.dart`

`clockProvider`, `idGeneratorProvider`, `walletCurrencyProvider` and
`appDatabaseProvider` move out of `features/transactions/presentation`.

**Options.** (a) `lib/core`; (b) `lib/data`; (c) `lib/app`.

(a) would pull `flutter_riverpod` — and therefore Flutter — into a layer `CLAUDE.md`
describes as pure Dart. (c) is unreachable: features may not import `app`, and
features need these. **(b)** — `lib/data` may be imported by every feature, and
Riverpod is a package rather than a layer, so nothing in the architecture rules
objects.

`transactionRepositoryProvider` stays in the transactions feature; only the
genuinely shared ones move.

### D11 — Refresh on record is the controller's, triggered by the shell

The add sheet is opened from the shell FAB on every destination. Rather than
having the sheet know which screens care, the Home controller invalidates itself
when it becomes visible after the sheet closes.

**Options.** (a) the sheet invalidates known providers; (b) Home refreshes on
sheet dismissal; (c) a shared "transactions changed" signal.

(a) makes the add sheet depend on every screen that displays transactions. (c) is
the right long-term answer and is more machinery than two screens justify.
**(b)** for now, with (c) noted as the thing to build when a third screen needs it.

### D12 — `HomeScreen` layout resolves through tokens only

The audit noted `design.md` never mentioned `tool/check_design_tokens.dart`, and
that a new screen is where it most likely fires. Concretely:

- Vertical rhythm between hero, section heading and list: `theme.spacing.*`.
- Screen padding: `spacing.x4l`, matching `TransactionsScreen`.
- Empty and error states reuse the shapes `TransactionsScreen` already
  established, so no new radii or insets are introduced.
- No `EdgeInsets.all(<number>)` and no `BorderRadius.circular(<number>)` anywhere
  in the feature — the checker matches a numeric literal argument specifically, so
  a token-derived expression is fine and a magic number is not.

### D13 — Failure kinds are named

- A read reporting `storage` → error state with retry.
- A `validation` failure from `TransactionQuery.build` → a defect in Home, since
  Home constructs those queries itself. Asserted unreachable by test, not
  rendered.
- A summary whose currency is not the wallet currency → a `validation` failure
  raised by Home before any arithmetic, so a mismatch cannot reach
  `Money.operator -` and throw. This is a guard against the archived summary bug,
  not a fix for it.

## Risks / trade-offs

- **`lib/app` gains logic-shaped code.** A mapper and an assembler. Watched: if
  either branches on anything, the derivation belongs in `features/home/domain`.
- **Three reads per load.** All aggregate or indexed. Accepted because they are
  the existing reusable reads; a single fused query would live in the assembler,
  which ADR 0004 wants thin.
- **Migration v2 on real user data.** Mitigated by the test that writes v1 rows,
  reopens at v2 and asserts them unchanged — the reason to add this table now
  rather than when it is urgent.
- **The provider relocation touches archived code and its tests.** Mechanical, but
  it is the largest diff in the change and it is not what the change is about.
- **`RecentEntry` duplicates part of `Transaction`.** Deliberate: the alternative
  is a cross-feature import. If a third feature needs the same shape, that is the
  signal to promote it to `lib/core`.

## Verification plan

| Spec requirement | Verified by |
| --- | --- |
| Period is the current local month | `test/features/home/domain/home_period_test.dart` — boundary instants asserted directly |
| December rolls to January | `home_period_test` |
| DST month spans exactly the month | `home_period_test` — transition months, no hour gained or lost |
| Bounds converted to UTC | `home_period_test` |
| `lastDayInclusive` is inside the period | `home_period_test` |
| Occurrence, not entry, positions a transaction | `home_snapshot_test`, `home_assembler_test` — a backdated transaction |
| Balance excludes future-dated transactions | `test/app/home_assembler_test.dart` |
| Balance and period net differ in sign | `home_assembler_test` |
| First run shows formatted zeros | `home_controller_test`, `home_screen_test` |
| Very large totals exact or refused | `home_snapshot_test` |
| Safe-to-spend definition and zero floor | `home_snapshot_test` — income >, =, < expenses |
| Five most recent, by occurrence | `home_assembler_test` |
| Recent list not period-bounded | `home_assembler_test` |
| `RecentEntry` carries only shared types | `dart run tool/check_architecture.dart` + compile |
| Masking hides every amount, hero and list | `test/features/home/presentation/home_screen_test.dart` — no digit belonging to an amount in the render tree |
| Non-amount content stays visible when masked | `home_screen_test` |
| Mask preference durable | `test/data/preferences_store_test.dart` + `home_controller_test` |
| Absent preference means revealed | `home_controller_test` |
| Failed preference read still renders, revealed | `home_controller_test` |
| Failed preference write follows the user, surfaces | `home_controller_test` |
| Error state vs empty state; partial failure is failure | `home_screen_test` |
| Retry succeeds; retry fails again | `home_screen_test` |
| Validation failure is unreachable | `home_controller_test` |
| Currency mismatch refused, not added | `home_assembler_test` |
| Negative magnitudes cannot occur | `home_snapshot_test` — asserted, not guarded |
| New transaction appears without manual refresh | `test/app/router_test.dart` |
| Composed from existing components, both variants | `home_screen_test` |
| Absent key ≠ value; fallback writes nothing | `preferences_store_test` |
| One stored boolean form; malformed is a failure naming the key | `preferences_store_test` |
| Overwrite leaves one row; last write wins | `preferences_store_test` |
| Keys declared once, names unique | `preferences_store_test` |
| Rows survive a migration on a populated database | `test/data/migrations_test.dart` |
| A failed migration on populated data | `test/data/database_test.dart` |

Plus the standing gates: format, analyze `--fatal-infos`, architecture,
design-tokens, hooks, tests, coverage (≥85% on `features/home/domain`,
`lib/data/preferences`).

## Open questions

None blocking. `recentLimit = 5` is a judgement to be revisited against a device
screenshot in task 5.3, and D11's refresh mechanism is expected to be replaced by
a shared change signal when a third screen needs one — both recorded above rather
than left open.
