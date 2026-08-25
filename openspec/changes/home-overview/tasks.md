> ## ⛔ FROZEN — 2026-08-25
>
> This change was planned on a false premise: that the Figma file contains no
> screen designs. It contains 74 screens, and the project never opened them
> because `get_metadata` without a `nodeId` returns an incomplete page list.
>
> Do not implement any of the tasks below. The `figma-fidelity` agent is
> reconciling what has already been built against the real designs; this change
> is reopened, revised or discarded once that lands.
>
> See `docs/design-system/figma-map.md` for the correction.

Blocked on `design-system-corrections` (see the proposal's Prerequisite section),
whose artifacts are written and validated. Only **task 4.3** needs it — that is the
task that renders `BalanceCard` and the masked row. Tasks 1 through 4.2 touch no
design-system component and can proceed.

## 1. Data-layer groundwork

- [ ] 1.1 Move `clockProvider`, `idGeneratorProvider`, `walletCurrencyProvider`
  and `appDatabaseProvider` from
  `features/transactions/presentation/transaction_providers.dart` to
  `lib/data/app_providers.dart`, leaving `transactionRepositoryProvider` behind.
  Riverpod overrides bind by object identity rather than by library, so the three
  existing `overrideWithValue` call sites keep working with only their imports
  changed. Verify: `dart run tool/check_architecture.dart` passes and every
  existing test passes with no assertion edited.
- [ ] 1.2 Add `test/data/app_providers_test.dart` asserting that
  `appDatabaseProvider` opens a database and that disposing the container closes
  it. Verify: `bash tool/verify.sh` (the **full** gate, not `--fast`) passes.

  This task exists because task 1.1 changes what the coverage gate demands of that
  code. `coverage_critical.txt` contains the bare substring `/data/` and
  `check_coverage.dart` matches with `contains`, so `lib/data/app_providers.dart`
  falls under the **85%** threshold — while `appDatabaseProvider`'s body currently
  has zero hits, because every widget test overrides
  `transactionRepositoryProvider` wholesale. Measured from the committed
  `lcov.info`: 8 lines, 3 hit, **37.5%**. `--fast` skips coverage, so this fails
  only at the full gate; run the full one here.
- [ ] 1.3 Add migration `v2` creating `settings(key TEXT PRIMARY KEY, value TEXT
  NOT NULL)`. Verify: `test/data/migrations_test.dart` gains a case that writes
  transaction rows under v1, reopens the same file declaring v2, and asserts every
  v1 row is present and unchanged, the new table exists and is empty, and the
  stored version advanced.
- [ ] 1.4 Add the populated-database failure case to
  `test/data/database_test.dart`: rows written under v1, a v2 migration that
  throws, and assertions that a storage failure is reported, the version did not
  advance, and the v1 rows are still readable. Verify: that test fails if the
  runner is changed to advance the version before the migration completes.
- [ ] 1.5 Implement `lib/data/preferences/preferences_store.dart`: a declared
  `PreferenceKey` enum, typed read/write returning `Result`, absence reported
  distinguishably, booleans stored as the literal `true`/`false` and any other
  text reported as a storage failure naming the key. Verify:
  `test/data/preferences_store_test.dart` covers write/read, overwrite leaving one
  row, last-write-wins, durability across close and reopen, absent key with and
  without a caller fallback, each malformed boolean form (`1`, `TRUE`, `yes`,
  empty), a failing read, a failing write, and that no two declared keys share a
  stored name.

## 2. Home domain

- [ ] 2.1 Implement `lib/features/home/domain/home_period.dart` —
  `HomePeriod.currentMonth(Clock)`, an arbitrary-range constructor, and
  `lastDayInclusive`. Verify:
  `test/features/home/domain/home_period_test.dart` asserts the boundary instants
  themselves (not the expression that produced them), that December's period ends
  in January of the next year, that a month containing a DST transition spans
  exactly that month with no hour gained or lost, that bounds are UTC, and that
  `lastDayInclusive` is the last **local** day — asserted in a zone ahead of UTC,
  where computing the day from the UTC end instant yields the previous day and
  therefore fails. The gate pins `TZ=Asia/Ho_Chi_Minh` and
  `tool/check_timezone.dart` enforces it, so that zone is available; do not write
  the assertion in a way that would also pass in UTC. "Falls inside the period" is not a sufficient assertion: the
  wrong answer is also inside the period.
- [ ] 2.2 Implement `recent_entry.dart` — id, display title, `Money` amount,
  `TransactionDirection`, `SpendCategory`, occurrence instant, all shared types.
  Verify: `dart run tool/check_architecture.dart` passes and the file compiles —
  that pair *is* the signal. There is deliberately no runtime test inspecting
  field types: `dart:mirrors` is unavailable in Flutter tests, so such a test
  would assert a hand-written list against itself.
- [ ] 2.3 Implement `home_snapshot.dart` with `safeToSpend` derived and floored at
  zero, and `recentLimit`. Verify:
  `test/features/home/domain/home_snapshot_test.dart` covers income greater than,
  equal to and less than expenses; asserts safe-to-spend is never negative;
  asserts balance and period net can differ in sign; and covers the empty snapshot.
  The currency guard is **not** here — the assembler checks currencies before
  constructing a snapshot, so the snapshot's inputs are same-currency by
  construction and its constructor stays ordinary. Assert that invariant with a
  comment, not a guard.

## 3. Assembling the snapshot

- [ ] 3.1 Implement the `Transaction` → `RecentEntry` mapper in `lib/app`,
  reading `displayTitle` rather than reimplementing the note fallback. Verify:
  `test/app/recent_entry_mapper_test.dart` asserts every field round-trips, that a
  transaction with no note maps to its category label, and that the mapper
  contains no branching beyond that fallback.
- [ ] 3.2 Implement the assembling provider in `lib/app`: balance from a summary
  bounded at now, period figures from a summary bounded to the month, and the
  recent list limited and unbounded by range. Verify:
  `test/app/home_assembler_test.dart` asserts balance excludes a **strictly**
  future-dated transaction, that it **includes** one occurring at exactly now —
  the instant the add form produces under a fixed clock, and the case a naive
  exclusive `end: now` bound would silently drop — that balance and period net can differ in sign, that a backdated
  transaction lands in its own month, that exactly `recentLimit` entries are
  returned when more exist and they are the most recent by occurrence, that a
  transaction older than the period still appears in the list, that any one
  failing read yields a storage failure with no partial snapshot, and that a
  summary in an unexpected currency is refused before any arithmetic.

## 4. Home presentation

- [ ] 4.1 Implement the snapshot half of the controller: load, error state, retry.
  Verify: `test/features/home/presentation/home_controller_test.dart` covers first
  run, a storage failure becoming an error state with no zero-valued snapshot,
  retry recovering, retry failing again, and that a validation failure from query
  construction is unreachable.
- [ ] 4.2 Implement the mask half of the controller: read the preference on load,
  toggle and persist, absent means revealed, a failed read means revealed without
  an error state, a failed write follows the user's action for the session and
  surfaces the failure, **and the store itself being unconstructible** — an
  unopenable database — still renders with figures shown, with the error state (if
  any) coming from the snapshot read rather than from the preference. Verify: the
  same test file, in its own group. Note the last case cannot be produced by
  substituting a working store, so it needs the store's construction to fail, not
  its read.
- [ ] 4.3 Implement `HomeScreen` composing `BalanceCard` and the recent list, with
  distinct empty and error states and a retry action. Verify:
  `test/features/home/presentation/home_screen_test.dart` asserts that masked
  renders no digit belonging to any monetary amount anywhere in the tree while
  category names and titles remain, that empty and error render differently and
  only the error offers retry, that no zero-valued hero card appears on failure,
  that fewer than `recentLimit` transactions all appear, and that both
  `BalanceCard` variants are used. `dart run tool/check_design_tokens.dart` must
  pass — this is the first new screen layout since that gate became load-bearing.

## 5. Wiring and close-out

- [ ] 5.1 Replace Home's placeholder route with `HomeScreen` and override the
  assembling provider in the composition root. Verify:
  `test/app/router_test.dart` asserts `/` renders `HomeScreen` with the Home tab
  active, and that the existing router assertions still pass.
- [ ] 5.2 Implement refresh-on-record: Home reloads when the add sheet closes.
  Verify: `test/app/router_test.dart` asserts that recording a transaction from the
  add action while on Home updates both the figures and the recent list without
  further user action, and that a failed record leaves Home unchanged. Its own
  task because it is a whole requirement with a decided mechanism
  (`design.md` D11), not a wiring detail.
- [ ] 5.3 Update the docs: `docs/design-system/figma-map.md` gains the Home
  composition and `recentLimit` as designed-not-transcribed entries, and
  `docs/ai-workflow/evidence-log.md` gains this change's section. Verify: the map
  lists every component Home uses, and the evidence log's checkpoint rows match
  `git log`.
- [ ] 5.4 Run the full gate. Verify:
  `bash tool/verify.sh --change home-overview` passes with all seven gates green.
- [ ] 5.5 Verify on a simulator: record a transaction, see it on Home with correct
  figures, hide the amounts, relaunch, confirm they are still hidden. Commit the
  screenshot. Verify: the screenshot shows the figures matching the recorded
  amounts, and the reply states whether `recentLimit = 5` was the right guess
  against it — if it was not, that is a spec change, not a silent constant edit,
  so stop and reopen task 2.3 rather than editing the constant.
