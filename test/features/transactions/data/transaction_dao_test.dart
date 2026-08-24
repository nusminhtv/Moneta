import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late TransactionDao dao;
  late FixedIdGenerator ids;

  setUp(() async {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    dao = TransactionDao((await database.open()).valueOrNull!);
    ids = FixedIdGenerator(prefix: 'tx');
  });

  tearDown(() async => database.close());

  Transaction build({
    int amount = 45000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? occurredAt,
    String? note,
    String? id,
  }) {
    return Transaction.create(
      id: id ?? ids.next(),
      amount: Money(amount, Currency.vnd),
      direction: direction,
      category: category,
      occurredAt: occurredAt ?? DateTime.utc(2026, 8, 24, 9),
      createdAt: DateTime.utc(2026, 8, 24, 9),
      note: note,
    ).valueOrNull!;
  }

  Future<List<Transaction>> listAll([TransactionQuery? query]) async {
    final result = await dao.list(query ?? TransactionQuery.all);
    return result.when(
      ok: (t) => t,
      err: (f) => fail('expected Ok, got $f'),
    );
  }

  group('round trip', () {
    test('every field reads back unchanged', () async {
      final original = build(note: 'Cà phê sữa đá');
      await dao.insert(original);

      final read = (await listAll()).single;
      expect(read, original);
      expect(read.id, original.id);
      expect(read.amount, original.amount);
      expect(read.direction, original.direction);
      expect(read.category, original.category);
      expect(read.occurredAt, original.occurredAt);
      expect(read.createdAt, original.createdAt);
      expect(read.note, 'Cà phê sữa đá');
    });

    test('a transaction with no note reads back with no note', () async {
      await dao.insert(build());
      expect((await listAll()).single.note, isNull);
    });

    test('amounts are exact at a trillion minor units', () async {
      await dao.insert(build(amount: 1000000000000));
      expect((await listAll()).single.amount.minorUnits, 1000000000000);
    });

    test('the instant survives a zone round trip', () async {
      final instant = DateTime.utc(2026, 3, 15, 22, 45, 30);
      await dao.insert(build(occurredAt: instant.toLocal()));

      final read = (await listAll()).single;
      expect(read.occurredAt.isUtc, isTrue);
      expect(read.occurredAt, instant);
    });

    test('identical values with different ids are two records', () async {
      // A person can buy the same coffee twice.
      final at = DateTime.utc(2026, 8, 24, 9);
      await dao.insert(build(occurredAt: at, note: 'cà phê'));
      await dao.insert(build(occurredAt: at, note: 'cà phê'));

      final all = await listAll();
      expect(all, hasLength(2));
      expect(all.map((t) => t.id).toSet(), hasLength(2));
    });

    test('every category and direction round-trips', () async {
      for (final category in SpendCategory.values) {
        for (final direction in TransactionDirection.values) {
          await dao.insert(build(category: category, direction: direction));
        }
      }
      final all = await listAll();
      expect(all, hasLength(SpendCategory.values.length * 2));
      expect(
        all.map((t) => t.category).toSet(),
        SpendCategory.values.toSet(),
      );
    });
  });

  group('ordering', () {
    test('newest first', () async {
      await dao.insert(build(occurredAt: DateTime.utc(2026, 8, 1), id: 'a'));
      await dao.insert(build(occurredAt: DateTime.utc(2026, 8, 3), id: 'c'));
      await dao.insert(build(occurredAt: DateTime.utc(2026, 8, 2), id: 'b'));

      expect((await listAll()).map((t) => t.id), ['c', 'b', 'a']);
    });

    test('ties are ordered stably across reads', () async {
      final at = DateTime.utc(2026, 8, 24, 9);
      for (final id in ['b', 'a', 'c']) {
        await dao.insert(build(occurredAt: at, id: id));
      }
      final first = (await listAll()).map((t) => t.id).toList();
      final second = (await listAll()).map((t) => t.id).toList();
      expect(first, second);
      expect(first.toSet(), {'a', 'b', 'c'});
    });
  });

  group('empty database', () {
    test('reads as an empty list, successfully', () async {
      final result = await dao.list(TransactionQuery.all);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('summarises to zero, successfully', () async {
      final summary = await dao.summarise(TransactionQuery.all, Currency.vnd);
      expect(summary.income.isZero, isTrue);
      expect(summary.expenses.isZero, isTrue);
      expect(summary.net.isZero, isTrue);
    });
  });

  group('filtering', () {
    setUp(() async {
      await dao.insert(
        build(
          category: SpendCategory.food,
          occurredAt: DateTime.utc(2026, 8, 1),
          id: 'aug-food',
        ),
      );
      await dao.insert(
        build(
          category: SpendCategory.transport,
          occurredAt: DateTime.utc(2026, 8, 15),
          id: 'aug-transport',
        ),
      );
      await dao.insert(
        build(
          category: SpendCategory.food,
          occurredAt: DateTime.utc(2026, 9, 1),
          id: 'sep-food',
        ),
      );
    });

    test('by category', () async {
      final query = TransactionQuery.build(
        categories: {SpendCategory.food},
      ).valueOrNull!;
      expect(
        (await listAll(query)).map((t) => t.id).toSet(),
        {'aug-food', 'sep-food'},
      );
    });

    test('by several categories', () async {
      final query = TransactionQuery.build(
        categories: {SpendCategory.food, SpendCategory.transport},
      ).valueOrNull!;
      expect(await listAll(query), hasLength(3));
    });

    test('by date range, inclusive start and exclusive end', () async {
      final august = TransactionQuery.build(
        start: DateTime.utc(2026, 8),
        end: DateTime.utc(2026, 9),
      ).valueOrNull!;
      expect(
        (await listAll(august)).map((t) => t.id).toSet(),
        {'aug-food', 'aug-transport'},
      );
    });

    test('a transaction exactly on the start boundary is included', () async {
      final query = TransactionQuery.build(
        start: DateTime.utc(2026, 8),
        end: DateTime.utc(2026, 8, 2),
      ).valueOrNull!;
      expect((await listAll(query)).map((t) => t.id), ['aug-food']);
    });

    test('a transaction exactly on the end boundary is excluded', () async {
      final query = TransactionQuery.build(
        start: DateTime.utc(2026, 7),
        end: DateTime.utc(2026, 8),
      ).valueOrNull!;
      expect(await listAll(query), isEmpty);
    });

    test('adjacent ranges partition without overlap or loss', () async {
      final july = TransactionQuery.build(
        start: DateTime.utc(2026, 7),
        end: DateTime.utc(2026, 8),
      ).valueOrNull!;
      final august = TransactionQuery.build(
        start: DateTime.utc(2026, 8),
        end: DateTime.utc(2026, 9),
      ).valueOrNull!;
      final september = TransactionQuery.build(
        start: DateTime.utc(2026, 9),
        end: DateTime.utc(2026, 10),
      ).valueOrNull!;

      final ids = [
        ...(await listAll(july)).map((t) => t.id),
        ...(await listAll(august)).map((t) => t.id),
        ...(await listAll(september)).map((t) => t.id),
      ];
      expect(ids, hasLength(3));
      expect(ids.toSet(), hasLength(3));
    });

    test('category and range combine', () async {
      final query = TransactionQuery.build(
        categories: {SpendCategory.food},
        start: DateTime.utc(2026, 8),
        end: DateTime.utc(2026, 9),
      ).valueOrNull!;
      expect((await listAll(query)).map((t) => t.id), ['aug-food']);
    });

    test('a filter matching nothing is an empty success', () async {
      final query = TransactionQuery.build(
        categories: {SpendCategory.gift},
      ).valueOrNull!;
      final result = await dao.list(query);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('limit bounds the result', () async {
      final query = TransactionQuery.build(limit: 2).valueOrNull!;
      expect(await listAll(query), hasLength(2));
    });
  });

  group('summary', () {
    test('adds income and expenses separately and nets them', () async {
      await dao.insert(
        build(
          amount: 32000000,
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
        ),
      );
      await dao.insert(build(amount: 20000000));
      await dao.insert(build(amount: 5840000));

      final summary = await dao.summarise(TransactionQuery.all, Currency.vnd);
      expect(summary.income.minorUnits, 32000000);
      expect(summary.expenses.minorUnits, 25840000);
      expect(summary.net.minorUnits, 6160000);
    });

    test('respects the range', () async {
      await dao.insert(
        build(amount: 1000, occurredAt: DateTime.utc(2026, 8, 15)),
      );
      await dao.insert(
        build(amount: 9999, occurredAt: DateTime.utc(2026, 9, 15)),
      );

      final august = TransactionQuery.build(
        start: DateTime.utc(2026, 8),
        end: DateTime.utc(2026, 9),
      ).valueOrNull!;
      final summary = await dao.summarise(august, Currency.vnd);
      expect(summary.expenses.minorUnits, 1000);
    });

    test('large totals stay exact', () async {
      for (var i = 0; i < 10; i++) {
        await dao.insert(build(amount: 100000000000));
      }
      final summary = await dao.summarise(TransactionQuery.all, Currency.vnd);
      expect(summary.expenses.minorUnits, 1000000000000);
    });

    test(
      'income-only and expense-only periods report zero for the other',
      () async {
        await dao.insert(
          build(
            amount: 500,
            direction: TransactionDirection.income,
            category: SpendCategory.salary,
          ),
        );
        final summary = await dao.summarise(TransactionQuery.all, Currency.vnd);
        expect(summary.income.minorUnits, 500);
        expect(summary.expenses.isZero, isTrue);
      },
    );
  });

  group('the summary is an aggregate, not a row read', () {
    // Asserted on the SQL itself. Checking only the numbers would still pass if
    // someone replaced the aggregate with a fold over every row, which is the
    // regression this guards against.
    test('groups and sums in SQL', () {
      final statement = TransactionDao.buildSummaryStatement(
        TransactionQuery.all,
      );
      expect(statement.sql, contains('SUM(amount_minor)'));
      expect(statement.sql, contains('GROUP BY direction'));
    });

    test('does not select the amount column row by row', () {
      final statement = TransactionDao.buildSummaryStatement(
        TransactionQuery.all,
      );
      expect(statement.sql, isNot(contains('SELECT *')));
      expect(statement.sql.contains('SELECT direction, SUM'), isTrue);
    });

    test('carries the range into SQL rather than filtering in Dart', () {
      final statement = TransactionDao.buildSummaryStatement(
        TransactionQuery.build(
          start: DateTime.utc(2026, 8),
          end: DateTime.utc(2026, 9),
        ).valueOrNull!,
      );
      expect(statement.sql, contains('occurred_at >= ?'));
      expect(statement.sql, contains('occurred_at < ?'));
      expect(statement.args, hasLength(2));
    });
  });

  group('list SQL', () {
    test('uses inclusive start and exclusive end', () {
      final statement = TransactionDao.buildListStatement(
        TransactionQuery.build(
          start: DateTime.utc(2026, 8),
          end: DateTime.utc(2026, 9),
        ).valueOrNull!,
      );
      expect(statement.sql, contains('occurred_at >= ?'));
      expect(statement.sql, contains('occurred_at < ?'));
      expect(statement.sql, isNot(contains('occurred_at <= ?')));
    });

    test('orders newest first with deterministic tie-breaks', () {
      final statement = TransactionDao.buildListStatement(TransactionQuery.all);
      expect(
        statement.sql,
        contains('ORDER BY occurred_at DESC, created_at DESC, id DESC'),
      );
    });

    test('parameterises category names rather than interpolating them', () {
      final statement = TransactionDao.buildListStatement(
        TransactionQuery.build(
          categories: {SpendCategory.food, SpendCategory.bills},
        ).valueOrNull!,
      );
      expect(statement.sql, contains('category IN (?, ?)'));
      expect(statement.args, hasLength(2));
      expect(statement.sql, isNot(contains('food')));
    });
  });

  group('unreadable rows', () {
    test(
      'an unknown category fails the read rather than being skipped',
      () async {
        // Skipping the row would silently change a balance.
        final db = (await database.open()).valueOrNull!;
        await db.insert(TransactionDao.table, {
          'id': 'future',
          'amount_minor': 100,
          'currency': 'VND',
          'direction': 'expense',
          'category': 'crypto',
          'occurred_at': 0,
          'created_at': 0,
        });

        final result = await dao.list(TransactionQuery.all);
        expect(result.isOk, isFalse);
        result.when(
          ok: (_) => fail('expected a failure'),
          err: (f) {
            expect(f.kind, FailureKind.storage);
            expect(f.message, contains('crypto'));
          },
        );
      },
    );

    test('an unknown direction fails the read', () async {
      final db = (await database.open()).valueOrNull!;
      await db.insert(TransactionDao.table, {
        'id': 'future',
        'amount_minor': 100,
        'currency': 'VND',
        'direction': 'transfer',
        'category': 'food',
        'occurred_at': 0,
        'created_at': 0,
      });
      expect((await dao.list(TransactionQuery.all)).isOk, isFalse);
    });
  });

  group('delete', () {
    test('removes the row and reports the count', () async {
      await dao.insert(build(id: 'gone'));
      expect(await dao.delete('gone'), 1);
      expect(await listAll(), isEmpty);
    });

    test('reports zero when nothing matched', () async {
      expect(await dao.delete('never-existed'), 0);
    });

    test('removes only the named row', () async {
      await dao.insert(build(id: 'keep'));
      await dao.insert(build(id: 'drop'));
      await dao.delete('drop');
      expect((await listAll()).map((t) => t.id), ['keep']);
    });
  });
}
