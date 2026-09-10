Restructured after the `spec-auditor` pass. The previous shape put the
capability's flagship guarantee — real data untouched — in the *last* task,
bundled four units into 1.1, and gave 1.3 no test file or gate. Order now runs
guarantees first, then data, then surfaces.

## 1. The Control / Active Database Split

- [x] 1.1 `lib/data/app_providers.dart`: split `appDatabaseProvider` into
  `controlDatabaseProvider` (always the real file) and `activeDatabaseProvider`
  (the file the demo flag selects), plus `demoModeProvider` in `lib/data` so a
  feature surface can read it without importing `lib/app` (D15). Both watchers
  move: `transaction_providers.dart` and `budget_providers.dart`, along with the
  re-export. Paths become providers so a test can point them at a temporary
  directory while the production bodies still run.
  Verify: `test/data/app_providers_test.dart` asserts demo-off yields the *same
  `AppDatabase` instance* as control (not merely an equal path — two handles on
  one file would each open it); demo-on yields a different one on the demo file;
  leaving demo mode closes the demo connection, observed through `openCount`;
  a switch in either direction leaves the control connection open; a write after
  the switch lands in the demo file while the real file's row is unchanged in
  both count and value; and both databases dump identical schemas.
  `bash tool/verify.sh --change demo-data` passes.
- [x] 1.2 `PreferenceKey.demoMode`, and `preferencesStoreProvider` bound to
  `controlDatabaseProvider` — every preference is control-scoped (D2).
  Verify: `test/data/preferences/preferences_store_test.dart` asserts a
  preference written before a swap reads back unchanged after it; that
  completing the introduction is not undone by turning demo mode on; and that
  the demo database's `settings` table holds no row whose key is a declared
  `PreferenceKey`.
- [x] 1.3 The toggle-undoes-itself guard, in
  `test/data/demo_flag_scope_test.dart`.
  Verify: the store is **re-resolved after** the swap, not held from before it —
  a test holding the pre-swap `PreferencesStore` reads from the still-open old
  connection and would pass even with the store bound to
  `activeDatabaseProvider`. Plus a source-level check, guarded by a counterfeit,
  that no code constructs a `PreferencesStore` over `activeDatabaseProvider` —
  the technique `donut_chart_test.dart` uses for the donut's absent parameter.
- [x] 1.4 **The flagship guarantee, tested end to end and early.**
  `test/app/demo/real_ledger_untouched_test.dart`: seed a real ledger, turn demo
  mode on, seed and then mutate the demo ledger, turn demo mode off, and assert
  the real ledger is unchanged row for row.
  Verify: it fails if the active database is pointed at the real file at any
  step. This gates the rest of the change rather than closing it.

## 2. In-Flight State Does Not Cross Ledgers

- [x] 2.1 `transaction_list_controller.dart`: pending undo and any in-flight
  write are discarded when the active ledger changes (D11).
  Verify: `test/features/transactions/presentation/undo_across_ledgers_test.dart`
  deletes a transaction in demo mode, turns demo mode off inside the five-second
  window, and asserts undo is not offered and the real ledger gains no row; the
  same in the other direction; and that undo still works when the ledger does
  *not* change, so the fix did not simply disable undo.

## 3. The Dataset Generator

- [x] 3.1 `lib/app/demo/demo_dataset.dart`: the pure generator (D5) with its own
  fixed-seed linear-congruential sequence (D4) and an **injected `IdGenerator`**
  (D4a), because the production one is `Random.secure()`. No I/O.
  Verify: `test/app/demo/demo_dataset_test.dart` asserts two runs at one fixed
  clock and one seeded id source are equal field for field including ids and
  order; and a signature check that the clock and id source are parameters.
- [x] 3.2 Span and anchoring: fifteen whole months up to the clock's month,
  transactions in every one, nothing dated after the clock.
  Verify: the no-future-dates case uses a clock late in a month, so an
  off-by-one day is caught rather than absorbed; a clock a month later yields
  the same relative span.
- [x] 3.3 Category and direction coverage: every **expense** category present
  with distinct totals, and salary on a repeating day-of-month cycle.
  Verify: asserted as properties, not as a transcribed count — a fixture
  asserting "1,203 transactions" would fail on every tuning of the weight table
  and prove nothing. The cycle test asserts the same day-of-month, not "roughly
  monthly".
- [x] 3.4 Budget states: budgets of all three periods, with one over its limit,
  one near it and one on track **when evaluated at the generating clock**.
  Verify: evaluated through `BudgetProgress` at that clock. Record in
  `design.md` that a demo ledger left unseeded for weeks drifts out of these
  states, since the dataset is anchored and seeded once — reset is the answer,
  and pretending otherwise would be a claim no test can hold.
- [x] 3.5 Raw-value boundaries: whole positive minor units in the wallet
  currency asserted on the generator's **raw values before construction**, since
  `Transaction.create` already enforces them and asserting afterwards would test
  `transaction.dart`. Plus one deliberately large amount and a larger
  fifteen-month total.
  Verify: the large row and the total both render without overflowing.

## 4. Seeding Through The Repositories

- [x] 4.1 `lib/app/demo/demo_seeder.dart`: writes via
  `TransactionRepository.add` and `BudgetRepository.add` (D3), reporting the
  first failure rather than continuing.
  Verify: `test/app/demo/demo_seeder_test.dart` seeds an in-memory database and
  asserts the repositories return the dataset; that a repository failure stops
  seeding and surfaces; and a source-level check that the seeder holds no SQL.
- [x] 4.2 The seed-completion marker in the demo database's `settings` table,
  written only after the whole dataset lands (D7).
  Verify: a completed seed is not repeated; a seed that fails after the first
  record **is** retried on the next activation — the row-count check this
  replaces would never retry it; and the marker is absent from the control
  database, so turning demo mode off does not make the real ledger look seeded.
- [x] 4.3 Measure the seed and record the number.
  Verify: the timing appears in `docs/ai-workflow/evidence-log.md`. Measure
  only — do not change anything in this task.
- [x] 4.4 **Not needed.** 4.3 measured 584ms for 1,177 records against a real
  file, against a two-second budget, so the cross-feature repository change this
  task describes is not justified. Original text kept below.

  Only if 4.3 exceeds two seconds: wrap the seed in one database
  transaction, still through the repositories.
  Verify: both timings recorded. **This needs a transaction-scoped executor
  threaded through two repository constructors — a cross-feature API change, not
  a tweak.** If 4.3 is under budget, tick this with "not needed" and the
  measurement that says so.

## 5. The Toggle, Reset, And Starting States

- [x] 5.1 `lib/app/demo/demo_mode_controller.dart`: persists the flag, seeds on
  first activation, discards in-flight state, and sets `demoModeProvider` last —
  only after the durable write succeeded (D15).
  Verify: `test/app/demo/demo_mode_controller_test.dart` asserts the flag
  persists; absence reads as off and is distinguishable from a stored `false`;
  and a storage failure surfaces rather than silently reading as off.
- [ ] 5.2 `AppDatabase.deleteFile()` returning `Result<void>` (D6a), and reset
  built on it: close, delete, reopen through the shared migration set, reseed.
  Verify: `test/data/database/app_database_test.dart` covers the delete and its
  failure branch — this file is in the ≥85% band. Reset after adding and
  deleting records returns the demo ledger to the seeded dataset; the reopened
  schema equals the real one; a delete failure reports a storage `AppFailure`
  and leaves a database the app can still open.
- [ ] 5.3 The real database has no destructive path.
  Verify: a source-level check with a counterfeit that no delete-the-file or
  drop-the-table call is reachable with the real path, and that reset is
  unreachable while demo mode is off.
- [ ] 5.4 Starting states: demo mode turned on before the real file exists; a
  demo database at an older schema version; a demo database *newer* than the
  app.
  Verify: the first creates the control database so the setting has somewhere to
  live; the second migrates rather than deleting; the third surfaces the storage
  failure and still allows leaving demo mode, because the setting lives in a
  database that opens.

## 6. Making Demo Mode Visible

- [ ] 6.1 A `MonetaBanner` with `BannerTone.info`, rendered by the route
  wrappers in `lib/app` (D13) on every route showing ledger data — Home,
  Transactions, Budgets, Budget detail. No feature widget gains a parameter.
  Verify: present on each of those routes with demo mode on and **absent** with
  it off — a banner that is always there is as wrong as one that never is.
- [ ] 6.2 `docs/design-system/figma-map.md`: record the banner deviation — Home
  already renders `_OverBudgetBanner` and the dataset is required to contain an
  over-limit budget, so demo mode stacks two banners where `52:2` authors one.
  Record that `MonetaBanner` having no dismiss is a property this use depends
  on, and correct the stale row still listing `Banner` `42:329` as not started.
  Verify: the entry names the node, the collision and the dependency.

## 7. The Provisional Settings Surface

- [ ] 7.1 `lib/features/settings/presentation/demo_settings_screen.dart` as a
  **callback-only** widget — current value in, two callbacks out, no provider
  read — because a feature may not import `lib/app` (D15). The ledger control is
  a two-option `MonetaRadioGroup`, not a new `Toggle` atom (D12).
  Verify: `test/features/settings/demo_settings_screen_test.dart` asserts each
  scenario of "The demo controls are reachable and say what they are": exactly
  one ledger reads selected and it is the active one; choosing the other reports
  it; reset asks before acting and declining changes nothing; and the surface
  states it is provisional.
- [ ] 7.2 Route and wiring in `lib/app`, reachable from Home.
  Verify: `test/app/router_test.dart` reaches the screen and back, and the
  controller is wired from `lib/app` so the architecture gate stays green. If a
  Home test's expectations change, the diff says which and why.
- [ ] 7.3 Record the provisional surface in `figma-map.md` as unauthored, naming
  the nodes deliberately **not** consulted, and that `profile-feature` absorbs
  both controls.
  Verify: the entry names them and says why.

## 8. Close-Out

- [ ] 8.1 `docs/ai-workflow/evidence-log.md`: verify runs, commits, the seed
  timing from 4.3, and the `spec-auditor` findings this change acted on.
  Verify: the entries match `git log`.
- [ ] 8.2 Amend `docs/adr/0001-local-persistence-layer.md`: it assumed one
  database. Record the control/data split as an addition that does not overturn
  its reasoning.
  Verify: the ADR names this change and the two files.
- [ ] 8.3 Run the full gate.
  Verify: `bash tool/verify.sh --change demo-data` passes and its evidence file
  is cited in the final commit.
