import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:moneta/features/settings/data/profile_store.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  sqfliteFfiInit();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('moneta_profile_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<(AppDatabase, ProfileStore, PreferencesStore)> open() async {
    final database = AppDatabase(
      path: '${tempDir.path}/moneta.db',
      factory: databaseFactoryFfi,
    );
    final db = (await database.open()).valueOrNull!;
    final preferences = PreferencesStore(db);
    return (database, ProfileStore(preferences), preferences);
  }

  AppFailure failureOf(Result<Object?> r) =>
      r.when(ok: (v) => fail('expected a failure, got $v'), err: (f) => f);

  group('the first name is the first word', () {
    // A table, because the rule's whole content is which word it picks and
    // what it strips. The two rows that disagree with each other are the
    // point: no rule is right for both name orders, and this one's cost is
    // `Trần Văn Minh` being greeted by surname.
    const expected = {
      'Minh Tran': 'Minh',
      'Trần Văn Minh': 'Trần',
      'Đặng Thu Thảo': 'Đặng',
      'Minh': 'Minh',
      '  Minh   Tran  ': 'Minh',
      'Minh, Tran': 'Minh',
      "O'Brien Nguyen": 'OBrien',
      '👨‍👩‍👧': '',
      '123': '',
      '   ': '',
      '': '',
    };

    for (final entry in expected.entries) {
      test('"${entry.key}" -> "${entry.value}"', () {
        expect(Profile(name: entry.key).firstName, entry.value);
      });
    }

    test('a name in the other order is greeted by surname, as recorded', () {
      // Asserted rather than left as a comment, so the cost of the rule is a
      // fact the test suite holds rather than a claim in a doc.
      expect(const Profile(name: 'Trần Văn Minh').firstName, 'Trần');
      expect(
        const Profile(name: 'Trần Văn Minh').firstName,
        isNot('Minh'),
        reason: 'the last word is the given name here, and this rule skips it',
      );
    });
  });

  group('validation', () {
    test('a name is required', () {
      expect(
        const Profile(name: '').validationFailure?.kind,
        FailureKind.validation,
      );
      expect(
        const Profile(name: '   ').validationFailure?.kind,
        FailureKind.validation,
      );
      expect(const Profile(name: 'Minh').validationFailure, isNull);
    });

    test('an email is not, but an invalid one is refused', () {
      expect(const Profile(name: 'Minh').validationFailure, isNull);
      expect(
        const Profile(name: 'Minh', email: '').validationFailure,
        isNull,
      );
      expect(
        const Profile(
          name: 'Minh',
          email: 'minh.tran@example.com',
        ).validationFailure,
        isNull,
      );
      for (final bad in ['minh.tran', '@example.com', 'a@b', 'a b@c.com']) {
        expect(
          const Profile(
            name: 'Minh',
          ).copyWith(email: bad).validationFailure?.kind,
          FailureKind.validation,
          reason: '"$bad" should be refused',
        );
      }
    });
  });

  group('reading and writing', () {
    test('first run has no profile', () async {
      final (database, store, _) = await open();
      addTearDown(database.close);

      expect((await store.read()).valueOrNull, isNull);
    });

    test('a saved profile reads back, all three fields', () async {
      final (database, store, _) = await open();
      addTearDown(database.close);

      const profile = Profile(
        name: 'Trần Văn Minh',
        email: 'minh.tran@example.com',
        currency: Currency.usd,
      );
      expect((await store.save(profile)).isOk, isTrue);
      expect((await store.read()).valueOrNull, profile);
    });

    test('a name of only whitespace is not a profile', () async {
      final (database, store, preferences) = await open();
      addTearDown(database.close);

      // Written around the store, because the store refuses to write it — the
      // case is a row put there by something else, or by an older build.
      await preferences.writeString(PreferenceKey.profileName, value: '   ');
      expect(
        (await store.read()).valueOrNull,
        isNull,
        reason: 'a blank name is not a profile anyone chose',
      );
    });

    test('an empty email round-trips as empty, not as absent', () async {
      final (database, store, _) = await open();
      addTearDown(database.close);

      await store.save(const Profile(name: 'Minh'));
      expect((await store.read()).valueOrNull?.email, '');
    });

    test('the name is trimmed on the way in', () async {
      final (database, store, _) = await open();
      addTearDown(database.close);

      await store.save(const Profile(name: '  Minh  '));
      expect((await store.read()).valueOrNull?.name, 'Minh');
    });

    test('an invalid profile writes nothing at all', () async {
      final (database, store, preferences) = await open();
      addTearDown(database.close);

      await store.save(const Profile(name: 'Minh', email: 'ok@example.com'));
      final refused = await store.save(
        const Profile(name: 'Bích', email: 'not-an-address'),
      );

      expect(failureOf(refused).kind, FailureKind.validation);
      // Not even the name, which is valid on its own: a half-written profile
      // is a profile nobody entered.
      expect(
        (await preferences.readString(PreferenceKey.profileName)).valueOrNull,
        'Minh',
      );
    });

    test('an unknown stored currency falls back rather than failing', () async {
      final (database, store, preferences) = await open();
      addTearDown(database.close);

      await store.save(const Profile(name: 'Minh'));
      await preferences.writeString(
        PreferenceKey.profileCurrency,
        value: 'xbt',
      );

      // A row written by a newer build must not make the whole profile
      // unreadable — the name is the part that matters.
      final read = (await store.read()).valueOrNull;
      expect(read?.name, 'Minh');
      expect(read?.currency, Currency.vnd);
    });

    test('a storage failure is reported, not treated as absence', () async {
      final (database, store, _) = await open();
      await database.close();

      final read = await store.read();
      expect(read.isOk, isFalse, reason: 'a closed database is not "no name"');
      expect(failureOf(read).kind, FailureKind.storage);

      expect(
        failureOf(await store.save(const Profile(name: 'Minh'))).kind,
        FailureKind.storage,
      );
    });
  });
}
