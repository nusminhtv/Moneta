import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/app/demo/demo_seed_marker.dart';
import 'package:moneta/app/demo/demo_seeder.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/data/sqlite_budget_repository.dart';
import 'package:moneta/features/transactions/data/sqlite_transaction_repository.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Plain `test`, never `testWidgets`: real database I/O.
void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late Database db;
  late DemoSeedMarker marker;
  late DemoSeeder seeder;

  setUp(() async {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    db = (await database.open()).valueOrNull!;
    marker = DemoSeedMarker(db);
    seeder = DemoSeeder(
      transactions: SqliteTransactionRepository(
        TransactionDao(db),
        currency: Currency.vnd,
      ),
      budgets: SqliteBudgetRepository(BudgetDao(db)),
    );
    addTearDown(database.close);
  });

  DemoDataset dataset() => generateDemoDataset(
    clock: FixedClock(DateTime.utc(2026, 9, 17, 14, 30)),
    ids: FixedIdGenerator(prefix: 'demo'),
    monthsOfHistory: 2,
  );

  group('the marker', () {
    test('an unseeded ledger reports false, not an error', () async {
      final seeded = await marker.isSeeded();
      expect(seeded.isOk, isTrue);
      expect(seeded.valueOrNull, isFalse);
    });

    test('marking then reading reports true', () async {
      expect((await marker.markSeeded()).isOk, isTrue);
      expect((await marker.isSeeded()).valueOrNull, isTrue);
    });

    test('marking twice is not an error', () async {
      expect((await marker.markSeeded()).isOk, isTrue);
      expect((await marker.markSeeded()).isOk, isTrue);
      expect((await marker.isSeeded()).valueOrNull, isTrue);
    });

    test('clearing makes it unseeded again', () async {
      await marker.markSeeded();
      expect((await marker.clear()).isOk, isTrue);
      expect((await marker.isSeeded()).valueOrNull, isFalse);
    });

    test('it is not reachable through the typed preference accessor', () async {
      await marker.markSeeded();
      final store = PreferencesStore(db);
      for (final key in PreferenceKey.values) {
        expect(
          (await store.readBool(key)).valueOrNull,
          isNull,
          reason: '${key.name} can see the marker',
        );
      }
      expect(
        PreferenceKey.values.map((k) => k.storedName),
        isNot(contains(DemoSeedMarker.key)),
      );
    });

    test('a value that is not the marker reads as unseeded', () async {
      // Someone else's row under the same key must not read as "seeded".
      await db.insert(PreferencesStore.table, {
        'key': DemoSeedMarker.key,
        'value': 'something else',
      });
      expect((await marker.isSeeded()).valueOrNull, isFalse);
    });

    test('a broken database is a failure, not false', () async {
      await db.execute('DROP TABLE ${PreferencesStore.table}');
      final seeded = await marker.isSeeded();
      expect(seeded.isOk, isFalse);
      expect((await marker.markSeeded()).isOk, isFalse);
    });
  });

  group('seedOnce', () {
    test('seeds when unmarked, and marks afterwards', () async {
      final data = dataset();
      final result = await seeder.seedOnce(marker: marker, dataset: data);

      expect(result.isOk, isTrue);
      expect(
        result.valueOrNull,
        data.transactions.length + data.budgets.length,
      );
      expect((await marker.isSeeded()).valueOrNull, isTrue);
    });

    test('does nothing the second time, and reports zero', () async {
      final data = dataset();
      await seeder.seedOnce(marker: marker, dataset: data);

      final again = await seeder.seedOnce(marker: marker, dataset: data);
      expect(again.isOk, isTrue);
      expect(
        again.valueOrNull,
        0,
        reason: 'zero is how the caller tells "already done" from "did it"',
      );

      final listed = await seeder.transactions.list(TransactionQuery.all);
      expect(listed.valueOrNull, hasLength(data.transactions.length));
    });

    test('a failed seed is NOT marked, so it is retried', () async {
      // The whole reason the marker exists rather than a row count. A seed
      // that fails after its first record leaves rows behind; a count would
      // see them and never try again.
      final data = dataset();
      final failing = DemoSeeder(
        transactions: _FailAfter(
          inner: seeder.transactions,
          failAfter: 3,
        ),
        budgets: seeder.budgets,
      );

      expect(
        (await failing.seedOnce(marker: marker, dataset: data)).isOk,
        isFalse,
      );
      expect(
        (await marker.isSeeded()).valueOrNull,
        isFalse,
        reason: 'a partial ledger must not be recorded as complete',
      );
      expect(
        (await seeder.transactions.list(TransactionQuery.all)).valueOrNull,
        hasLength(3),
        reason: 'rows really were left behind, which is why a count is wrong',
      );
    });

    test('the retry after a failure is refused by the duplicate ids', () async {
      // Honest about what actually happens: the leftover rows collide, so the
      // retry fails too rather than silently producing a doubled ledger. The
      // caller's answer is reset, which deletes the file. Recorded because a
      // reader would otherwise assume "retried" means "recovers".
      final data = dataset();
      final failing = DemoSeeder(
        transactions: _FailAfter(inner: seeder.transactions, failAfter: 3),
        budgets: seeder.budgets,
      );
      await failing.seedOnce(marker: marker, dataset: data);

      final retry = await seeder.seedOnce(marker: marker, dataset: data);
      expect(retry.isOk, isFalse);
      expect((await marker.isSeeded()).valueOrNull, isFalse);
    });
  });
}

class _FailAfter implements TransactionRepository {
  _FailAfter({required this.inner, required this.failAfter});

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
