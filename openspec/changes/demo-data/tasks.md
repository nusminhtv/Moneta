## 1. The Control / Active Database Split

- [ ] 1.1 `lib/data/app_providers.dart`: split `appDatabaseProvider` into
  `controlDatabaseProvider` (always `moneta.db`) and `activeDatabaseProvider`
  (the file the demo setting selects), per design D2. When demo mode is off both
  resolve to one connection rather than opening the file twice. Closing on
  dispose stays. Every current watcher moves to `activeDatabaseProvider`.
  Verify: `test/data/app_providers_test.dart` asserts that with demo off the two
  providers yield the same connection; that with demo on they differ; that
  switching closes the connection it replaces; and that a write after the switch
  lands in the new file while the old file's row count is unchanged.
  `bash tool/verify.sh --change demo-data` passes.
- [ ] 1.2 `PreferenceKey` gains `demoMode`, and `preferencesStoreProvider` is
  bound to `controlDatabaseProvider` — every preference is control-scoped (D2).
  Verify: `test/data/preferences/preferences_store_test.dart` asserts a
  preference written before a swap reads back unchanged after it; that
  completing the introduction is not undone by turning demo mode on; and that
  the demo database's `settings` table is empty after use.
- [ ] 1.3 Prove the trap this change exists to avoid: a test that fails if the
  demo flag is ever read from the active database.
  Verify: turning demo mode on and reading the flag back returns `true`, and a
  mutation binding the store to `activeDatabaseProvider` must fail it — the
  toggle undoing itself is the defect, so it needs a test that catches it.

## 2. The Dataset Generator

- [ ] 2.1 `lib/app/demo/demo_dataset.dart`: the pure generator — a function from
  a `Clock` to transactions and budgets, with its own fixed-seed
  linear-congruential sequence rather than `dart:math`'s `Random` (D4), and no
  I/O of any kind (D5).
  Verify: `test/app/demo/demo_dataset_test.dart` asserts two runs at one fixed
  clock are identical field for field; that the span is the fifteen whole months
  up to the clock's month with transactions in every one; and that a clock a
  month later produces the same *relative* span.
- [ ] 2.2 Coverage of what the screens need: every spend category present with
  unequal totals, both directions of money with income on a repeating cycle,
  more than eight categories in the current month so the donut's fold is
  exercised, and budgets of all three periods with one over, one near-limit and
  one on track.
  Verify: one test per spec scenario, each asserting the property rather than a
  transcribed count — a fixture asserting "1,203 transactions" would fail on
  every tuning of the weight table and prove nothing.
- [ ] 2.3 Boundary correctness of generated values: whole positive minor units
  in the wallet currency, every `DateTime` in UTC, nothing dated in the future,
  no duplicate identifiers.
  Verify: each asserted over the whole dataset; the no-future-dates test uses a
  clock late in a month so an off-by-one day is caught rather than absorbed.
- [ ] 2.4 Record in `design.md`'s D9 the weight table as **invented, not
  transcribed**, and state that its numbers may be tuned freely because no test
  depends on them.
  Verify: the tests from 2.2 still pass after changing a weight, which is the
  claim being made.

## 3. Seeding Through The Repositories

- [ ] 3.1 `lib/app/demo/demo_seeder.dart`: writes the generated dataset via
  `TransactionRepository.add` and `BudgetRepository.add` (D3), reporting the
  first failure rather than continuing.
  Verify: `test/app/demo/demo_seeder_test.dart` seeds an in-memory database and
  asserts the repositories now return the dataset; that a repository failure
  stops seeding and is surfaced; and that nothing is written by any route other
  than a repository.
- [ ] 3.2 Seed once, on first activation only (D7): seeding runs when demo mode
  is turned on and the demo database holds no transactions.
  Verify: turning demo mode on twice seeds once; a transaction added in demo
  mode is still present after the providers are rebuilt, which is the defect
  this decision exists to prevent.
- [ ] 3.3 Measure the seed and record the number.
  Verify: the timing appears in `docs/ai-workflow/evidence-log.md`. If it
  exceeds two seconds, wrap the seed in one database transaction — still through
  the repositories — and record both numbers. Do not optimise before measuring.

## 4. The Toggle And Reset

- [ ] 4.1 `lib/app/demo/demo_mode_controller.dart`: reads and writes the
  `demoMode` preference, seeds on first activation, and rebuilds the provider
  graph onto the other database.
  Verify: `test/app/demo/demo_mode_controller_test.dart` asserts the flag
  persists; that absence reads as off and is distinguishable from a stored
  `false`; and that a storage failure surfaces rather than silently reading as
  off.
- [ ] 4.2 Reset: close the connection, delete `moneta_demo.db`, reopen through
  the shared migration set and reseed (D6).
  Verify: reset after adding and deleting records returns the demo database to
  exactly the seeded dataset; the reopened schema equals the real database's;
  and reset is unreachable while demo mode is off.
- [ ] 4.3 The real database has no destructive path.
  Verify: a source-level check that no delete-the-file or drop-the-table call
  can be reached with the real path, guarded by a counterfeit so the check
  cannot rot into one that always passes — the technique
  `donut_chart_test.dart` uses for the donut's absent legend parameter.

## 5. Making Demo Mode Visible

- [ ] 5.1 A `MonetaBanner` with `BannerTone.info` on the application's main
  surfaces while demo mode is active (D8). `MonetaBanner` has no dismiss
  affordance, so nothing needs suppressing — if a later change adds one, this
  use must opt out.
  Verify: the banner is present on the main surfaces with demo mode on and
  absent with it off; a test asserts the absence too, since a banner that is
  always there is as wrong as one that never is.
- [ ] 5.2 `docs/design-system/figma-map.md`: record that the demo indication
  reuses `42:329` unchanged, and that `MonetaBanner` having no dismiss is a
  property this use depends on.
  Verify: the entry names the node and the dependency.

## 6. The Provisional Settings Surface

- [ ] 6.1 `lib/features/settings/presentation/demo_settings_screen.dart`: the
  toggle and, in demo mode, reset. Token-compliant and reachable from Home.
  **Explicitly provisional** — not an implementation of `08.xx`, whose Figma
  page has never been read.
  Verify: `test/features/settings/demo_settings_screen_test.dart` asserts the
  toggle reflects and changes the stored setting; that reset appears only in
  demo mode; that a destructive action asks before acting; and that the screen
  states it is provisional so a reviewer does not compare it to Figma.
- [ ] 6.2 Route and entry point in `lib/app/router.dart`, reachable from Home
  without displacing anything Figma authors there.
  Verify: `test/app/router_test.dart` reaches the screen and back; the Home
  tests that assert its app-bar contents still pass unchanged, or their
  expectations are updated deliberately and the change is called out.
- [ ] 6.3 Record the provisional surface in `figma-map.md` as unauthored, with
  the note that `profile-feature` absorbs both controls onto the real Settings
  screen.
  Verify: the entry says which nodes were *not* consulted and why.

## 7. Close-Out

- [ ] 7.1 `docs/ai-workflow/evidence-log.md`: this change's verify runs, commits
  and the seed timing from 3.3.
  Verify: the entries match `git log`.
- [ ] 7.2 Run the full gate and confirm the untouched-real-data claim
  end-to-end.
  Verify: `bash tool/verify.sh --change demo-data` passes, and a test seeds a
  real database, turns demo mode on, seeds and mutates the demo database, turns
  it off, and asserts the real database is unchanged row for row — the
  capability's first requirement, tested as a whole rather than per unit.
