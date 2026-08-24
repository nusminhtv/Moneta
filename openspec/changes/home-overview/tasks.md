## 1. Preferences storage

- [ ] 1.1 Add migration `v2` creating `settings(key TEXT PRIMARY KEY, value TEXT
  NOT NULL)`. Verify: `test/data/migrations_test.dart` gains a case that writes
  transaction rows under v1, reopens the file declaring v2, and asserts every v1
  row is present and unchanged **and** the new table exists and is empty — the
  first migration this project applies to populated data.
- [ ] 1.2 Implement `lib/data/preferences/preferences_store.dart`: a declared
  `PreferenceKey` enum, typed read/write returning `Result`, absence reported
  distinguishably from a stored value, and a malformed stored value reported as a
  storage failure. Verify: `test/data/preferences_store_test.dart` covers
  write/read, overwrite, durability across close and reopen, absent key with and
  without a caller fallback, a malformed boolean, a failing read and a failing
  write, and that no two declared keys share a stored name.

## 2. Home domain

- [ ] 2.1 Implement `lib/features/home/domain/home_period.dart` —
  `HomePeriod.currentMonth(Clock)` plus an arbitrary-range constructor, local
  month bounds built by `DateTime(year, month + 1, 1)` rather than duration
  arithmetic. Verify: `test/features/home/domain/home_period_test.dart` asserts
  the boundary instants directly (inclusive start, exclusive end), that December
  rolls to January of the next year, that a DST-transition month spans exactly
  that month with no hour gained or lost, and that bounds are local converted to
  UTC.
- [ ] 2.2 Implement `home_snapshot.dart` (`totalBalance`, `periodIncome`,
  `periodExpenses`, `recent`, `recentLimit`) with `safeToSpend` derived and
  floored at zero, and `home_data_source.dart` — the port returning
  `Result<HomeSnapshot>`. Verify:
  `test/features/home/domain/home_snapshot_test.dart` covers income greater than,
  equal to, and less than expenses; asserts safe-to-spend is never negative;
  asserts balance and period net can differ in sign; and covers the empty
  snapshot.

## 3. The adapter

- [ ] 3.1 Implement `lib/app/home_data_source_impl.dart`: the single
  `HomeDataSource`, composing two `summarise` calls (all-time and period) and one
  limited `list`, plus its provider. Verify:
  `test/app/home_data_source_impl_test.dart` asserts balance comes from the
  all-time read and income/expenses from the period read (a case where they
  differ), that the recent list is limited and unbounded by the period, and that
  any one failing read yields a storage failure rather than partial figures.
  `dart run tool/check_architecture.dart` must pass with no file under
  `features/home` importing another feature.

## 4. Home presentation

- [ ] 4.1 Implement the Home controller: loads the snapshot through the port,
  reads and writes the mask preference, exposes error state. A failed preference
  read must fall back to revealed without failing the load. Verify:
  `test/features/home/presentation/home_controller_test.dart` drives it entirely
  through a fake port — no database, no transactions code — and covers first run,
  a snapshot failure becoming an error state, retry recovering, retry failing
  again, a failed preference read still rendering revealed, and toggling the mask
  persisting through the store.
- [ ] 4.2 Implement `HomeScreen` composing `BalanceCard` and the recent list,
  with distinct empty and error states and a retry action. Verify:
  `test/features/home/presentation/home_screen_test.dart` asserts masked renders
  **no digit** anywhere in the tree, that empty and error states render
  differently and only the error offers retry, that no zero-valued hero card is
  shown on failure, and that a snapshot with fewer than `recentLimit`
  transactions shows all of them.

## 5. Wiring and close-out

- [ ] 5.1 Replace Home's placeholder route with `HomeScreen` and override the
  data-source provider in the composition root. Verify:
  `test/app/router_test.dart` gains a case asserting `/` renders `HomeScreen`
  with the Home tab active, and that navigating away and back preserves nothing
  it should not.
- [ ] 5.2 Run the full gate, record the recent-list length decision and the Home
  composition in `docs/design-system/figma-map.md` as designed-not-transcribed,
  update `docs/ai-workflow/evidence-log.md`, and confirm on a simulator that a
  transaction recorded in the app appears on Home, that the figures are right, and
  that hiding them survives a relaunch. Verify:
  `bash tool/verify.sh --change home-overview` passes, and a screenshot of Home
  with real data is committed. Revisit `recentLimit` against that screenshot and
  say whether 5 was the right guess.
