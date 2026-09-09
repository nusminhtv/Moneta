import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

/// Budget spend is never stored, so editing the ledger must move it.
///
/// `specs/budgets/spec.md` requires that deleting a transaction inside a
/// budget's window drops the budget's spend on the next read, and that nothing
/// about the budget row changes. `tasks.md` restated it as a required test and
/// was ticked; no such test existed. It is the scenario that justifies the whole
/// "spend is derived, never written" decision.
void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 20, 3);

  Transaction tx(String id, int minor) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: TransactionDirection.expense,
    category: SpendCategory.food,
    occurredAt: DateTime.utc(2026, 9, 10, 3),
    createdAt: DateTime.utc(2026, 9, 10, 3),
  ).valueOrNull!;

  final theBudget = Budget.create(
    id: 'b-food',
    category: SpendCategory.food,
    limit: const Money(4000000, vnd),
    period: BudgetPeriod.monthly,
    startsOn: DateTime.utc(2026, 9),
    createdAt: DateTime.utc(2026, 9),
  ).valueOrNull!;

  Future<ProviderContainer> container(FakeTransactionRepository repo) async {
    final c = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) => repo),
        clockProvider.overrideWithValue(TickingClock(now)),
        budgetListProvider.overrideWith((ref) async => [theBudget]),
      ],
    );
    addTearDown(c.dispose);
    await c.read(transactionListControllerProvider.future);
    await c.read(budgetListProvider.future);
    return c;
  }

  test(
    'deleting a transaction drops the budget spend on the next read',
    () async {
      final repo = FakeTransactionRepository(
        initial: [tx('a', 1000000), tx('b', 500000)],
      );
      final c = await container(repo);

      expect(
        c.read(budgetProgressProvider).value!.single.spent,
        const Money(1500000, vnd),
      );

      await c
          .read(transactionListControllerProvider.notifier)
          .delete(tx('b', 500000));

      expect(
        c.read(budgetProgressProvider).value!.single.spent,
        const Money(1000000, vnd),
      );
    },
  );

  test('and nothing about the budget itself changed', () async {
    final repo = FakeTransactionRepository(initial: [tx('a', 1000000)]);
    final c = await container(repo);
    final before = c.read(budgetProgressProvider).value!.single.budget;

    await c
        .read(transactionListControllerProvider.notifier)
        .delete(tx('a', 1000000));

    final after = c.read(budgetProgressProvider).value!.single.budget;
    expect(after, before);
    expect(after.limit, const Money(4000000, vnd));
    expect(
      c.read(budgetProgressProvider).value!.single.spent,
      const Money(0, vnd),
    );
  });

  test('adding a transaction raises it again', () async {
    final repo = FakeTransactionRepository(initial: [tx('a', 1000000)]);
    final c = await container(repo);

    await c
        .read(transactionListControllerProvider.notifier)
        .add(tx('c', 250000));

    expect(
      c.read(budgetProgressProvider).value!.single.spent,
      const Money(1250000, vnd),
    );
  });

  test(
    'deleting the transaction that tipped it clears the over state',
    () async {
      // The status is derived too, so it must fall back with the spend.
      final repo = FakeTransactionRepository(
        initial: [tx('a', 3500000), tx('b', 1000000)],
      );
      final c = await container(repo);
      expect(
        c.read(budgetProgressProvider).value!.single.status,
        BudgetStatus.over,
      );

      await c
          .read(transactionListControllerProvider.notifier)
          .delete(tx('b', 500000));

      final after = c.read(budgetProgressProvider).value!.single;
      expect(after.status, isNot(BudgetStatus.over));
      expect(after.passedLimitOn, isNull);
      expect(after.overBy, const Money(0, vnd));
    },
  );
}
