import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

/// Real budgets travelling through `homeSnapshotProvider`.
///
/// This path had no test at all, which is how a display cap reached the money
/// arithmetic: `budgets` was `ranked.take(homeBudgetLimit)`, and because
/// `compareWorstFirst` ranks by fraction used **descending**, the budgets it
/// dropped were the least spent — the ones holding the largest unspent
/// commitments. Safe-to-spend was therefore always overstated, and the error
/// grew with every budget the user added.
void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 20, 3);

  Budget budget({
    required String id,
    required SpendCategory category,
    int limit = 5000000,
  }) => Budget.create(
    id: id,
    category: category,
    limit: Money(limit, vnd),
    period: BudgetPeriod.monthly,
    startsOn: DateTime.utc(2026, 9),
    createdAt: DateTime.utc(2026, 9),
  ).valueOrNull!;

  Transaction spend({
    required String id,
    required SpendCategory category,
    required int minor,
  }) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: TransactionDirection.expense,
    category: category,
    occurredAt: DateTime.utc(2026, 9, 10, 3),
    createdAt: DateTime.utc(2026, 9, 10, 3),
  ).valueOrNull!;

  /// Four 5,000,000 ₫ budgets: food 90% spent, transport 80%, shopping and
  /// bills untouched. Worst-first ranking puts the untouched pair last, so
  /// *any* cap drops budgets whose commitment is still entirely outstanding.
  ///
  /// Four rather than three on purpose. With exactly three, `take(3)` inside
  /// `safeToSpend` passed the whole suite — the guard only caught the cap that
  /// happened to ship.
  Future<ProviderContainer> container() async {
    final repository = FakeTransactionRepository(
      initial: [
        spend(id: 't1', category: SpendCategory.food, minor: 4500000),
        spend(id: 't2', category: SpendCategory.transport, minor: 4000000),
      ],
    );
    final c = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) => repository),
        clockProvider.overrideWithValue(TickingClock(now)),
        budgetListProvider.overrideWith(
          (ref) async => [
            budget(id: 'b-food', category: SpendCategory.food),
            budget(id: 'b-transport', category: SpendCategory.transport),
            budget(id: 'b-shopping', category: SpendCategory.shopping),
            budget(id: 'b-bills', category: SpendCategory.bills),
          ],
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(transactionListControllerProvider.future);
    await c.read(budgetListProvider.future);
    return c;
  }

  test('every budget reaches the snapshot, not just the ones Home draws', () {
    // The cap belongs to HomeScreen now. The snapshot carries the truth.
    return container().then((c) {
      final snapshot = c.read(homeSnapshotProvider).value!;
      expect(snapshot.budgets, hasLength(4));
    });
  });

  test('safe to spend counts the budget that ranks last', () async {
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;

    // balance = -8,500,000 (two expenses, no income)
    // remainders = 500,000 + 1,000,000 + 5,000,000 + 5,000,000 = 11,500,000
    expect(snapshot.totalBalance, const Money(-8500000, vnd));
    expect(snapshot.safeToSpend, const Money(-20000000, vnd));
  });

  test('no cap of any size gives the right answer', () async {
    // Written as a loop rather than against one magic number. A fixture of
    // exactly three budgets let `take(3)` pass the whole suite, which is the
    // same shape of hole as the bug: a guard calibrated to the cap that
    // shipped.
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;

    final all = safeToSpend(
      balance: snapshot.totalBalance,
      budgets: snapshot.budgets,
    );
    expect(snapshot.safeToSpend, all);

    for (var cap = 1; cap < snapshot.budgets.length; cap++) {
      final capped = safeToSpend(
        balance: snapshot.totalBalance,
        budgets: snapshot.budgets.take(cap).toList(),
      );
      expect(
        capped.minorUnits,
        greaterThan(all.minorUnits),
        reason: 'a cap of $cap made safe-to-spend look better than it is',
      );
    }
  });

  test('budgets arrive worst first', () async {
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;
    expect(snapshot.budgets.take(2).map((b) => b.category), [
      SpendCategory.food,
      SpendCategory.transport,
    ]);
    // The untouched pair tie at 0%, so only their position after the spent
    // ones is guaranteed.
    expect(
      snapshot.budgets.skip(2).map((b) => b.category),
      containsAll([SpendCategory.shopping, SpendCategory.bills]),
    );
  });

  test('the untouched budget keeps its whole limit as remainder', () async {
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;
    final shopping = snapshot.budgets.last;
    expect(shopping.spent, const Money(0, vnd));
    expect(shopping.remaining, const Money(5000000, vnd));
    expect(shopping.isOver, isFalse);
  });

  test(
    'toBudgetSummary carries the id, so a card can open its own detail',
    () async {
      final c = await container();
      final snapshot = c.read(homeSnapshotProvider).value!;
      expect(
        snapshot.budgets.map((b) => b.id),
        containsAll(['b-food', 'b-transport', 'b-shopping']),
      );
    },
  );

  test('the note is the same sentence the Budgets screen builds', () async {
    // Reused rather than reformatted, so one budget cannot describe itself
    // differently on two screens.
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;
    expect(snapshot.budgets.first.note, contains('% used'));
    expect(snapshot.budgets.first.note, contains('days left'));
  });

  test('the limit is the effective limit, so status matches Budgets', () async {
    final c = await container();
    final snapshot = c.read(homeSnapshotProvider).value!;
    // No rollover here, so effective == limit; the point is that the mapping
    // reads effectiveLimit rather than budget.limit.
    expect(snapshot.budgets.first.limit, const Money(5000000, vnd));
  });

  test('an over-limit budget sets hasOverBudget on the real graph', () async {
    final repository = FakeTransactionRepository(
      initial: [
        spend(id: 't1', category: SpendCategory.food, minor: 6000000),
      ],
    );
    final c = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) => repository),
        clockProvider.overrideWithValue(TickingClock(now)),
        budgetListProvider.overrideWith(
          (ref) async => [budget(id: 'b-food', category: SpendCategory.food)],
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(transactionListControllerProvider.future);
    await c.read(budgetListProvider.future);

    final snapshot = c.read(homeSnapshotProvider).value!;
    expect(snapshot.hasOverBudget, isTrue);
    expect(snapshot.worstBudget?.category, SpendCategory.food);
    expect(snapshot.worstBudget?.overBy, const Money(1000000, vnd));
  });
}
