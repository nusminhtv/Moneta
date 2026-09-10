import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/app/demo/demo_seeder.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/data/sqlite_budget_repository.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_repository.dart';
import 'package:moneta/features/transactions/data/sqlite_transaction_repository.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Plain `test`, never `testWidgets`: real database I/O.
void main() {
  sqfliteFfiInit();

  final anchor = DateTime.utc(2026, 9, 17, 14, 30);

  late AppDatabase database;
  late TransactionRepository transactions;
  late BudgetRepository budgets;

  setUp(() async {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final db = (await database.open()).valueOrNull!;
    transactions = SqliteTransactionRepository(
      TransactionDao(db),
      currency: Currency.vnd,
    );
    budgets = SqliteBudgetRepository(BudgetDao(db));
    addTearDown(database.close);
  });

  DemoDataset dataset({int months = 3}) => generateDemoDataset(
    clock: FixedClock(anchor),
    ids: FixedIdGenerator(prefix: 'demo'),
    monthsOfHistory: months,
  );

  test('the whole dataset reaches the ledger', () async {
    final data = dataset();
    final seeded = await DemoSeeder(
      transactions: transactions,
      budgets: budgets,
    ).seed(data);

    expect(seeded.isOk, isTrue);
    expect(
      seeded.valueOrNull,
      data.transactions.length + data.budgets.length,
    );

    final listed = await transactions.list(TransactionQuery.all);
    expect(listed.valueOrNull, hasLength(data.transactions.length));
    final storedBudgets = await budgets.list();
    expect(storedBudgets.valueOrNull, hasLength(data.budgets.length));
  });

  test('what comes back out is what went in, field for field', () async {
    final data = dataset(months: 2);
    await DemoSeeder(transactions: transactions, budgets: budgets).seed(data);

    final listed = (await transactions.list(TransactionQuery.all)).valueOrNull!;
    final byId = {for (final t in listed) t.id: t};
    for (final original in data.transactions) {
      final stored = byId[original.id];
      expect(stored, isNotNull, reason: '${original.id} never landed');
      expect(stored!.amount, original.amount);
      expect(stored.direction, original.direction);
      expect(stored.category, original.category);
      expect(stored.occurredAt, original.occurredAt);
      expect(stored.note, original.note);
    }
  });

  test('a repository failure stops the seed and is surfaced', () async {
    final data = dataset(months: 2);
    final failing = _FailingTransactionRepository(
      inner: transactions,
      failAfter: 5,
    );

    final result = await DemoSeeder(
      transactions: failing,
      budgets: budgets,
    ).seed(data);

    expect(result.isOk, isFalse);
    expect(
      result.when(ok: (_) => null, err: (f) => f.message),
      contains('the disk fell over'),
    );

    // Stopped, not carried on: exactly the records before the failure.
    final listed = (await transactions.list(TransactionQuery.all)).valueOrNull!;
    expect(listed, hasLength(5));

    // And no budget was written, because budgets come after transactions.
    expect((await budgets.list()).valueOrNull, isEmpty);
  });

  test('a budget failure is surfaced too', () async {
    final data = dataset(months: 2);
    final result = await DemoSeeder(
      transactions: transactions,
      budgets: _FailingBudgetRepository(budgets),
    ).seed(data);

    expect(result.isOk, isFalse);
    expect((await budgets.list()).valueOrNull, isEmpty);
  });

  test('seeding twice into one ledger duplicates nothing silently', () async {
    // The repositories reject a duplicate id, so a second seed of the same
    // dataset must FAIL rather than double every row. This is what makes the
    // completion marker load-bearing rather than an optimisation.
    final data = dataset(months: 2);
    final seeder = DemoSeeder(transactions: transactions, budgets: budgets);
    expect((await seeder.seed(data)).isOk, isTrue);

    final again = await seeder.seed(data);
    final listed = (await transactions.list(TransactionQuery.all)).valueOrNull!;
    expect(
      again.isOk && listed.length == data.transactions.length * 2,
      isFalse,
      reason:
          'a second seed either fails or is a no-op; it must not double '
          'the ledger',
    );
  });

  test('the seeder holds no SQL of its own', () {
    // D3 as a source-level check: the moment it writes a table directly it can
    // drift from a schema it does not otherwise know about.
    final source = File('lib/app/demo/demo_seeder.dart').readAsStringSync();
    for (final forbidden in [
      'INSERT',
      'insert(',
      'rawInsert',
      'execute(',
      'Database',
      'sqflite',
    ]) {
      expect(
        source,
        isNot(contains(forbidden)),
        reason: 'the seeder reached past the repositories: $forbidden',
      );
    }
    expect(source, contains('transactions.add('));
    expect(source, contains('budgets.add('));
  });
}

/// Fails on the nth write, so the stop-and-report path is exercised against a
/// real ledger rather than a stub with no rows in it.
class _FailingTransactionRepository implements TransactionRepository {
  _FailingTransactionRepository({required this.inner, required this.failAfter});

  final TransactionRepository inner;
  final int failAfter;
  int _written = 0;

  @override
  Future<Result<Transaction>> add(Transaction transaction) async {
    if (_written >= failAfter) {
      return const Err(AppFailure.storage('the disk fell over'));
    }
    _written++;
    return inner.add(transaction);
  }

  @override
  Future<Result<void>> delete(String id) => inner.delete(id);

  @override
  Future<Result<List<Transaction>>> list(TransactionQuery query) =>
      inner.list(query);

  @override
  Future<Result<PeriodSummary>> summarise(TransactionQuery query) =>
      inner.summarise(query);
}

class _FailingBudgetRepository implements BudgetRepository {
  _FailingBudgetRepository(this.inner);

  final BudgetRepository inner;

  @override
  Future<Result<void>> add(Budget budget) async =>
      const Err(AppFailure.storage('no room for budgets'));

  @override
  Future<Result<Budget>> byId(String id) => inner.byId(id);

  @override
  Future<Result<bool>> exists({
    required SpendCategory category,
    required BudgetPeriod period,
  }) => inner.exists(category: category, period: period);

  @override
  Future<Result<List<Budget>>> list() => inner.list();

  @override
  Future<Result<void>> remove(String id) => inner.remove(id);

  @override
  Future<Result<void>> update(Budget budget) => inner.update(budget);
}
