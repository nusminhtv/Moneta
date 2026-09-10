import 'package:moneta/core/result.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

/// Records that a demo ledger has been seeded **completely**.
///
/// "Does this ledger have any transactions?" is a different question, and the
/// wrong one: a seed that fails after its first record leaves transactions
/// behind, so a row-count check would never retry it and would present a
/// ledger with holes in it as complete.
///
/// It lives in the demo database's own `settings` table, not behind a
/// `PreferenceKey`. Preferences are control-scoped and shared, so a preference
/// would claim the *real* ledger was seeded the moment demo mode was switched
/// off. This marker describes the file it is in, which is exactly why it
/// belongs in that file — and it is the one row the demo database's `settings`
/// table is allowed to hold.
class DemoSeedMarker {
  /// Creates a marker over [db], which must be the demo ledger's connection.
  const DemoSeedMarker(this.db);

  /// The demo ledger's connection.
  final DatabaseExecutor db;

  /// Row key. Deliberately not a `PreferenceKey`: this is ledger metadata, and
  /// the typed preference accessor must not be able to reach it.
  static const String key = 'demo_seed_complete';

  /// The only value ever written.
  static const String value = 'complete';

  /// Whether this ledger has been seeded in full.
  Future<Result<bool>> isSeeded() async {
    try {
      final rows = await db.query(
        PreferencesStore.table,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return const Ok(false);
      return Ok(rows.first['value'] == value);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not read the seed marker', cause: error),
      );
    }
  }

  /// Records that this ledger has been seeded in full.
  ///
  /// Called only after every record has landed. Calling it earlier is the
  /// defect this class exists to prevent.
  Future<Result<void>> markSeeded() async {
    try {
      await db.insert(PreferencesStore.table, {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not record the seed marker', cause: error),
      );
    }
  }

  /// Clears the marker, so the next activation seeds again.
  ///
  /// Reset deletes the whole file, so this exists for the case where the file
  /// survives and its contents should not be trusted.
  Future<Result<void>> clear() async {
    try {
      await db.delete(
        PreferencesStore.table,
        where: 'key = ?',
        whereArgs: [key],
      );
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not clear the seed marker', cause: error),
      );
    }
  }
}
