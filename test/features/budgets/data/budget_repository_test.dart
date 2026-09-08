import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/database/migrations.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/data/sqlite_budget_repository.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  const vnd = Currency.vnd;

  late Database db;
  late SqliteBudgetRepository repository;

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, v) => runMigrations(db, from: 0, to: v),
        onUpgrade: (db, from, to) => runMigrations(db, from: from, to: to),
      ),
    );
    repository = SqliteBudgetRepository(BudgetDao(db));
  });

  tearDown(() => db.close());

  Budget budget({
    String id = 'b1',
    SpendCategory category = SpendCategory.food,
    Money limit = const Money(4000000, vnd),
    BudgetPeriod period = BudgetPeriod.monthly,
    bool rollsOver = false,
    double threshold = 0.8,
  }) => Budget.create(
    id: id,
    category: category,
    limit: limit,
    period: period,
    startsOn: DateTime.utc(2026, 9),
    createdAt: DateTime.utc(2026, 8, 30, 7, 45),
    rollsOver: rollsOver,
    alertThreshold: threshold,
  ).valueOrNull!;

  group('round trip', () {
    test('every field survives storage unchanged', () async {
      final original = budget(rollsOver: true, threshold: 0.65);
      expect(await repository.add(original), isA<Ok<void>>());

      final read = (await repository.byId('b1') as Ok<Budget>).value;
      expect(read, original);
      expect(read.rollsOver, isTrue);
      expect(read.alertThreshold, 0.65);
      expect(read.startsOn.isUtc, isTrue);
      expect(read.createdAt, DateTime.utc(2026, 8, 30, 7, 45));
    });

    test('the boolean survives the integer column', () async {
      // SQLite has no boolean; 0/1 conversion is the kind of thing that reads
      // back as `true` for everything if the mapping is wrong in one direction.
      await repository.add(budget(id: 'on', rollsOver: true));
      await repository.add(
        budget(id: 'off', category: SpendCategory.bills, rollsOver: false),
      );
      final list = (await repository.list() as Ok<List<Budget>>).value;
      expect(
        {for (final b in list) b.id: b.rollsOver},
        {'on': true, 'off': false},
      );
    });

    test('the threshold survives as a real, not an integer', () async {
      await repository.add(budget(threshold: 0.65));
      final read = (await repository.byId('b1') as Ok<Budget>).value;
      expect(read.alertThreshold, 0.65);
    });

    test('every period round-trips', () async {
      for (final period in BudgetPeriod.values) {
        await repository.add(
          budget(id: period.name, period: period),
        );
      }
      final list = (await repository.list() as Ok<List<Budget>>).value;
      expect(
        list.map((b) => b.period).toSet(),
        BudgetPeriod.values.toSet(),
      );
    });
  });

  group('duplicates', () {
    test(
      'a second budget for the same category and period is refused',
      () async {
        await repository.add(budget());
        final second = await repository.add(budget(id: 'b2'));

        expect(second, isA<Err<void>>());
        final failure = (second as Err<void>).failure;
        expect(failure.kind, FailureKind.validation);
        expect(failure.message, contains(SpendCategory.food.label));
        expect(failure.message, contains('split the same spend'));
      },
    );

    test('the same category with a different period is allowed', () async {
      await repository.add(budget());
      expect(
        await repository.add(budget(id: 'b2', period: BudgetPeriod.weekly)),
        isA<Ok<void>>(),
      );
    });

    test('the unique index holds even past the repository check', () async {
      // The read-then-write in `add` is a race between two concurrent writes.
      // The index is what actually prevents two budgets over one category, so
      // it is asserted directly.
      await repository.add(budget());
      expect(
        () => BudgetDao(db).insert(budget(id: 'b2')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('exists reports both ways', () async {
      expect(
        (await repository.exists(
                  category: SpendCategory.food,
                  period: BudgetPeriod.monthly,
                )
                as Ok<bool>)
            .value,
        isFalse,
      );
      await repository.add(budget());
      expect(
        (await repository.exists(
                  category: SpendCategory.food,
                  period: BudgetPeriod.monthly,
                )
                as Ok<bool>)
            .value,
        isTrue,
      );
    });
  });

  group('update and remove', () {
    test('update replaces the stored values', () async {
      await repository.add(budget());
      final edited = budget().copyWith(
        limit: const Money(5000000, vnd),
        alertThreshold: 0.5,
      );
      expect(await repository.update(edited), isA<Ok<void>>());

      final read = (await repository.byId('b1') as Ok<Budget>).value;
      expect(read.limit, const Money(5000000, vnd));
      expect(read.alertThreshold, 0.5);
    });

    test('updating a budget that is not there is notFound', () async {
      final result = await repository.update(budget());
      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure.kind, FailureKind.notFound);
    });

    test('remove deletes it', () async {
      await repository.add(budget());
      expect(await repository.remove('b1'), isA<Ok<void>>());
      expect(
        (await repository.list() as Ok<List<Budget>>).value,
        isEmpty,
      );
    });

    test('removing one that is not there is not an error', () async {
      // The caller wanted it gone and it is gone.
      expect(await repository.remove('nope'), isA<Ok<void>>());
    });

    test('reading a budget that is not there is notFound', () async {
      final result = await repository.byId('nope');
      expect(result, isA<Err<Budget>>());
      expect((result as Err<Budget>).failure.kind, FailureKind.notFound);
    });
  });

  group('storage failures become Result, not exceptions', () {
    test('reading a dropped table is a storage failure', () async {
      await db.execute('DROP TABLE budgets');

      for (final result in [
        await repository.list(),
        await repository.byId('b1'),
        await repository.add(budget()),
        await repository.update(budget()),
        await repository.remove('b1'),
        await repository.exists(
          category: SpendCategory.food,
          period: BudgetPeriod.monthly,
        ),
      ]) {
        expect(result, isA<Err<Object?>>());
        expect(
          (result as Err<Object?>).failure.kind,
          FailureKind.storage,
        );
      }
    });
  });

  group('an empty first-run database', () {
    test('lists nothing rather than failing', () async {
      expect((await repository.list() as Ok<List<Budget>>).value, isEmpty);
    });
  });
}
