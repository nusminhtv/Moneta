import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';

/// Covers the value types themselves.
///
/// `features/home/domain` is in `tool/coverage_critical.txt` at 85%, and the
/// provider tests exercise these types only incidentally — equality and `props`
/// are never reached by building a snapshot and reading it back.
void main() {
  const vnd = Currency.vnd;
  final at = DateTime.utc(2026, 8, 20, 9, 24);

  RecentEntry entry({
    String id = 'a',
    String title = 'Highlands Coffee',
    int minor = 45000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? occurredAt,
  }) => RecentEntry(
    id: id,
    title: title,
    amount: Money(minor, vnd),
    direction: direction,
    category: category,
    occurredAt: occurredAt ?? at,
  );

  group('RecentEntry', () {
    test('two entries with the same content are equal', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
    });

    test('every field participates in equality', () {
      // One assertion per field, so a field dropped from `props` is caught. A
      // single "different id" check would leave the other five unguarded.
      expect(entry(), isNot(entry(id: 'b')));
      expect(entry(), isNot(entry(title: 'Grab')));
      expect(entry(), isNot(entry(minor: 1)));
      expect(
        entry(),
        isNot(entry(direction: TransactionDirection.income)),
      );
      expect(entry(), isNot(entry(category: SpendCategory.salary)));
      expect(
        entry(),
        isNot(entry(occurredAt: DateTime.utc(2026, 8, 21))),
      );
    });

    test('the amount is a positive magnitude; direction carries the sign', () {
      final expense = entry();
      final income = entry(direction: TransactionDirection.income);
      expect(expense.amount.isNegative, isFalse);
      expect(income.amount, expense.amount);
      expect(income.direction, isNot(expense.direction));
    });
  });

  group('HomeSnapshot', () {
    HomeSnapshot snapshot({
      int balance = 100,
      int income = 200,
      int expenses = 100,
      List<RecentEntry>? recent,
      int safeToSpend = 100,
      List<BudgetSummary> budgets = const [],
    }) => HomeSnapshot(
      totalBalance: Money(balance, vnd),
      income: Money(income, vnd),
      expenses: Money(expenses, vnd),
      recent: recent ?? [entry()],
      safeToSpend: Money(safeToSpend, vnd),
      budgets: budgets,
    );

    test('every field participates in equality', () {
      expect(snapshot(), snapshot());
      expect(snapshot(), isNot(snapshot(balance: 999)));
      expect(snapshot(), isNot(snapshot(income: 999)));
      expect(snapshot(), isNot(snapshot(expenses: 999)));
      expect(snapshot(), isNot(snapshot(recent: [])));
    });

    test('empty is zero in the given currency and reports itself empty', () {
      final empty = HomeSnapshot.empty(vnd);
      expect(empty.totalBalance, const Money.zero(vnd));
      expect(empty.income, const Money.zero(vnd));
      expect(empty.expenses, const Money.zero(vnd));
      expect(empty.recent, isEmpty);
      expect(empty.isEmpty, isTrue);
    });

    test('empty respects the currency it is given', () {
      expect(
        HomeSnapshot.empty(Currency.usd).totalBalance.currency,
        Currency.usd,
      );
    });

    test('a snapshot with entries is not empty, even at a zero balance', () {
      // Emptiness is about the list, not the money: a wallet whose income and
      // expenses cancel out still has transactions to show.
      final zeroed = snapshot(balance: 0, income: 100, expenses: 100);
      expect(zeroed.totalBalance, const Money.zero(vnd));
      expect(zeroed.isEmpty, isFalse);
    });
  });

  group('BudgetSummary', () {
    BudgetSummary summary({
      int spent = 0,
      int limit = 5000000,
      double threshold = 0.8,
      SpendCategory category = SpendCategory.food,
    }) => BudgetSummary(
      id: 'b-${category.name}',
      category: category,
      spent: Money(spent, vnd),
      limit: Money(limit, vnd),
      note: 'note',
      alertThreshold: threshold,
    );

    test('remaining is the unspent part of the limit', () {
      expect(
        summary(limit: 5000000, spent: 2000000).remaining,
        const Money(3000000, vnd),
      );
    });

    test('remaining clamps at zero when overspent', () {
      // Unclamped this would be negative and would *raise* safe-to-spend.
      expect(
        summary(limit: 5000000, spent: 7000000).remaining,
        const Money.zero(vnd),
      );
    });

    test('remaining is the whole limit when nothing is spent', () {
      expect(summary(limit: 5000000).remaining, const Money(5000000, vnd));
    });

    test('under the threshold reads as on track', () {
      expect(summary(limit: 1000, spent: 500).status, BudgetStatus.onTrack);
      expect(summary(limit: 1000, spent: 500).isOver, isFalse);
    });

    test('at the limit is near it, not over it', () {
      // The project rule: exactly 1.0 is the limit reached, not exceeded.
      expect(summary(limit: 1000, spent: 1000).status, BudgetStatus.nearLimit);
      expect(summary(limit: 1000, spent: 1000).isOver, isFalse);
    });

    test('past the limit is over', () {
      expect(summary(limit: 1000, spent: 1001).status, BudgetStatus.over);
      expect(summary(limit: 1000, spent: 1001).isOver, isTrue);
    });

    test('the status honours the budget own threshold, not the default', () {
      // 60% is on track at the default 80% and near-limit at 50%.
      expect(
        summary(limit: 1000, spent: 600, threshold: 0.8).status,
        BudgetStatus.onTrack,
      );
      expect(
        summary(limit: 1000, spent: 600, threshold: 0.5).status,
        BudgetStatus.nearLimit,
      );
    });

    test('a zero limit with spend against it is over', () {
      expect(summary(limit: 0, spent: 1).status, BudgetStatus.over);
    });

    test('every field participates in equality', () {
      expect(summary(), summary());
      expect(
        summary(),
        isNot(
          const BudgetSummary(
            id: 'other',
            category: SpendCategory.food,
            spent: Money.zero(vnd),
            limit: Money(5000000, vnd),
            note: 'note',
          ),
        ),
      );
      expect(summary(), isNot(summary(spent: 1)));
      expect(summary(), isNot(summary(limit: 1)));
      expect(summary(), isNot(summary(threshold: 0.5)));
      expect(summary(), isNot(summary(category: SpendCategory.transport)));
    });
  });

  group('HomeSnapshot over-budget reporting', () {
    BudgetSummary summary({
      required SpendCategory category,
      int spent = 0,
      int limit = 1000,
    }) => BudgetSummary(
      id: 'b-${category.name}',
      category: category,
      spent: Money(spent, vnd),
      limit: Money(limit, vnd),
      note: 'note',
    );

    HomeSnapshot withBudgets(List<BudgetSummary> budgets) => HomeSnapshot(
      totalBalance: const Money(100, vnd),
      income: const Money(200, vnd),
      expenses: const Money(100, vnd),
      recent: const [],
      safeToSpend: const Money(100, vnd),
      budgets: budgets,
    );

    test('no budgets is not over budget', () {
      expect(withBudgets(const []).hasOverBudget, isFalse);
      expect(withBudgets(const []).worstBudget, isNull);
    });

    test('all on track is not over budget', () {
      expect(
        withBudgets([
          summary(category: SpendCategory.food, spent: 100),
          summary(category: SpendCategory.transport, spent: 200),
        ]).hasOverBudget,
        isFalse,
      );
    });

    test('one budget over its limit is enough', () {
      // Annotation `57:612`: triggered when ANY active budget exceeds 100%.
      expect(
        withBudgets([
          summary(category: SpendCategory.food, spent: 100),
          summary(category: SpendCategory.transport, spent: 1001),
        ]).hasOverBudget,
        isTrue,
      );
    });

    test('a budget exactly at its limit does not trigger the alert', () {
      expect(
        withBudgets([
          summary(category: SpendCategory.food, spent: 1000),
        ]).hasOverBudget,
        isFalse,
      );
    });

    test('the worst budget is the head of the list, which arrives ranked', () {
      // The banner names only this one, however many are over.
      final snapshot = withBudgets([
        summary(category: SpendCategory.transport, spent: 3000),
        summary(category: SpendCategory.food, spent: 1500),
      ]);
      expect(snapshot.worstBudget?.category, SpendCategory.transport);
    });
  });
}
