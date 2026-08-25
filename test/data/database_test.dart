import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/database/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('moneta_db_test');
    dbPath = '${tempDir.path}/moneta.db';
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  AppDatabase build({List<Migration>? set, int? version, String? path}) {
    return AppDatabase(
      path: path ?? dbPath,
      factory: factory,
      migrationSet: set,
      version: version,
    );
  }

  group('opening', () {
    test('opens successfully and applies the schema', () async {
      final database = build();
      final result = await database.open();

      expect(result.isOk, isTrue);
      final db = result.valueOrNull!;
      expect(await db.getVersion(), schemaVersion);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables.map((t) => t['name']), contains('transactions'));

      await database.close();
    });

    test('opens once even under concurrent first access', () async {
      final database = build();
      final results = await Future.wait([
        database.open(),
        database.open(),
        database.open(),
      ]);

      expect(results.every((r) => r.isOk), isTrue);
      expect(database.openCount, 1);
      // And every caller got the same connection.
      final connections = results.map((r) => r.valueOrNull).toSet();
      expect(connections, hasLength(1));

      await database.close();
    });

    test('a second open after the first returns the same connection', () async {
      final database = build();
      final first = (await database.open()).valueOrNull;
      final second = (await database.open()).valueOrNull;
      expect(identical(first, second), isTrue);
      expect(database.openCount, 1);
      await database.close();
    });

    test('reports a storage failure when the path cannot be opened', () async {
      // A directory is not a database file. sqflite_ffi happily creates missing
      // parent directories, so a merely non-existent path is not a failure.
      final database = build(path: tempDir.path);
      final result = await database.open();

      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (failure) => expect(failure.kind, FailureKind.storage),
      );
    });

    test('a malformed migration set throws rather than becoming a failure', () {
      // A programming error must crash in development, not be reported to the
      // user as "could not open the database".
      final database = build(
        set: [Migration(version: 2, apply: (_) async {})],
        version: 2,
      );
      expect(database.open, throwsA(isA<MigrationSetError>()));
    });
  });

  group('durability', () {
    test('a written row survives close and reopen', () async {
      final first = build();
      final db = (await first.open()).valueOrNull!;
      await db.insert('transactions', {
        'id': 'tx-1',
        'amount_minor': 123456,
        'currency': 'VND',
        'direction': 'expense',
        'category': 'food',
        'occurred_at': 1756000000000,
        'note': 'phở',
        'created_at': 1756000000000,
      });
      await first.close();

      final second = build();
      final reopened = (await second.open()).valueOrNull!;
      final rows = await reopened.query('transactions');

      expect(rows, hasLength(1));
      expect(rows.single['id'], 'tx-1');
      expect(rows.single['amount_minor'], 123456);
      expect(rows.single['note'], 'phở');
      await second.close();
    });

    test('close is idempotent', () async {
      final database = build();
      await database.open();
      await database.close();
      await expectLater(database.close(), completes);
    });

    test('reopening after close works', () async {
      final database = build();
      await database.open();
      await database.close();
      final again = await database.open();
      expect(again.isOk, isTrue);
      expect(database.openCount, 2);
      await database.close();
    });
  });

  group('version mismatches', () {
    test(
      'refuses to open a database newer than the app, without data loss',
      () async {
        // Simulate a user downgrading: write one version ABOVE the app, then
        // open with the app's own version. Expressed relative to schemaVersion
        // so this keeps working as the schema grows — hardcoding 2 is what broke
        // it when v2 shipped.
        const aheadVersion = schemaVersion + 1;
        final ahead = [
          ...migrations,
          Migration(
            version: aheadVersion,
            apply: (db) =>
                db.execute('ALTER TABLE transactions ADD COLUMN x TEXT'),
          ),
        ];
        final newer = build(set: ahead, version: aheadVersion);
        final db = (await newer.open()).valueOrNull!;
        await db.insert('transactions', {
          'id': 'keep-me',
          'amount_minor': 1,
          'currency': 'VND',
          'direction': 'income',
          'category': 'salary',
          'occurred_at': 0,
          'created_at': 0,
        });
        await newer.close();

        final older = build();
        final result = await older.open();

        expect(result.isOk, isFalse);
        result.when(
          ok: (_) => fail('expected a refusal'),
          err: (failure) {
            expect(failure.kind, FailureKind.storage);
            expect(failure.message, contains('newer than this app'));
          },
        );

        // The row is still there: refusing must not destroy data.
        final check = build(set: ahead, version: aheadVersion);
        final rows = await (await check.open()).valueOrNull!.query(
          'transactions',
        );
        expect(rows.map((r) => r['id']), contains('keep-me'));
        await check.close();
      },
    );

    test('a failing migration leaves the stored version behind', () async {
      final failing = [
        ...migrations,
        Migration(
          version: schemaVersion + 1,
          apply: (_) async => throw StateError('boom'),
        ),
      ];
      final first = build();
      await first.open();
      await first.close();

      final upgrading = build(set: failing, version: schemaVersion + 1);
      final result = await upgrading.open();
      expect(result.isOk, isFalse);

      // Still openable at the app's version, with its schema intact.
      final recovered = build();
      final db = (await recovered.open()).valueOrNull!;
      expect(await db.getVersion(), schemaVersion);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables.map((t) => t['name']), contains('transactions'));
      await recovered.close();
    });

    test('upgrades an existing database forward, preserving rows', () async {
      final first = build();
      final db = (await first.open()).valueOrNull!;
      await db.insert('transactions', {
        'id': 'survivor',
        'amount_minor': 500,
        'currency': 'VND',
        'direction': 'expense',
        'category': 'food',
        'occurred_at': 10,
        'created_at': 10,
      });
      await first.close();

      const nextVersion = schemaVersion + 1;
      final withAccount = [
        ...migrations,
        Migration(
          version: nextVersion,
          apply: (db) =>
              db.execute('ALTER TABLE transactions ADD COLUMN account TEXT'),
        ),
      ];
      final upgraded = build(set: withAccount, version: nextVersion);
      final db2 = (await upgraded.open()).valueOrNull!;

      expect(await db2.getVersion(), nextVersion);
      final rows = await db2.query('transactions');
      expect(rows.single['id'], 'survivor');
      expect(rows.single.containsKey('account'), isTrue);
      await upgraded.close();
    });
  });
}
