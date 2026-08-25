import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/data/database/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  Future<Database> freshDatabase({
    required int version,
    List<Migration>? using,
  }) {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, v) => runMigrations(db, from: 0, to: v, using: using),
        onUpgrade: (db, from, to) =>
            runMigrations(db, from: from, to: to, using: using),
      ),
    );
  }

  /// The full schema as SQLite reports it — tables, indexes and their SQL.
  Future<List<Map<String, Object?>>> schemaOf(Database db) async {
    return db.rawQuery(
      'SELECT type, name, tbl_name, sql FROM sqlite_master '
      "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
    );
  }

  group('the migration set itself', () {
    test('is contiguous from 1 to the declared version', () {
      expect(
        () => assertMigrationSetIsWellFormed(migrations, schemaVersion),
        returnsNormally,
      );
      expect(
        migrations.map((m) => m.version),
        [for (var v = 1; v <= schemaVersion; v++) v],
      );
    });

    test('rejects a gap', () {
      final broken = [
        Migration(version: 1, apply: (_) async {}),
        Migration(version: 3, apply: (_) async {}),
      ];
      expect(
        () => assertMigrationSetIsWellFormed(broken, 3),
        throwsA(isA<MigrationSetError>()),
      );
    });

    test('rejects a duplicate', () {
      final broken = [
        Migration(version: 1, apply: (_) async {}),
        Migration(version: 1, apply: (_) async {}),
      ];
      expect(
        () => assertMigrationSetIsWellFormed(broken, 2),
        throwsA(isA<MigrationSetError>()),
      );
    });

    test('rejects out-of-order versions', () {
      final broken = [
        Migration(version: 2, apply: (_) async {}),
        Migration(version: 1, apply: (_) async {}),
      ];
      expect(
        () => assertMigrationSetIsWellFormed(broken, 2),
        throwsA(isA<MigrationSetError>()),
      );
    });

    test('rejects a set shorter than the declared version', () {
      expect(
        () => assertMigrationSetIsWellFormed(migrations, schemaVersion + 1),
        throwsA(isA<MigrationSetError>()),
      );
    });
  });

  group('v1 schema', () {
    late Database db;

    setUp(() async {
      db = await freshDatabase(version: schemaVersion);
    });

    tearDown(() async => db.close());

    test('creates the transactions table with the declared columns', () async {
      final columns = await db.rawQuery('PRAGMA table_info(transactions)');
      final byName = {
        for (final c in columns) c['name']! as String: c,
      };

      expect(
        byName.keys.toSet(),
        {
          'id',
          'amount_minor',
          'currency',
          'direction',
          'category',
          'occurred_at',
          'note',
          'created_at',
        },
      );
      expect(byName['id']!['type'], 'TEXT');
      expect(byName['id']!['pk'], 1);
      expect(byName['amount_minor']!['type'], 'INTEGER');
      expect(byName['occurred_at']!['type'], 'INTEGER');
      // note is the only nullable column.
      expect(byName['note']!['notnull'], 0);
      for (final name in byName.keys.where((n) => n != 'note')) {
        expect(byName[name]!['notnull'], 1, reason: '$name should be NOT NULL');
      }
    });

    test('creates the indexes the read paths depend on', () async {
      final indexes = await db.rawQuery('PRAGMA index_list(transactions)');
      final names = indexes.map((i) => i['name']).toSet();
      expect(names, contains('idx_transactions_occurred_at'));
      expect(names, contains('idx_transactions_category'));
    });

    test('amount_minor holds a trillion without loss', () async {
      // SQLite INTEGER is 64-bit; this is the exactness Money depends on.
      const big = 1000000000000;
      await db.insert('transactions', {
        'id': 'x',
        'amount_minor': big,
        'currency': 'VND',
        'direction': 'expense',
        'category': 'food',
        'occurred_at': 0,
        'created_at': 0,
      });
      final row = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['x'],
      );
      expect(row.single['amount_minor'], big);
    });
  });

  group('v2 — settings, applied to a populated database', () {
    test(
      'v1 rows survive the upgrade and the new table arrives empty',
      () async {
        // The first migration this project applies to real data. Before v2
        // there was only one version, so this case could not be exercised.
        //
        // File-backed, not in-memory: two opens of inMemoryDatabasePath are two
        // different databases, so an in-memory version of this test would query
        // an empty table and prove nothing.
        final dir = await Directory.systemTemp.createTemp('moneta_v2');
        addTearDown(() => dir.delete(recursive: true));
        final path = '${dir.path}/moneta.db';

        Future<Database> openAt(int version, List<Migration> using) {
          return factory.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: version,
              onCreate: (db, v) =>
                  runMigrations(db, from: 0, to: v, using: using),
              onUpgrade: (db, from, to) =>
                  runMigrations(db, from: from, to: to, using: using),
            ),
          );
        }

        final v1 = await openAt(1, [migrations.first]);
        await v1.insert('transactions', {
          'id': 'survivor',
          'amount_minor': 45000,
          'currency': 'VND',
          'direction': 'expense',
          'category': 'food',
          'occurred_at': 1756000000000,
          'note': 'phở',
          'created_at': 1756000000000,
        });
        await v1.close();

        final v2 = await openAt(2, migrations);
        expect(await v2.getVersion(), 2);

        final rows = await v2.query('transactions');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'survivor');
        expect(rows.single['note'], 'phở');
        expect(rows.single['amount_minor'], 45000);

        final settings = await v2.query('settings');
        expect(settings, isEmpty, reason: 'the new table starts empty');
        await v2.close();
      },
    );

    test('settings has a text primary key and a not-null value', () async {
      final db = await freshDatabase(version: schemaVersion);
      final columns = await db.rawQuery('PRAGMA table_info(settings)');
      final byName = {for (final c in columns) c['name']! as String: c};

      expect(byName.keys.toSet(), {'key', 'value'});
      expect(byName['key']!['type'], 'TEXT');
      expect(byName['key']!['pk'], 1);
      expect(byName['value']!['notnull'], 1);
      await db.close();
    });

    test('a duplicate key replaces rather than accumulating', () async {
      final db = await freshDatabase(version: schemaVersion);
      await db.insert('settings', {'key': 'k', 'value': 'a'});
      await db.insert(
        'settings',
        {'key': 'k', 'value': 'b'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final rows = await db.query('settings');
      expect(rows, hasLength(1));
      expect(rows.single['value'], 'b');
      await db.close();
    });
  });

  group('fresh install versus stepwise upgrade', () {
    test('produce an identical schema', () async {
      // The test that catches the classic mistake: editing migration v1 in place
      // instead of adding v2. A fresh install would get the edit; every existing
      // device would not, and the two would drift apart silently.
      final fresh = await freshDatabase(version: schemaVersion);
      final freshSchema = await schemaOf(fresh);
      await fresh.close();

      var stepwise = await freshDatabase(version: 1);
      for (var v = 2; v <= schemaVersion; v++) {
        await stepwise.close();
        stepwise = await freshDatabase(version: v);
      }
      final upgradedSchema = await schemaOf(stepwise);
      await stepwise.close();

      expect(upgradedSchema, freshSchema);
    });
  });

  group('runMigrations', () {
    test('applies only the steps above the stored version', () async {
      final applied = <int>[];
      final set = [
        for (var v = 1; v <= 4; v++)
          Migration(version: v, apply: (_) async => applied.add(v)),
      ];
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await runMigrations(db, from: 2, to: 4, using: set);
      await db.close();
      expect(applied, [3, 4]);
    });

    test('applies nothing when already current', () async {
      final applied = <int>[];
      final set = [
        for (var v = 1; v <= 3; v++)
          Migration(version: v, apply: (_) async => applied.add(v)),
      ];
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await runMigrations(db, from: 3, to: 3, using: set);
      await db.close();
      expect(applied, isEmpty);
    });

    test('stops at the first failure and does not run later steps', () async {
      final applied = <int>[];
      final set = [
        Migration(version: 1, apply: (_) async => applied.add(1)),
        Migration(version: 2, apply: (_) async => throw StateError('boom')),
        Migration(version: 3, apply: (_) async => applied.add(3)),
      ];
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await expectLater(
        runMigrations(db, from: 0, to: 3, using: set),
        throwsStateError,
      );
      await db.close();
      expect(applied, [1], reason: 'step 3 must not run after step 2 failed');
    });
  });
}
