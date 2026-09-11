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

    test('and the same for strings, in both directions', () async {
      // The coverage gate caught these missing: the string accessors' error
      // paths were the only uncovered lines in the file, and the spec requires
      // a storage failure rather than a default for both.
      final (database, store) = await open();
      await database.close();

      final read = await store.readString(PreferenceKey.profileName);
      expect(failureOf(read).kind, FailureKind.storage);
      expect(
        failureOf(read).message,
        contains(PreferenceKey.profileName.storedName),
        reason: 'the failure must name the key',
      );

      final write = await store.writeString(
        PreferenceKey.profileName,
        value: 'Minh',
      );
      expect(failureOf(write).kind, FailureKind.storage);
      expect(
        failureOf(write).message,
        contains(PreferenceKey.profileName.storedName),
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

    test('demoMode is declared, since the toggle needs somewhere to live', () {
      expect(PreferenceKey.demoMode.storedName, 'demo_mode');
    });
  });

  group('every preference is control-scoped', () {
    // The point of these: a preference must not change value because the
    // active ledger changed. The store is bound to the control database in
    // `app_providers.dart`; these assert the consequence at the storage level,
    // where it can be seen without a provider container.

    Future<(AppDatabase, PreferencesStore)> openAt(String path) async {
      final database = AppDatabase(path: path, factory: databaseFactoryFfi);
      final db = (await database.open()).valueOrNull!;
      return (database, PreferencesStore(db));
    }

    test('a value written before a swap reads back after it', () async {
      final (control, store) = await openAt(dbPath);
      addTearDown(control.close);

      expect(
        (await store.writeBool(PreferenceKey.demoMode, value: true)).isOk,
        isTrue,
      );

      // The demo database is opened alongside — the swap — and the control
      // store is asked again afterwards.
      final (demo, _) = await openAt('${tempDir.path}/moneta_demo.db');
      addTearDown(demo.close);

      expect(
        (await store.readBool(PreferenceKey.demoMode)).valueOrNull,
        isTrue,
        reason: 'the flag must survive the database it selects becoming active',
      );
    });

    test('the demo database holds no declared preference', () async {
      final (control, controlStore) = await openAt(dbPath);
      final (demo, demoStore) = await openAt('${tempDir.path}/moneta_demo.db');
      addTearDown(control.close);
      addTearDown(demo.close);

      for (final key in PreferenceKey.values) {
        expect((await controlStore.writeBool(key, value: true)).isOk, isTrue);
      }

      // Same table, same schema, and empty of preferences: the migration set is
      // shared, so the table exists in both, and nothing puts a preference in
      // the one that moves.
      for (final key in PreferenceKey.values) {
        expect(
          (await demoStore.readBool(key)).valueOrNull,
          isNull,
          reason: '${key.name} leaked into the demo ledger',
        );
      }
    });

    test('a string round-trips, and replacing leaves one row', () async {
      final (database, store) = await open();
      addTearDown(database.close);

      await store.writeString(PreferenceKey.profileName, value: 'Minh');
      expect(
        (await store.readString(PreferenceKey.profileName)).valueOrNull,
        'Minh',
      );

      await store.writeString(PreferenceKey.profileName, value: 'Trần');
      expect(
        (await store.readString(PreferenceKey.profileName)).valueOrNull,
        'Trần',
      );
      final db = (await database.open()).valueOrNull!;
      final rows = await db.query(
        PreferencesStore.table,
        where: 'key = ?',
        whereArgs: [PreferenceKey.profileName.storedName],
      );
      expect(rows, hasLength(1), reason: 'a write must replace, not append');
    });

    test('nothing stored is not an empty string', () async {
      final (database, store) = await open();
      addTearDown(database.close);

      // The distinction the boolean accessors already hold: an unset name and
      // a cleared one are different facts, and a store that conflated them
      // would make "never entered" indistinguishable from "deleted".
      expect(
        (await store.readString(PreferenceKey.profileName)).valueOrNull,
        isNull,
      );

      await store.writeString(PreferenceKey.profileName, value: '');
      expect(
        (await store.readString(PreferenceKey.profileName)).valueOrNull,
        '',
      );
    });

    test('strings a careless implementation would break', () async {
      final (database, store) = await open();
      addTearDown(database.close);

      // A quote (SQL injection if the value were interpolated), a newline, a
      // grapheme cluster made of several code points, and a Vietnamese
      // diacritic.
      const awkward = "Trần's note\nwith 👨‍👩‍👧 and 'quotes'";
      await store.writeString(PreferenceKey.profileName, value: awkward);
      expect(
        (await store.readString(PreferenceKey.profileName)).valueOrNull,
        awkward,
      );
    });

    test('a very long value is not truncated', () async {
      final (database, store) = await open();
      addTearDown(database.close);

      final long = 'a' * 10000;
      await store.writeString(PreferenceKey.profileEmail, value: long);
      final read = (await store.readString(
        PreferenceKey.profileEmail,
      )).valueOrNull;
      // The length is asserted as well as the content: a truncating write
      // would still round-trip a prefix, and `expect(read, long)` alone
      // reports a diff so large it is unreadable.
      expect(read, hasLength(10000));
      expect(read, long);
    });

    test('a boolean key read as a string gives the literal text', () async {
      final (database, store) = await open();
      addTearDown(database.close);

      await store.writeBool(PreferenceKey.demoMode, value: true);
      expect(
        (await store.readString(PreferenceKey.demoMode)).valueOrNull,
        PreferencesStore.trueText,
        reason: 'the column is TEXT and that is what is in it',
      );

      // And the reverse is still a failure, which is the existing contract
      // and is not relaxed by adding string accessors.
      await store.writeString(PreferenceKey.profileName, value: 'Minh');
      expect(
        failureOf(await store.readBool(PreferenceKey.profileName)).kind,
        FailureKind.storage,
      );
    });

    test(
      'finishing the introduction is not undone by the demo ledger',
      () async {
        final (control, controlStore) = await openAt(dbPath);
        addTearDown(control.close);
        await controlStore.writeBool(
          PreferenceKey.onboardingComplete,
          value: true,
        );

        final (demo, _) = await openAt('${tempDir.path}/moneta_demo.db');
        addTearDown(demo.close);

        expect(
          (await controlStore.readBool(
            PreferenceKey.onboardingComplete,
          )).valueOrNull,
          isTrue,
          reason:
              'a ledger-scoped onboarding flag would re-show the intro every '
              'time demo mode was enabled',
        );
      },
    );
  });
}
