import 'dart:async';

import 'package:moneta/core/result.dart';
import 'package:moneta/data/database/migrations.dart';
import 'package:sqflite/sqflite.dart';

/// Opens and owns the application's SQLite connection.
///
/// One connection per process, opened lazily. Every failure mode is reported as
/// an [AppFailure]; nothing here throws past its own boundary, because a
/// storage error that escapes as an exception ends up caught by something that
/// treats it as "no data".
final class AppDatabase {
  /// Creates a database handle.
  ///
  /// [path] is the file location. [factory] is the sqflite factory, which tests
  /// replace with the FFI factory to run on the Dart VM.
  AppDatabase({
    required this.path,
    required this.factory,
    List<Migration>? migrationSet,
    int? version,
  }) : _migrations = migrationSet ?? migrations,
       _version = version ?? schemaVersion;

  /// Database file path.
  final String path;

  /// The sqflite factory used to open [path]. Tests supply the FFI factory so
  /// the data layer runs on the Dart VM without a simulator.
  final DatabaseFactory factory;
  final List<Migration> _migrations;
  final int _version;

  Database? _db;
  Future<Result<Database>>? _opening;

  /// How many times the underlying open actually ran. Used by tests to prove
  /// concurrent first access does not open twice.
  int get openCount => _openCount;
  int _openCount = 0;

  /// Returns the open connection, opening it if necessary.
  ///
  /// Concurrent callers during the first open share one future, so the work
  /// happens once.
  Future<Result<Database>> open() {
    final existing = _db;
    if (existing != null) return Future.value(Ok(existing));
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<Result<Database>> _open() async {
    // Deliberately not caught: a malformed migration set is a programming
    // error, not a storage failure. Converting it into an AppFailure would show
    // the user "could not open the database" for a bug that should crash in
    // development and be caught by migrations_test before release.
    assertMigrationSetIsWellFormed(_migrations, _version);

    try {
      final db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _version,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            // A fresh database still walks every migration in order rather than
            // executing a snapshot of the final schema. That is what keeps a
            // fresh install and an upgraded install identical.
            await runMigrations(db, from: 0, to: version, using: _migrations);
          },
          onUpgrade: (db, from, to) async {
            await runMigrations(db, from: from, to: to, using: _migrations);
          },
          onDowngrade: (db, from, to) async {
            // There is no safe automatic answer here, and destroying the user's
            // data to make the app start is the worst one.
            throw DatabaseDowngradeError(storedVersion: from, appVersion: to);
          },
        ),
      );
      _openCount++;
      _db = db;
      return Ok(db);
    } on DatabaseDowngradeError catch (error) {
      return Err(AppFailure.storage(error.message, cause: error));
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not open the database', cause: error),
      );
    }
  }

  /// Closes the connection, if open.
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  /// Closes the connection and deletes the file.
  ///
  /// Lives here rather than in a caller because this object owns the path and
  /// the factory; a caller reconstructing the path would be a second place that
  /// has to agree about it.
  ///
  /// Deleting the file rather than emptying the tables is deliberate: the next
  /// [open] runs the whole migration set from nothing, so the result is
  /// identical to a first run. `DELETE FROM` every table needs a list of tables
  /// kept in step with the migrations by hand, and that list is exactly what
  /// drifts.
  ///
  /// Reported, never thrown: "the file could not be deleted" is a real outcome,
  /// not a programming error.
  Future<Result<void>> deleteFile() async {
    try {
      await close();
      await factory.deleteDatabase(path);
      // The next open is a fresh one, so the memoised count would otherwise
      // claim work that no longer exists.
      _openCount = 0;
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not delete the database', cause: error),
      );
    }
  }
}

/// Raised when the stored schema is newer than this build of the app.
final class DatabaseDowngradeError implements Exception {
  /// Creates the error.
  const DatabaseDowngradeError({
    required this.storedVersion,
    required this.appVersion,
  });

  /// Schema version found on disk.
  final int storedVersion;

  /// Schema version this build expects.
  final int appVersion;

  /// Human-readable description.
  String get message =>
      'Database schema v$storedVersion is newer than this app (v$appVersion). '
      'Refusing to open rather than migrating down, which would lose data.';

  @override
  String toString() => 'DatabaseDowngradeError: $message';
}
