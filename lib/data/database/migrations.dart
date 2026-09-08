import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

/// One forward schema step.
///
/// Migrations are append-only. Editing an existing migration in place changes
/// the schema a *fresh* install receives while leaving every existing device
/// untouched — the two then drift apart silently. `migrations_test.dart` asserts
/// a fresh database ends up identical to one upgraded step by step, which is
/// what catches that mistake.
@immutable
final class Migration {
  /// Creates a migration.
  const Migration({required this.version, required this.apply});

  /// The schema version this migration produces. Must be exactly one more than
  /// the previous migration's version.
  final int version;

  /// Applies the step. Runs inside a transaction.
  final Future<void> Function(DatabaseExecutor db) apply;
}

/// The schema version the application expects.
const int schemaVersion = 3;

/// Every migration, in ascending order.
final List<Migration> migrations = [
  Migration(
    version: 1,
    apply: (db) async {
      // amount_minor is a POSITIVE MAGNITUDE and never carries a sign; the sign
      // lives in `direction`. A signed amount would let the two disagree, and
      // every read would then have to decide which field wins.
      await db.execute('''
CREATE TABLE transactions (
  id            TEXT    NOT NULL PRIMARY KEY,
  amount_minor  INTEGER NOT NULL,
  currency      TEXT    NOT NULL,
  direction     TEXT    NOT NULL,
  category      TEXT    NOT NULL,
  occurred_at   INTEGER NOT NULL,
  note          TEXT,
  created_at    INTEGER NOT NULL
)''');
      await db.execute(
        'CREATE INDEX idx_transactions_occurred_at '
        'ON transactions (occurred_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions (category)',
      );
    },
  ),
  Migration(
    version: 2,
    apply: (db) async {
      // Small durable values that belong to no single feature: a display
      // preference, whether first-run has happened. Values are TEXT and parsed
      // by a typed accessor, so a malformed value is a storage failure rather
      // than a silent default.
      await db.execute('''
CREATE TABLE settings (
  key   TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
)''');
    },
  ),
  Migration(
    version: 3,
    apply: (db) async {
      // limit_minor is the limit the user set. Spend is NOT stored: it is
      // summed from `transactions` on every read, so a budget and the
      // transactions under it cannot drift apart when one is edited or deleted
      // by anything but the path that would have maintained a cached total.
      //
      // alert_threshold is a ratio, not an amount, and it is per budget:
      // annotation 04.04 makes "Alert me at 80%" a setting, and says the
      // component's warning colour is data-driven rather than hardcoded.
      await db.execute('''
CREATE TABLE budgets (
  id               TEXT    NOT NULL PRIMARY KEY,
  category         TEXT    NOT NULL,
  limit_minor      INTEGER NOT NULL,
  currency         TEXT    NOT NULL,
  period           TEXT    NOT NULL,
  starts_on        INTEGER NOT NULL,
  rolls_over       INTEGER NOT NULL,
  alert_threshold  REAL    NOT NULL,
  created_at       INTEGER NOT NULL
)''');
      // Two budgets over one category and period would split the same spend
      // between them, and neither total would mean anything. Enforced in the
      // schema as well as in the repository: the repository's check is a race
      // between two writes, the index is not.
      await db.execute(
        'CREATE UNIQUE INDEX idx_budgets_category_period '
        'ON budgets (category, period)',
      );
    },
  ),
];

/// Applies every migration above [from] up to and including [to].
///
/// The caller is responsible for running this inside a transaction and for
/// recording the resulting version.
Future<void> runMigrations(
  DatabaseExecutor db, {
  required int from,
  required int to,
  List<Migration>? using,
}) async {
  final set = using ?? migrations;
  for (final migration in set.where(
    (m) => m.version > from && m.version <= to,
  )) {
    await migration.apply(db);
  }
}

/// Thrown when the migration set itself is malformed.
final class MigrationSetError extends StateError {
  /// Creates the error.
  MigrationSetError(super.message);
}

/// Checks that [set] covers 1..[target] exactly once, in order.
///
/// Called on every open rather than only in tests: a malformed set is a
/// programming error that must surface immediately, not on the one device that
/// happens to be two versions behind.
void assertMigrationSetIsWellFormed(List<Migration> set, int target) {
  final versions = set.map((m) => m.version).toList();
  final expected = [for (var v = 1; v <= target; v++) v];
  if (versions.length != expected.length ||
      !versions.asMap().entries.every((e) => e.value == expected[e.key])) {
    throw MigrationSetError(
      'Migrations must be contiguous 1..$target in ascending order, '
      'got $versions',
    );
  }
}
