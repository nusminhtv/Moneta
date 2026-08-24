## Context

Home is the first screen that reads data it does not own, so the architecture
rule — a feature may not import another feature — either bends here or is honoured
with an indirection. [ADR 0004](../../../docs/adr/0004-cross-feature-overview-screens.md)
scores five options and chooses the port/adapter split; this document takes that
as given and works out the rest.

The other constraint worth stating up front: migration v2 is the first migration
this app will apply to a database that already has rows in it. Change 2 built the
runner and tested it, but with only one version there was nothing to upgrade
*from* with data present. That gap is closed here.

## Goals / Non-goals

**Goals**: a Home overview showing this month's figures on the existing hero card,
recent transactions below it, a mask preference that survives a restart, honest
empty and error states, and a data port that keeps `features/home` free of any
other feature.

**Non-goals**: budgets on Home, month switching, accounts, charts, pull-to-refresh,
Insights, Profile, multi-currency.

## Decisions

### D1 — `HomePeriod` is a value object, not two loose `DateTime`s

**Options.** (a) pass `start` and `end` around; (b) a `HomePeriod` value object
that computes its own bounds.

(a) is fewer lines and puts the month arithmetic at every call site. The month
boundary is exactly where an off-by-one hides — inclusive start, exclusive end,
and a DST month that is 23 or 25 hours long.

**Chosen: (b).** `HomePeriod.currentMonth(Clock)` builds local month bounds by
constructing `DateTime(year, month, 1)` and `DateTime(year, month + 1, 1)` —
never by adding a 30-day duration — then converts to UTC for querying.
`DateTime(2026, 13, 1)` correctly rolls to January 2027, which is why the month+1
form is used rather than a branch on December.

The type takes an arbitrary range, so a month-switcher later is a constructor,
not a refactor.

### D2 — Total balance is a separate read from the period summary

Balance is all-time; income and expenses are per-period. Two aggregate queries,
not one, and not a fold over rows.

The tempting shortcut is to show the period's net as the balance. It is wrong in a
way that looks right: in a good month it agrees with nothing and reads plausibly,
and in the first month of use it agrees exactly, so it survives casual testing.
The spec states both separately and the tests assert a case where they differ in
sign.

`TransactionRepository.summarise(TransactionQuery.all)` already gives the all-time
figures, so this costs one extra call and no new SQL.

### D3 — Safe-to-spend is floored at zero, and the definition is pinned

Income minus expenses for the period, floored at zero.

The floor is a product decision, not arithmetic: `Money` will happily hold a
negative, and "safe to spend −2,000,000 ₫" is not a meaning the phrase has. The
alternative — showing the overspend as a negative safe-to-spend — conflates two
different messages, and the one worth showing when a user has overspent is a
budget warning, which this change does not build.

Written into the spec rather than left as an implementation detail, because
"safe to spend" is the kind of phrase three people define three ways.

### D4 — Preferences are a table in the existing database, not `shared_preferences`

**Options.** (a) `shared_preferences`; (b) a `settings` key/value table in the
SQLite database already open.

(a) is one line to adopt and is the conventional answer. It also adds a
dependency, puts durable state in a second store with different failure modes and
no migration story, and cannot be read in the same transaction as anything else.

**(b).** `settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)` as migration v2.
No new dependency, one place data lives, one backup surface, and it exercises the
migration runner against real data — which is worth something on its own.

Values are stored as `TEXT` and parsed by the caller through a typed accessor.
A malformed value is a storage failure, not a silent `false`: a preference that
reads as its default when the stored data is corrupt is how a bug becomes
invisible.

### D5 — The mask preference must not be able to fail the screen

`HomeSnapshot` loading and the mask preference are read separately, and only the
snapshot can produce an error state. A failed preference read logs and falls back
to *revealed*.

Falling back to revealed rather than hidden is deliberate: hiding on failure
would be the safer-looking default, but it makes an unreadable preference look
like a working feature, and the user cannot tell why their figures vanished.
Revealed is the state they can act on.

### D6 — `HomeSnapshot` carries `Money` and entities, not formatted strings

The port returns domain types. Formatting stays in the design system, where
`BalanceCard` and `TransactionRow` already own it, so Home cannot disagree with
the transactions list about how money is written.

### D7 — The recent list is not bounded by the period

The hero card is about a month; the recent list is about *recency*. If a user has
recorded nothing this month, a period-bounded recent list would be empty while
their history is not, which reads as data loss.

So: `summarise` twice (all-time, period) and `list` once with a limit and no
range. Three reads, all aggregates or indexed, none scaling with total rows
beyond the limit.

### D8 — Recent-list length is a named constant, not a magic number

`HomeSnapshot.recentLimit = 5`. Not read from Figma — Figma has no Home frame at
all, so this is a decision, and it is labelled as one in `figma-map.md` alongside
`TransactionRow`.

## Risks / trade-offs

- **The port may be speculative generality.** ADR 0004's own counter-argument:
  if budgets and goals never land on Home, `HomeDataSource` will have had one
  implementation forever. Recorded there with the condition that would prove it
  wrong.
- **Three reads per load.** All indexed or aggregate, but it is three round trips
  where a bespoke query would be one. Accepted because the reads are reusable and
  a single fused query would live in the adapter, which ADR 0004 wants kept thin.
- **`lib/app` stops being purely declarative.** One file there now knows about two
  features. Watched: if the adapter starts deciding rather than translating, the
  port is at the wrong altitude.
- **Migration v2 on real user data.** The risk is real and the mitigation is the
  test: rows written under v1, then opened at v2, asserted unchanged. That test is
  the reason to add this table now rather than when it is urgent.

## Verification plan

| Spec requirement | Verified by |
| --- | --- |
| Period is the current local month | `test/features/home/domain/home_period_test.dart` |
| Inclusive start, exclusive end | `home_period_test` — boundary instants asserted directly |
| Period derived in local time | `home_period_test` |
| DST month spans exactly the month | `home_period_test` — transition months, no hour gained or lost |
| December rolls to January | `home_period_test` |
| Balance is all-time, not the period | `test/features/home/domain/home_snapshot_test.dart` and `home_controller_test` — a case where the two differ in sign |
| First run shows formatted zeros | `home_controller_test`, `home_screen_test` |
| Safe-to-spend definition and zero floor | `home_snapshot_test` — income>expenses, equal, expenses>income |
| Recent list limit and ordering | `home_controller_test` |
| Recent list not period-bounded | `home_controller_test` — newest transaction outside the period still listed |
| Masking hides every digit | `test/features/home/presentation/home_screen_test.dart` — no digit in the render tree |
| Mask preference is durable | `test/data/preferences_store_test.dart` (write/close/reopen) + `home_controller_test` |
| A failed preference read still renders, revealed | `home_controller_test` |
| Error state vs empty state | `home_screen_test` |
| Retry succeeds and retry-fails-again | `home_screen_test` |
| Home depends only on the port | `dart run tool/check_architecture.dart`, plus `home_controller_test` using only a fake port |
| Preference absent ≠ false | `preferences_store_test` |
| Malformed stored value is a failure | `preferences_store_test` |
| Preference keys declared once, unique | `preferences_store_test` |
| Migration preserves rows in a populated database | `test/data/migrations_test.dart` — v1 rows written, opened at v2, asserted unchanged |
| Failed migration on populated data | `test/data/database_test.dart` |

Plus the standing gates: format, analyze `--fatal-infos`, architecture,
design-tokens, hooks, tests, coverage (≥85% on `features/home/domain` and
`lib/data`).

## Open questions

- **Recent-list length.** Set to 5. No Figma Home frame exists to read it from, so
  this is a guess at what fits above the fold on a 393×852 frame with the hero
  card present. Worth revisiting against a real device screenshot during
  close-out.
