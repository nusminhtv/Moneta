import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/features/transactions/data/sqlite_transaction_repository.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteTransactionRepository repository;

  setUp(() async {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repository = SqliteTransactionRepository(
      TransactionDao((await database.open()).valueOrNull!),
    );
  });

  tearDown(() async => database.close());

  Transaction build({
    String id = 'tx-1',
    int amount = 45000,
    Currency currency = Currency.vnd,
  }) {
    return Transaction.create(
      id: id,
      amount: Money(amount, currency),
      direction: TransactionDirection.expense,
      category: SpendCategory.food,
      occurredAt: DateTime.utc(2026, 8, 24, 9),
      createdAt: DateTime.utc(2026, 8, 24, 9),
    ).valueOrNull!;
  }

  AppFailure failureOf(Result<Object?> result) => result.when(
    ok: (v) => fail('expected a failure, got $v'),
    err: (f) => f,
  );

  group('happy path', () {
    test('adds and reads back', () async {
      final added = await repository.add(build());
      expect(added.isOk, isTrue);

      final listed = await repository.list(TransactionQuery.all);
      expect(listed.valueOrNull, hasLength(1));
      expect(listed.valueOrNull!.single.id, 'tx-1');
    });

    test('summarises', () async {
      await repository.add(build(amount: 1000));
      final summary = await repository.summarise(TransactionQuery.all);
      expect(summary.valueOrNull!.expenses.minorUnits, 1000);
    });

    test('deletes', () async {
      await repository.add(build());
      expect((await repository.delete('tx-1')).isOk, isTrue);
      expect(
        (await repository.list(TransactionQuery.all)).valueOrNull,
        isEmpty,
      );
    });
  });

  group('storage failures are converted, never swallowed', () {
    // Exercised against a genuinely broken connection rather than a fake DAO:
    // this proves the real sqflite failure path is converted, not just that a
    // stub's exception would be.
    late SqliteTransactionRepository broken;

    setUp(() async {
      final closed = AppDatabase(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final db = (await closed.open()).valueOrNull!;
      broken = SqliteTransactionRepository(TransactionDao(db));
      await closed.close();
    });

    test('a failed read returns Err, not an empty list', () async {
      // An empty list here would read as "no transactions" and be
      // indistinguishable from an empty wallet.
      final result = await broken.list(TransactionQuery.all);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(failureOf(result).kind, FailureKind.storage);
    });

    test('a failed write returns Err and does not throw', () async {
      final result = await broken.add(build());
      expect(failureOf(result).kind, FailureKind.storage);
    });

    test('a failed delete returns Err', () async {
      expect(failureOf(await broken.delete('x')).kind, FailureKind.storage);
    });

    test('a failed summary returns Err, not a zero summary', () async {
      // A zero summary would render as "you have spent nothing this month".
      final result = await broken.summarise(TransactionQuery.all);
      expect(result.isOk, isFalse);
      expect(failureOf(result).kind, FailureKind.storage);
    });

    test('the original error is preserved as the cause', () async {
      final cause = failureOf(await broken.list(TransactionQuery.all)).cause;
      expect(cause, isNotNull);
      expect('$cause', contains('database_closed'));
    });
  });

  group('a failed write leaves the database unchanged', () {
    test('a duplicate id does not overwrite the existing row', () async {
      await repository.add(build(amount: 1000));
      final second = await repository.add(build(amount: 9999));

      expect(second.isOk, isFalse);
      expect(failureOf(second).kind, FailureKind.storage);

      final rows = (await repository.list(TransactionQuery.all)).valueOrNull!;
      expect(rows, hasLength(1));
      expect(rows.single.amount.minorUnits, 1000);
    });
  });

  group('validation happens before any write', () {
    test('a currency the wallet does not use is rejected', () async {
      final result = await repository.add(
        build(currency: Currency.usd, amount: 100),
      );
      expect(failureOf(result).kind, FailureKind.validation);
      expect(
        (await repository.list(TransactionQuery.all)).valueOrNull,
        isEmpty,
      );
    });

    test('an empty id is rejected on delete', () async {
      expect(
        failureOf(await repository.delete('')).kind,
        FailureKind.validation,
      );
    });
  });

  group('delete reports a missing target', () {
    test('not-found rather than success', () async {
      // Reporting success would hide a stale UI.
      final result = await repository.delete('never-existed');
      expect(result.isOk, isFalse);
      expect(failureOf(result).kind, FailureKind.notFound);
      expect(failureOf(result).message, contains('never-existed'));
    });

    test('deleting twice reports not-found the second time', () async {
      await repository.add(build());
      expect((await repository.delete('tx-1')).isOk, isTrue);
      expect(
        failureOf(await repository.delete('tx-1')).kind,
        FailureKind.notFound,
      );
    });
  });
}
