import 'package:moneta/core/result.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

/// Durable key/value storage for small values that belong to no single feature.
///
/// Booleans are stored as the literal text `true` or `false` and **nothing else
/// is accepted**. A value that does not parse is a storage failure, not `false`:
/// a preference that quietly becomes its default when the data is corrupt is how
/// a bug becomes invisible.
final class PreferencesStore {
  /// Creates a store over [db].
  const PreferencesStore(this.db);

  /// The open connection.
  final DatabaseExecutor db;

  /// Table name, created by migration v2.
  static const String table = 'settings';

  /// The only two accepted stored forms of a boolean.
  static const String trueText = 'true';

  /// See [trueText].
  static const String falseText = 'false';

  /// Reads [key] as a boolean.
  ///
  /// Returns `Ok(null)` when nothing is stored — absence is reported distinctly
  /// from a stored value, because "never chose" and "chose the default" are
  /// different facts.
  Future<Result<bool?>> readBool(PreferenceKey key) async {
    try {
      final rows = await db.query(
        table,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key.storedName],
        limit: 1,
      );
      if (rows.isEmpty) return const Ok(null);

      final raw = rows.single['value'] as String?;
      return switch (raw) {
        trueText => const Ok(true),
        falseText => const Ok(false),
        _ => Err(
          AppFailure.storage(
            'Preference "${key.storedName}" holds "$raw", which is neither '
            '"$trueText" nor "$falseText"',
          ),
        ),
      };
    } on Object catch (error) {
      return Err(
        AppFailure.storage(
          'Could not read preference "${key.storedName}"',
          cause: error,
        ),
      );
    }
  }

  /// Reads [key] as a boolean, falling back to [orElse] when nothing is stored.
  ///
  /// A failure is still a failure — this only collapses *absence*.
  Future<Result<bool>> readBoolOr(
    PreferenceKey key, {
    required bool orElse,
  }) async {
    final result = await readBool(key);
    return result.when(
      ok: (value) => Ok(value ?? orElse),
      err: Err.new,
    );
  }

  /// Writes [value] for [key], replacing anything already there.
  Future<Result<void>> writeBool(
    PreferenceKey key, {
    required bool value,
  }) async {
    try {
      await db.insert(
        table,
        {'key': key.storedName, 'value': value ? trueText : falseText},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage(
          'Could not save preference "${key.storedName}"',
          cause: error,
        ),
      );
    }
  }
}
