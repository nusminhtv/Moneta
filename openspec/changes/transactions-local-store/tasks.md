## 1. Database foundation

- [x] 1.1 Add `IdGenerator` to `lib/core` (`SystemIdGenerator`, `FixedIdGenerator`),
  beside `Clock` and for the same reason. Verify:
  `test/core/id_generator_test.dart` asserts ids are unique across 10k draws,
  sort roughly by creation time, and that `FixedIdGenerator` is deterministic;
  `dart run tool/check_architecture.dart` passes.
- [x] 1.2 Implement `lib/data/database/migrations.dart` — a `Migration` record
  and the ordered list, with `v1` creating the `transactions` table and its two
  indexes exactly as in `design.md` D1. Verify:
  `test/data/migrations_test.dart` asserts the set is contiguous 1..schemaVersion
  with no duplicates, and that a fresh database ends up with the **same schema**
  as one upgraded step by step.
- [x] 1.3 Implement `lib/data/database/app_database.dart` — lazy single
  connection, migration runner in a transaction, refusal to open when the stored
  version exceeds the declared one, and deterministic close. Verify:
  `test/data/database_test.dart` asserts durability across a close/reopen,
  that concurrent first access opens once, that a downgrade yields a storage
  failure with no data loss, and that a throwing migration leaves the stored
  version behind.

## 2. Transactions domain

- [x] 2.1 Implement `lib/features/transactions/domain/transaction.dart`:
  the entity, `TransactionDirection`, and construction that rejects a
  non-positive amount and an over-length note as validation failures. Verify:
  `test/features/transactions/domain/transaction_test.dart` covers zero,
  negative, very large amounts, note absent vs empty vs over-length, and that
  the signed value is derived from direction rather than stored.
- [x] 2.2 Implement `TransactionQuery` (category set, date range) and the
  `TransactionRepository` interface returning `Result<T>`. Verify:
  `test/features/transactions/domain/transaction_query_test.dart` asserts an
  inverted range is rejected, an empty filter matches everything, and that the
  range is inclusive-start/exclusive-end by construction.

## 3. Transactions data layer

- [x] 3.1 Implement `TransactionDao` — insert, query with filters, delete,
  and the aggregate summary — plus row↔entity mapping. Verify:
  `test/features/transactions/data/transaction_dao_test.dart` runs against
  `sqflite_common_ffi` and covers round-trip fidelity, exactness at a trillion
  minor units, UTC in/UTC out across zones, newest-first with stable ties,
  the empty database, both filters, the exact boundary instants, summary figures
  for populated and empty periods, and that the summary is an aggregate query
  rather than a row read.
- [x] 3.2 Implement `SqliteTransactionRepository` converting DAO exceptions into
  `AppFailure.storage`, validation into `AppFailure.validation`, and a missing
  delete target into `AppFailure.notFound`. Verify:
  `test/features/transactions/data/transaction_repository_test.dart` uses a
  throwing fake DAO to assert a failed read returns `Err` rather than an empty
  list, and that a failed write leaves the database unchanged.

## 4. Design system addition

- [x] 4.1 Implement `TransactionRow` per ADR 0003, taking `Money` and a
  direction. Verify: `test/design_system/molecules/transaction_row_test.dart`
  asserts the sign and colour for both directions, the category disc coming from
  the shared binding, the note falling back to the category name, one-line
  ellipsis on a long note with the amount neither displaced nor clipped, and add
  the row to `docs/design-system/figma-map.md` marked as designed-not-transcribed.

## 5. Presentation

- [x] 5.1 Implement day grouping — local calendar day, net per day, no empty
  days. Verify: `test/features/transactions/presentation/day_grouping_test.dart`
  covers a mixed-sign day, a day boundary either side of local midnight, and a
  DST transition day.
- [x] 5.2 Implement the list controller (Riverpod): load, retry, delete with an
  in-memory undo buffer and an injected clock for expiry. Verify:
  `test/features/transactions/presentation/list_controller_test.dart` asserts
  undo restores the original id and list position, that the window expires, and
  that a load failure is exposed as an error state rather than an empty list.
- [x] 5.3 Implement `TransactionsScreen` with distinct empty and error states and
  a retry action. Verify:
  `test/features/transactions/presentation/transactions_screen_test.dart`
  asserts empty and error render differently, retry recovers, and a newly added
  transaction appears without a manual refresh.
- [x] 5.4 Implement the add form with validation before any write. Verify:
  `test/features/transactions/presentation/add_transaction_test.dart` covers
  empty, zero, non-numeric and over-precision amounts, a future instant, and a
  successful record.

## 6. App wiring and close-out

- [x] 6.1 Wire the router: a real transactions route, the bottom navigation
  driving it, and the add action opening the form. Verify:
  `test/app/router_test.dart` asserts each destination reaches its route and that
  the active tab matches the current route — Figma calls a mismatch "a real
  defect, not a nitpick".
- [ ] 6.2 Run the full gate, update `docs/ai-workflow/evidence-log.md` and
  `docs/design-system/figma-map.md`, and confirm the running app stores and
  reloads a transaction. Verify:
  `bash tool/verify.sh --change transactions-local-store` passes, and a
  transaction recorded in the running app is still present after a restart.
