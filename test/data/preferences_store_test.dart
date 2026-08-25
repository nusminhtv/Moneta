import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('moneta_prefs_test');
    dbPath = '${tempDir.path}/moneta.db';
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<(AppDatabase, PreferencesStore)> open() async {
    final database = AppDatabase(path: dbPath, factory: databaseFactoryFfi);
    final db = (await database.open()).valueOrNull!;
    return (database, PreferencesStore(db));
  }

  AppFailure failureOf(Result<Object?> r) =>
      r.when(ok: (v) => fail('expected a failure, got $v'), err: (f) => f);

  group('write and read', () {
    test('a written value reads back', () async {
      final (database, store) = await open();
      expect(
        (await store.writeBool(
          PreferenceKey.onboardingComplete,
          value: true,
        )).isOk,
        isTrue,
      );
      expect(
        (await store.readBool(PreferenceKey.onboardingComplete)).valueOrNull,
        isTrue,
      );
      await database.close();
    });

    test('false round-trips, distinctly from absent', () async {
      final (database, store) = await open();
      await store.writeBool(PreferenceKey.onboardingComplete, value: false);
      final read = await store.readBool(PreferenceKey.onboardingComplete);
      expect(read.isOk, isTrue);
      expect(read.valueOrNull, isFalse, reason: 'false, not null');
      await database.close();
    });

    test(
      'overwriting leaves exactly one row, and the last write wins',
      () async {
        final (database, store) = await open();
        final db = (await database.open()).valueOrNull!;

        // The last value must differ from the first, or the test cannot fail.
        // This was false -> true -> false asserting false, which ends where it
        // started: switching ConflictAlgorithm.replace to .ignore silently kept
        // the *first* write and the test named "the last write wins" passed.
        await store.writeBool(PreferenceKey.onboardingComplete, value: false);
        await store.writeBool(PreferenceKey.onboardingComplete, value: true);
        await store.writeBool(PreferenceKey.onboardingComplete, value: false);
        await store.writeBool(PreferenceKey.onboardingComplete, value: true);

        final rows = await db.query(PreferencesStore.table);
        expect(rows, hasLength(1));
        expect(
          rows.single['value'],
          'true',
          reason: 'the stored row is not the last value written',
        );
        expect(
          (await store.readBool(PreferenceKey.onboardingComplete)).valueOrNull,
          isTrue,
        );
        await database.close();
      },
    );

    test('survives close and reopen', () async {
      final (first, store) = await open();
      await store.writeBool(PreferenceKey.onboardingComplete, value: true);
      await first.close();

      final (second, reopened) = await open();
      expect(
        (await reopened.readBool(PreferenceKey.onboardingComplete)).valueOrNull,
        isTrue,
      );
      await second.close();
    });
  });

  group('absence', () {
    test('an unset key reads as Ok(null), not as false', () async {
      final (database, store) = await open();
      final read = await store.readBool(PreferenceKey.onboardingComplete);
      expect(read.isOk, isTrue);
      expect(read.valueOrNull, isNull);
      await database.close();
    });
  });

  group('malformed values are failures, not defaults', () {
    for (final bad in ['1', '0', 'TRUE', 'yes', '', 'null']) {
      test('"$bad" is a storage failure', () async {
        final (database, store) = await open();
        final db = (await database.open()).valueOrNull!;
        await db.insert(PreferencesStore.table, {
          'key': PreferenceKey.onboardingComplete.storedName,
          'value': bad,
        });

        final read = await store.readBool(PreferenceKey.onboardingComplete);
        expect(read.isOk, isFalse, reason: '"$bad" must not parse');
        expect(failureOf(read).kind, FailureKind.storage);
        expect(
          failureOf(read).message,
          contains(PreferenceKey.onboardingComplete.storedName),
          reason: 'the failure must name the key',
        );
        await database.close();
      });
    }
  });

  group('failures are reported', () {
    test('a read against a closed database is a storage failure', () async {
      final (database, store) = await open();
      await database.close();
      expect(
        failureOf(await store.readBool(PreferenceKey.onboardingComplete)).kind,
        FailureKind.storage,
      );
    });

    test('a write against a closed database is a storage failure', () async {
      final (database, store) = await open();
      await database.close();
      expect(
        failureOf(
          await store.writeBool(
            PreferenceKey.onboardingComplete,
            value: true,
          ),
        ).kind,
        FailureKind.storage,
      );
    });
  });

  group('declared keys', () {
    test('no two keys share a stored name', () {
      final names = PreferenceKey.values.map((k) => k.storedName).toSet();
      expect(names, hasLength(PreferenceKey.values.length));
    });

    test('stored names are snake_case, so they read as column data', () {
      final snake = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final key in PreferenceKey.values) {
        expect(key.storedName, matches(snake), reason: key.name);
      }
    });
  });
}
