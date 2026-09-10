import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// The one path by which the file separation is not enough on its own.
///
/// Deleting a transaction leaves a `PendingUndo` holding that record **in
/// memory** for five seconds, and undo restores it through the ordinary
/// repository. So: delete a demo transaction, leave demo mode inside the
/// window, press undo — and a demo record is written into the real ledger.
///
/// Plain `test`, never `testWidgets`: real database I/O never completes inside
/// a `FakeAsync` zone.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_undo');
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

  Transaction coffee(String id) => Transaction.create(
    id: id,
    amount: const Money(45000, Currency.vnd),
    direction: TransactionDirection.expense,
    category: SpendCategory.food,
    occurredAt: DateTime.utc(2026, 9, 2, 8),
    createdAt: DateTime.utc(2026, 9, 2, 8),
  ).valueOrNull!;

  TransactionListController controllerIn(ProviderContainer c) =>
      c.read(transactionListControllerProvider.notifier);

  Future<TransactionListState> stateIn(ProviderContainer c) =>
      c.read(transactionListControllerProvider.future);

  /// Rows in whichever ledger is active.
  ///
  /// Deliberately the container's own connection. Opening a second
  /// `AppDatabase` on the same path looks independent and is not: sqflite
  /// defaults to `singleInstance`, so it hands back the connection the app is
  /// already using, and closing it takes the app's connection down. That cost
  /// three failing tests before it was spotted.
  Future<int> activeRows(ProviderContainer c) async {
    final opened = await c.read(activeDatabaseProvider).open();
    final rows = await opened.valueOrNull!.query('transactions');
    return rows.length;
  }

  test('a pending undo does not survive leaving demo mode', () async {
    final container = makeContainer();
    container.read(demoModeProvider.notifier).active = true;
    await stateIn(container);

    final controller = controllerIn(container);
    expect((await controller.add(coffee('demo-coffee'))).isOk, isTrue);
    expect((await controller.delete(coffee('demo-coffee'))).isOk, isTrue);
    expect(
      (await stateIn(container)).pendingUndo,
      isNotNull,
      reason: 'the undo window must be open, or this test proves nothing',
    );

    // Out of demo mode, well inside the five-second window.
    container.read(demoModeProvider.notifier).active = false;
    final after = await stateIn(container);

    expect(
      after.pendingUndo,
      isNull,
      reason:
          'a demo record held in memory is one undo press away from the real '
          'ledger',
    );

    // And pressing undo anyway does nothing to the real ledger.
    expect((await controllerIn(container).undoDelete()).isOk, isFalse);
    expect(await activeRows(container), 0);
  });

  test('and does not survive entering demo mode either', () async {
    final container = makeContainer();
    await stateIn(container);

    final controller = controllerIn(container);
    expect((await controller.add(coffee('real-coffee'))).isOk, isTrue);
    expect((await controller.delete(coffee('real-coffee'))).isOk, isTrue);
    expect((await stateIn(container)).pendingUndo, isNotNull);

    container.read(demoModeProvider.notifier).active = true;
    expect((await stateIn(container)).pendingUndo, isNull);

    expect((await controllerIn(container).undoDelete()).isOk, isFalse);
    expect(await activeRows(container), 0);
  });

  test('a refresh inside one ledger keeps the undo window open', () async {
    // Guards the other half of the fix. `keepPendingUndo` defaults to true,
    // and a mutation hardcoding it to null passed both the tests above AND all
    // 172 tests in `test/features/transactions` — because `delete` refreshes
    // *before* it sets the pending undo, so no existing test ever refreshes
    // while one is open. Changing the filter within five seconds of a deletion
    // does exactly that.
    final container = makeContainer();
    await stateIn(container);
    final controller = controllerIn(container);

    expect((await controller.add(coffee('filtered'))).isOk, isTrue);
    expect((await controller.delete(coffee('filtered'))).isOk, isTrue);
    expect((await stateIn(container)).pendingUndo, isNotNull);

    await controller.refresh();
    expect(
      (await stateIn(container)).pendingUndo,
      isNotNull,
      reason:
          'reloading the list must not cancel a deletion the user can '
          'still undo',
    );

    await controller.applyFilter(TransactionQuery.all);
    expect((await stateIn(container)).pendingUndo, isNotNull);
  });

  test('undo still works when the ledger does not change', () async {
    // The inverse, and the reason this fix is not just "disable undo": the
    // feature has to keep working inside one ledger.
    final container = makeContainer();
    await stateIn(container);

    final controller = controllerIn(container);
    expect((await controller.add(coffee('keeper'))).isOk, isTrue);
    expect((await controller.delete(coffee('keeper'))).isOk, isTrue);
    expect(await activeRows(container), 0);

    expect((await controller.undoDelete()).isOk, isTrue);
    expect(await activeRows(container), 1);
    expect((await stateIn(container)).pendingUndo, isNull);
  });
}
