import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/features/insights/domain/insights_entry.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';

void main() {
  const vnd = Currency.vnd;

  InsightsEntry entry({
    String id = 'a',
    String title = 'Coffee',
    SpendCategory category = SpendCategory.food,
    TransactionDirection direction = TransactionDirection.expense,
    int minor = 45000,
    DateTime? at,
  }) => InsightsEntry(
    id: id,
    title: title,
    category: category,
    direction: direction,
    amount: Money(minor, vnd),
    occurredAt: at ?? DateTime.utc(2026, 9, 2, 8),
  );

  group('InsightsEntry', () {
    test('equality is by value, across every field', () {
      expect(entry(), entry());
      expect(entry(), isNot(entry(id: 'b')));
      expect(entry(), isNot(entry(title: 'Tea')));
      expect(entry(), isNot(entry(category: SpendCategory.transport)));
      expect(
        entry(),
        isNot(entry(direction: TransactionDirection.income)),
      );
      expect(entry(), isNot(entry(minor: 46000)));
      expect(entry(), isNot(entry(at: DateTime.utc(2026, 9, 3))));
    });

    test('isExpense reads the direction, both ways', () {
      expect(entry().isExpense, isTrue);
      expect(
        entry(direction: TransactionDirection.income).isExpense,
        isFalse,
      );
    });
  });

  group('CategorySpend and MonthlyFlow', () {
    test('CategorySpend equality is by value', () {
      const a = CategorySpend(
        category: SpendCategory.food,
        amount: Money(1000, vnd),
      );
      expect(
        a,
        const CategorySpend(
          category: SpendCategory.food,
          amount: Money(1000, vnd),
        ),
      );
      expect(
        a,
        isNot(
          const CategorySpend(
            category: SpendCategory.bills,
            amount: Money(1000, vnd),
          ),
        ),
      );
    });

    test('MonthlyFlow net is income less expenses, either sign', () {
      final positive = MonthlyFlow(
        month: DateTime.utc(2026, 9),
        income: const Money(3000, vnd),
        expenses: const Money(1000, vnd),
      );
      expect(positive.net, const Money(2000, vnd));

      final negative = MonthlyFlow(
        month: DateTime.utc(2026, 9),
        income: const Money(1000, vnd),
        expenses: const Money(3000, vnd),
      );
      expect(negative.net, const Money(-2000, vnd));
      expect(negative.net.isNegative, isTrue);
    });

    test('MonthlyFlow equality is by value', () {
      final a = MonthlyFlow(
        month: DateTime.utc(2026, 9),
        income: const Money(1, vnd),
        expenses: const Money(2, vnd),
      );
      expect(
        a,
        MonthlyFlow(
          month: DateTime.utc(2026, 9),
          income: const Money(1, vnd),
          expenses: const Money(2, vnd),
        ),
      );
      expect(
        a,
        isNot(
          MonthlyFlow(
            month: DateTime.utc(2026, 8),
            income: const Money(1, vnd),
            expenses: const Money(2, vnd),
          ),
        ),
      );
    });
  });

  group('InsightsWindow and summary identity', () {
    test('a window prints its bounds, for a failure message worth reading', () {
      final window = InsightsPeriod.thisMonth.windowAt(
        DateTime.utc(2026, 9, 17),
      );
      expect(window.toString(), contains('2026-09-01'));
    });

    test('two summaries of the same data are equal', () {
      final entries = [entry(), entry(id: 'b', minor: 99000)];
      InsightsSummary summarise() => InsightsSummary.of(
        entries: entries,
        period: InsightsPeriod.thisMonth,
        now: DateTime.utc(2026, 9, 17),
        currency: vnd,
      );
      expect(summarise(), summarise());
    });

    test('summaries of different periods are not equal', () {
      final entries = [entry()];
      InsightsSummary summarise(InsightsPeriod period) => InsightsSummary.of(
        entries: entries,
        period: period,
        now: DateTime.utc(2026, 9, 17),
        currency: vnd,
      );
      expect(
        summarise(InsightsPeriod.thisMonth),
        isNot(summarise(InsightsPeriod.year)),
      );
    });

    test('every period declares a label, a long label and a month count', () {
      for (final period in InsightsPeriod.values) {
        expect(period.label, isNotEmpty);
        expect(period.longLabel, isNotEmpty);
        expect(period.months, greaterThan(0));
      }
      expect(
        InsightsPeriod.values.map((p) => p.months).toList(),
        [1, 3, 6, 12],
      );
      expect(
        InsightsPeriod.values.map((p) => p.label).toSet(),
        hasLength(InsightsPeriod.values.length),
        reason: 'two periods sharing a label would make the switcher ambiguous',
      );
    });

    test('barFractionOf is zero when there is nothing to compare', () {
      final empty = InsightsSummary.of(
        entries: const [],
        period: InsightsPeriod.thisMonth,
        now: DateTime.utc(2026, 9, 17),
        currency: vnd,
      );
      expect(
        empty.barFractionOf(
          const CategorySpend(
            category: SpendCategory.food,
            amount: Money(1000, vnd),
          ),
        ),
        0.0,
      );
    });
  });
}
