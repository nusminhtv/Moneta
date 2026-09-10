import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// The capability's first requirement, tested as a whole rather than per unit.
///
/// This is task 1.4 rather than the last task on purpose: "demo data and real
/// data are never mixed" is the promise the whole change rests on, so it gates
/// the work instead of closing it.
///
/// Plain `test`, never `testWidgets` — these bodies await real database I/O,
/// which never completes inside a `FakeAsync` zone.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_ledgers');
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
  });

  String pathIn(String name) => p.join(temporaryDirectory.path, name);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        realDatabasePathProvider.overrideWithValue(pathIn('moneta.db')),
        demoDatabasePathProvider.overrideWithValue(pathIn('moneta_demo.db')),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Transaction transactionNamed(String id, int minorUnits) => Transaction.create(
    id: id,
    amount: Money(minorUnits, Currency.vnd),
    direction: TransactionDirection.expense,
    category: SpendCategory.food,
    occurredAt: DateTime.utc(2026, 8, 14, 9),
    createdAt: DateTime.utc(2026, 8, 14, 9),
    note: id,
  ).valueOrNull!;

  Future<TransactionRepository> repositoryIn(ProviderContainer c) =>
      c.read(transactionRepositoryProvider.future);

  /// Every field of every row, so "unchanged" means unchanged and not merely
  /// "the same number of rows".
  Future<List<String>> ledgerOf(ProviderContainer c) async {
    final repository = await repositoryIn(c);
    final listed = await repository.list(TransactionQuery.all);
    String fingerprint(Transaction t) =>
        '${t.id}|${t.amount.minorUnits}|${t.direction.name}|'
        '${t.category.name}|${t.occurredAt.toIso8601String()}|${t.note}';
    return [for (final t in listed.valueOrNull!) fingerprint(t)];
  }

  test('the real ledger is untouched by everything demo mode does', () async {
    final container = makeContainer();

    // A real ledger with real money in it.
    final real = await repositoryIn(container);
    expect((await real.add(transactionNamed('real-1', 250000))).isOk, isTrue);
    expect((await real.add(transactionNamed('real-2', 780000))).isOk, isTrue);
    final before = await ledgerOf(container);
    expect(before, hasLength(2));

    // Into demo mode.
    container.read(demoModeProvider.notifier).active = true;
    expect(
      container.read(activeDatabaseProvider).path,
      pathIn('moneta_demo.db'),
    );

    // The demo ledger starts empty — it is a different file, not a filtered
    // view of the same one.
    final demo = await repositoryIn(container);
    expect(
      await ledgerOf(container),
      isEmpty,
      reason: 'a filtered single database would still show the real rows here',
    );

    // Seed it, mutate it, delete from it: everything a user can do.
    for (var i = 0; i < 12; i++) {
      expect(
        (await demo.add(transactionNamed('demo-$i', 10000 + i))).isOk,
        isTrue,
      );
    }
    expect((await demo.delete('demo-3')).isOk, isTrue);
    expect(await ledgerOf(container), hasLength(11));

    // Back out.
    container.read(demoModeProvider.notifier).active = false;
    expect(container.read(activeDatabaseProvider).path, pathIn('moneta.db'));

    // Row for row, field for field.
    expect(
      await ledgerOf(container),
      before,
      reason: 'the real ledger changed while demo mode was active',
    );
  });

  test('and demo work does not survive into the real ledger file', () async {
    final container = makeContainer();
    container.read(demoModeProvider.notifier).active = true;
    final demo = await repositoryIn(container);
    expect((await demo.add(transactionNamed('demo-only', 99000))).isOk, isTrue);

    container.read(demoModeProvider.notifier).active = false;

    // Nothing opened the real ledger at all, so its file does not exist. That
    // is a stronger result than "it has no rows", and it is what the first
    // draft of this test discovered by failing: a raw open created an empty
    // file with no schema and the query died on `no such table`.
    expect(
      File(pathIn('moneta.db')).existsSync(),
      isFalse,
      reason: 'demo mode created the real ledger file',
    );

    // And when it IS opened — migrations and all, the way the app would — it is
    // an empty ledger rather than one holding demo rows. Asserted through
    // AppDatabase rather than a raw open, so the schema exists and "no rows" is
    // a real answer instead of a missing table.
    final real = AppDatabase(
      path: pathIn('moneta.db'),
      factory: databaseFactoryFfi,
    );
    addTearDown(real.close);
    final opened = await real.open();
    final rows = await opened.valueOrNull!.query('transactions');
    expect(rows, isEmpty);
  });

  test('a real write while demo mode is off reaches the real file', () async {
    // The inverse. Without this, a provider that always pointed at the demo
    // file would pass every assertion above.
    final container = makeContainer();
    final real = await repositoryIn(container);
    expect((await real.add(transactionNamed('real-only', 5000))).isOk, isTrue);

    final db = await databaseFactoryFfi.openDatabase(pathIn('moneta.db'));
    final rows = await db.query('transactions');
    await db.close();
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'real-only');
  });
}
