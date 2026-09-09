import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

/// Home and the Transactions tab must never disagree about what exists.
///
/// They did. Home read the repository through its own `FutureProvider` while the
/// list went through `TransactionListController`, so adding a transaction
/// updated one and not the other: the new row appeared in the Transactions tab
/// and Home kept the old balance until the app restarted. Two sources of truth
/// for the same data.
void main() {
  const vnd = Currency.vnd;

  Transaction tx(String id, int minor) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: TransactionDirection.expense,
    category: SpendCategory.food,
    occurredAt: DateTime.utc(2026, 8, 20, 10),
    createdAt: DateTime.utc(2026, 8, 20, 10),
    note: 'Row $id',
  ).valueOrNull!;

  Future<ProviderContainer> container(FakeTransactionRepository repo) async {
    final c = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) => repo),
        clockProvider.overrideWithValue(
          TickingClock(DateTime.utc(2026, 8, 20, 10)),
        ),
        // Home waits for budgets as well as transactions, so that safe-to-spend
        // is never painted as the bare balance and then corrected. These tests
        // are about Home and the list agreeing on the ledger; without this
        // override the budget read would reach for a real database and the
        // snapshot would stay loading forever.
        budgetListProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(c.dispose);
    // Home derives from the controller, so the controller has to have loaded.
    await c.read(transactionListControllerProvider.future);
    // ...and it now waits on budgets too, which must resolve before the
    // snapshot leaves its loading state.
    await c.read(budgetListProvider.future);
    return c;
  }

  test('a transaction added through the controller reaches Home', () async {
    final repo = FakeTransactionRepository();
    final c = await container(repo);

    expect(c.read(homeSnapshotProvider).value!.recent, isEmpty);

    await c
        .read(transactionListControllerProvider.notifier)
        .add(tx('a', 45000));

    final snapshot = c.read(homeSnapshotProvider).value!;
    expect(
      snapshot.recent.map((e) => e.id),
      ['a'],
      reason: 'Home did not see a transaction the Transactions tab has',
    );
    expect(snapshot.expenses, const Money(45000, vnd));
    expect(snapshot.totalBalance, const Money(-45000, vnd));
  });

  test('Home and the list agree on how many transactions exist', () async {
    final repo = FakeTransactionRepository();
    final c = await container(repo);
    final controller = c.read(transactionListControllerProvider.notifier);

    for (final id in ['a', 'b', 'c']) {
      await controller.add(tx(id, 1000));
    }

    final inList = [
      for (final day in c.read(transactionListControllerProvider).value!.days)
        ...day.transactions,
    ];
    final inHome = c.read(homeSnapshotProvider).value!;

    expect(inList, hasLength(3));
    expect(inHome.expenses, const Money(3000, vnd));
    expect(
      inHome.recent.map((e) => e.id).toSet(),
      inList.map((t) => t.id).toSet(),
      reason: 'the two views disagree about what exists',
    );
  });

  test('deleting a transaction removes it from Home too', () async {
    final repo = FakeTransactionRepository();
    final c = await container(repo);
    final controller = c.read(transactionListControllerProvider.notifier);

    final added = tx('a', 45000);
    await controller.add(added);
    expect(c.read(homeSnapshotProvider).value!.recent, hasLength(1));

    await controller.delete(added);

    expect(
      c.read(homeSnapshotProvider).value!.recent,
      isEmpty,
      reason: 'Home still shows a deleted transaction',
    );
  });
}
