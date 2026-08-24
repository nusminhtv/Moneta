## Context

This is the first change that crosses every layer, so it is also the first real
test of `tool/check_architecture.dart`'s rules. The constraints that shape it:

- `features/<f>` may import `core`, `design_system`, `data` and itself. So the
  feature's `domain` can hold the repository *interface*, and its `data` can hold
  the implementation, but neither may reach into another feature.
- `lib/core` is Flutter-free, which is why `SpendCategory` already lives there
  and why anything the domain needs from the platform arrives as an injected
  interface.
- `Money` is integer minor units, so the schema needs an integer column and no
  decimal handling anywhere.
- Coverage is enforced at ≥85% on `*/domain/` and `*/data/`. This change is the
  first code those patterns match, so the thresholds become real here.

## Goals / Non-goals

**Goals**: durable storage with an explicit migration path; a repository the
presentation layer can use without knowing SQL exists; a date-grouped list with
honest empty and error states; an add form that validates before writing; delete
with undo; a period summary computed in SQL.

**Non-goals**: editing, accounts, budgets, multi-currency, sync, export, search,
attachments, recurring transactions, Insights and Profile screens.

## Decisions

### D1 — One table, integers and text only

```sql
CREATE TABLE transactions (
  id            TEXT    NOT NULL PRIMARY KEY,
  amount_minor  INTEGER NOT NULL,           -- positive magnitude
  currency      TEXT    NOT NULL,           -- ISO-4217
  direction     TEXT    NOT NULL,           -- 'income' | 'expense'
  category      TEXT    NOT NULL,           -- SpendCategory.name
  occurred_at   INTEGER NOT NULL,           -- epoch milliseconds, UTC
  note          TEXT,                       -- nullable
  created_at    INTEGER NOT NULL
);
CREATE INDEX idx_transactions_occurred_at ON transactions (occurred_at DESC);
CREATE INDEX idx_transactions_category    ON transactions (category);
```

**Options for the amount.** (a) `INTEGER` minor units; (b) `REAL`; (c) `TEXT`
decimal. (b) is disqualified outright — SQLite `REAL` is IEEE-754 and would
reintroduce the drift `Money` exists to prevent. (c) is exact but unsummable in
SQL, which kills D4. **(a)**, and the column is named `amount_minor` so nobody
reads it as a major unit.

**Options for the instant.** (a) epoch milliseconds `INTEGER`; (b) ISO-8601
`TEXT`. (b) sorts correctly as text and is readable in a DB browser, but invites
zone-suffix inconsistency and is slower to compare. **(a)**, always UTC,
converted to local only at the presentation boundary.

**Direction and category are stored as their enum names**, not ordinals.
An ordinal silently remaps every stored row if someone reorders the enum;
`SpendCategory.tryParse` already returns null for an unknown name, so a row
written by a newer version fails loudly instead of becoming the wrong category.

**Sign lives in `direction`, not in `amount_minor`.** A signed amount lets two
rows disagree — direction `income` with a negative amount — and every read then
has to decide which field wins. A positive magnitude plus a direction has no such
state. `amount_minor > 0` is enforced in the domain and asserted by tests.

### D2 — Migrations are a list, and the list is verified

`AppDatabase` declares `schemaVersion` and a `List<Migration>`, each with a
`version` and an `apply`. The runner applies every migration above the stored
version, in order, inside a transaction.

Two properties are asserted by tests rather than assumed: the set is
**contiguous** from 1 to `schemaVersion` with no gaps or duplicates, and a
**fresh** database ends up with the same schema as one that upgraded step by
step. That second test is the one that catches the classic bug where someone
edits migration v1 in place instead of adding v2 — existing devices then never
receive the change.

A stored version *higher* than the declared one — a downgrade — is refused rather
than "migrated down". There is no safe automatic answer, and destroying the
user's data to make the app start is the worst one.

### D3 — DAOs throw, repositories return `Result`

The DAO speaks SQL and throws whatever `sqflite` throws. The repository catches
at that boundary and converts to `Err(AppFailure.storage(...))`, keeping the
`try`/`catch` in exactly one layer instead of smeared through the feature.

The alternative — `Result` all the way down into the DAO — was rejected because
it makes each DAO method carry error plumbing that the repository immediately
re-wraps, and it tempts callers to ignore a failed row read mid-loop.

Validation failures are produced *before* touching SQL, so a `validation` failure
never implies a write was attempted.

### D4 — The summary is one aggregate query

```sql
SELECT direction, SUM(amount_minor) AS total
FROM transactions
WHERE occurred_at >= ? AND occurred_at < ?
GROUP BY direction;
```

Loading rows and folding them in Dart is simpler and is what a first version
usually does — and it turns the home screen into an O(n) read that gets slower
every month a person uses the app. The aggregate is barely more code and the
index on `occurred_at` makes it a range scan.

The test asserts the totals, and separately asserts that the summary path issues
an aggregate rather than a row read, so the shortcut cannot creep back in.

### D5 — Identity is injected, not imported

Transactions need a unique id. **Options:** (a) the `uuid` package; (b) SQLite
`rowid`; (c) a small injected `IdGenerator` in `lib/core`.

(b) is rejected because an autoincrement id is only unique within this database,
which makes any future export or sync a rewrite. (a) is one more dependency for
sixteen bytes of randomness, and — more importantly — a non-deterministic one:
every test that compares a stored transaction has to work around a random id.

**(c).** `IdGenerator` sits beside `Clock` in `lib/core`: `SystemIdGenerator`
composes a UTC timestamp with a random suffix, giving ids that are unique and
sort roughly by creation; `FixedIdGenerator` makes tests deterministic. It is the
same seam as `Clock` and for the same reason.

### D6 — Undo is a buffer in the controller, not a `deleted_at` column

**Options:** (a) soft delete with a `deleted_at` column and a filter on every
read; (b) hard delete, with the removed entity held in the controller for the
undo window and re-inserted on undo.

(a) means every query grows a `WHERE deleted_at IS NULL`, and forgetting it once
resurrects deleted transactions in some corner of the app. It also keeps data the
user asked to remove.

**(b).** The delete is real immediately; the controller keeps the entity in
memory for the undo window and re-inserts it with its **original id** on undo, so
undo restores the same record rather than a copy. If the app is killed during the
window, the deletion stands — which is the correct reading of "the user deleted
it".

### D7 — Day grouping happens in the presentation layer

Grouping is by **local** calendar day, while storage is UTC. `GROUP BY` in SQL
would have to encode a fixed offset, which is wrong the moment the device
changes zone or crosses a DST boundary. The repository returns an ordered list;
the presentation layer groups it using the device's zone.

This is only correct because the list is already bounded by a period filter. If
an unbounded list ever needs grouping, the answer is pagination, not SQL
grouping.

### D8 — `TransactionRow` is designed, not transcribed

See [ADR 0003](../../../docs/adr/0003-transaction-row-layout.md). Figma has no
transaction row and no screen frames, so this component is a decision rather
than a transcription, and is labelled as such in `figma-map.md`.

## Risks / trade-offs

- **`sqflite_common_ffi` is not `sqflite`.** Tests run against SQLite through FFI
  on the VM; the app runs against the platform plugin. They are the same SQLite
  but not the same binding. Mitigation: the DAO uses no platform-specific SQL,
  and the schema test asserts the resulting schema rather than trusting the
  binding.
- **Undo lost on process death** is a deliberate trade (D6), not an oversight.
- **No accounts yet** means `Transaction` has no account column. Adding one later
  is a migration with a default — cheap, and explicitly the reason the migration
  runner exists before it is needed.
- **Local-day grouping across DST.** A day with a DST transition is 23 or 25
  hours. Using `DateTime` local arithmetic rather than adding 24-hour durations
  handles this; a test covers a DST boundary explicitly.

## Verification plan

| Spec requirement | Verified by |
| --- | --- |
| Versioned, migrated forward | `test/data/migrations_test.dart` — fresh-vs-upgraded schema equality, contiguity, ordering |
| Downgrade refused | `migrations_test` — stored version above declared version yields a storage failure and no data loss |
| Migration failure does not advance the version | `migrations_test` — a throwing migration leaves the stored version behind |
| Failures reported, never swallowed | `test/features/transactions/data/repository_test.dart` with a throwing DAO |
| Durability across restarts | `test/data/database_test.dart` — write, close, reopen against the same file |
| Single connection | `database_test` — concurrent first access opens once |
| Fields round-trip; amounts exact | `test/features/transactions/data/transaction_dao_test.dart` |
| Positive magnitude; zero/negative rejected | `test/features/transactions/domain/transaction_test.dart` |
| UTC in, UTC out | `transaction_dao_test` — write in one zone, read in another |
| Note optional and bounded | `transaction_test` |
| Distinct ids for identical values | `transaction_dao_test` with `FixedIdGenerator` sequences |
| Newest first, stable ties | `transaction_dao_test` |
| Empty database is an empty list | `transaction_dao_test` |
| Category and range filters; inclusive/exclusive bounds | `transaction_dao_test` — boundary instants asserted directly |
| Inverted range is a validation failure | `repository_test` |
| Summary figures; empty period; large totals | `transaction_dao_test` |
| Summary uses an aggregate | `transaction_dao_test` — asserts the query shape, not just the numbers |
| Delete; delete-missing is not-found | `repository_test` |
| Undo restores the same id and position | `test/features/transactions/presentation/list_controller_test.dart` |
| Undo expires | `list_controller_test` with an injected clock |
| Day grouping, day net, DST boundary | `test/features/transactions/presentation/day_grouping_test.dart` |
| Empty vs error state distinguishable | `test/features/transactions/presentation/transactions_screen_test.dart` |
| Retry after failure | `transactions_screen_test` |
| Add-form validation cases | `test/features/transactions/presentation/add_transaction_test.dart` |
| New transaction visible without manual refresh | `transactions_screen_test` |
| TransactionRow behaviour and variants | `test/design_system/molecules/transaction_row_test.dart` |

Plus the standing gates.

## Open questions

- **Undo window length.** Set to 5 seconds, matching a typical snackbar. Not
  read from Figma — Figma's `Snackbar` component has no duration property.
  Flagged as a product decision, not a design transcription.
