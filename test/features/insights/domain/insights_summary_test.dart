import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/features/insights/domain/insights_entry.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';

void main() {
  const vnd = Currency.vnd;
  // Mid-month, so "the month in progress" is genuinely in progress and an
  // off-by-one at either boundary shows up.
  final now = DateTime.utc(2026, 9, 17, 14, 30);

  InsightsEntry expense(
    String id,
    int minor,
    SpendCategory category,
    DateTime at, {
    String? title,
  }) => InsightsEntry(
    id: id,
    title: title ?? category.label,
    category: category,
    direction: TransactionDirection.expense,
    amount: Money(minor, vnd),
    occurredAt: at,
  );

  InsightsEntry income(String id, int minor, DateTime at) => InsightsEntry(
    id: id,
    title: 'Salary',
    category: SpendCategory.salary,
    direction: TransactionDirection.income,
    amount: Money(minor, vnd),
    occurredAt: at,
  );

  InsightsSummary summarise(
    List<InsightsEntry> entries, {
    InsightsPeriod period = InsightsPeriod.thisMonth,
    DateTime? at,
  }) => InsightsSummary.of(
    entries: entries,
    period: period,
    now: at ?? now,
    currency: vnd,
  );

  group('periods resolve to whole-month windows ending now', () {
    test('each period covers the months it names', () {
      expect(
        InsightsPeriod.thisMonth.windowAt(now).start,
        DateTime.utc(2026, 9),
      );
      expect(
        InsightsPeriod.threeMonths.windowAt(now).start,
        DateTime.utc(2026, 7),
      );
      expect(
        InsightsPeriod.sixMonths.windowAt(now).start,
        DateTime.utc(2026, 4),
      );
      expect(
        InsightsPeriod.year.windowAt(now).start,
        DateTime.utc(2025, 10),
      );
    });

    test('every window ends at the clock, not at the month end', () {
      for (final period in InsightsPeriod.values) {
        expect(period.windowAt(now).end, now, reason: period.name);
      }
    });

    test('a January clock crosses the year boundary', () {
      final january = DateTime.utc(2027, 1, 9, 10);
      expect(
        InsightsPeriod.threeMonths.windowAt(january).start,
        DateTime.utc(2026, 11),
      );
      expect(
        InsightsPeriod.year.windowAt(january).start,
        DateTime.utc(2026, 2),
      );
    });

    test('windows are UTC even from a local clock', () {
      final window = InsightsPeriod.thisMonth.windowAt(
        DateTime(2026, 9, 17, 14, 30),
      );
      expect(window.start.isUtc, isTrue);
      expect(window.end.isUtc, isTrue);
    });

    test('windowFrom reads an injected clock', () {
      expect(
        InsightsPeriod.thisMonth.windowFrom(FixedClock(now)).start,
        DateTime.utc(2026, 9),
      );
    });

    test('months lists one entry per calendar month, oldest first', () {
      expect(InsightsPeriod.thisMonth.windowAt(now).months, [
        DateTime.utc(2026, 9),
      ]);
      expect(InsightsPeriod.threeMonths.windowAt(now).months, [
        DateTime.utc(2026, 7),
        DateTime.utc(2026, 8),
        DateTime.utc(2026, 9),
      ]);
      expect(InsightsPeriod.year.windowAt(now).months, hasLength(12));
    });

    test('the window excludes what falls outside it', () {
      final window = InsightsPeriod.thisMonth.windowAt(now);
      expect(window.contains(DateTime.utc(2026, 9)), isTrue);
      expect(window.contains(DateTime.utc(2026, 9, 17, 14, 30)), isTrue);
      expect(window.contains(DateTime.utc(2026, 8, 31, 23, 59)), isFalse);
      expect(
        window.contains(DateTime.utc(2026, 9, 18)),
        isFalse,
        reason: 'the future is not in this period',
      );
    });
  });

  group('categories are ranked, and shares add up', () {
    test('largest first', () {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
        expense('b', 500000, SpendCategory.bills, DateTime.utc(2026, 9, 3)),
        expense('c', 300000, SpendCategory.transport, DateTime.utc(2026, 9, 4)),
      ]);

      expect(summary.byCategory.map((c) => c.category), [
        SpendCategory.bills,
        SpendCategory.transport,
        SpendCategory.food,
      ]);
    });

    test('same category in one period is one row', () {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
        expense('b', 250000, SpendCategory.food, DateTime.utc(2026, 9, 9)),
      ]);

      expect(summary.byCategory, hasLength(1));
      expect(summary.byCategory.single.amount, const Money(350000, vnd));
    });

    test('shares of total sum to one', () {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
        expense('b', 300000, SpendCategory.bills, DateTime.utc(2026, 9, 3)),
      ]);

      final shares = summary.byCategory.map(summary.shareOf).toList();
      expect(shares.reduce((a, b) => a + b), closeTo(1, 1e-12));
      expect(shares.first, closeTo(0.75, 1e-12));
    });

    test('bar fractions are of the LARGEST, not of the total', () {
      // The two numbers differ and 07.03 shows both: `77:587` carries rank by
      // length, so the top bar is full.
      final summary = summarise([
        expense('a', 400000, SpendCategory.bills, DateTime.utc(2026, 9, 3)),
        expense('b', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);

      expect(summary.barFractionOf(summary.byCategory.first), 1.0);
      expect(
        summary.barFractionOf(summary.byCategory.last),
        closeTo(0.25, 1e-12),
      );
      expect(
        summary.shareOf(summary.byCategory.first),
        closeTo(0.8, 1e-12),
        reason: 'share-of-total is the label; share-of-largest is the bar',
      );
    });

    test('income never appears as spending', () {
      final summary = summarise([
        income('i', 32000000, DateTime.utc(2026, 9, 5)),
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);

      expect(summary.byCategory, hasLength(1));
      expect(summary.byCategory.single.category, SpendCategory.food);
      expect(summary.totalIncome, const Money(32000000, vnd));
      expect(summary.totalExpenses, const Money(100000, vnd));
    });
  });

  group('the monthly series is aligned with the calendar', () {
    test('one point per month, oldest first, even when a month is silent', () {
      final summary = summarise(
        [
          expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 7, 4)),
          // Nothing at all in August.
          expense('c', 300000, SpendCategory.food, DateTime.utc(2026, 9, 4)),
        ],
        period: InsightsPeriod.threeMonths,
      );

      expect(summary.monthly, hasLength(3));
      expect(summary.monthly.map((m) => m.month), [
        DateTime.utc(2026, 7),
        DateTime.utc(2026, 8),
        DateTime.utc(2026, 9),
      ]);
      expect(
        summary.monthly[1].expenses,
        const Money.zero(vnd),
        reason:
            'skipping a silent month would shift every later point one place '
            'left and misalign the line with the calendar',
      );
      expect(summary.monthly[1].income, const Money.zero(vnd));
    });

    test('a transaction lands in its own month, not a neighbour', () {
      final summary = summarise(
        [
          expense(
            'edge',
            100000,
            SpendCategory.food,
            DateTime.utc(2026, 8, 31, 23, 59, 59),
          ),
        ],
        period: InsightsPeriod.threeMonths,
      );

      expect(summary.monthly[1].expenses, const Money(100000, vnd));
      expect(summary.monthly[2].expenses, const Money.zero(vnd));
    });

    test('net is income less expenses, and can be negative', () {
      final summary = summarise([
        income('i', 1000000, DateTime.utc(2026, 9, 5)),
        expense('a', 2500000, SpendCategory.bills, DateTime.utc(2026, 9, 6)),
      ]);

      expect(summary.net, const Money(-1500000, vnd));
      expect(summary.monthly.single.net, const Money(-1500000, vnd));
    });
  });

  group('top expenses', () {
    test('the three largest, largest first', () {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
        expense('b', 900000, SpendCategory.bills, DateTime.utc(2026, 9, 3)),
        expense('c', 300000, SpendCategory.transport, DateTime.utc(2026, 9, 4)),
        expense('d', 700000, SpendCategory.shopping, DateTime.utc(2026, 9, 5)),
      ]);

      expect(summary.topExpenses.map((e) => e.id), ['b', 'd', 'c']);
    });

    test('fewer than three is not padded', () {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);
      expect(summary.topExpenses, hasLength(1));
    });

    test('income is never a top expense, however large', () {
      final summary = summarise([
        income('i', 99000000, DateTime.utc(2026, 9, 5)),
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);
      expect(summary.topExpenses.map((e) => e.id), ['a']);
    });
  });

  group('boundaries', () {
    test('an empty ledger is empty, not an error', () {
      final summary = summarise([]);
      expect(summary.hasNoSpending, isTrue);
      expect(summary.byCategory, isEmpty);
      expect(summary.topExpenses, isEmpty);
      expect(summary.totalExpenses, const Money.zero(vnd));
      expect(summary.totalIncome, const Money.zero(vnd));
      expect(summary.monthly, hasLength(1));
      expect(summary.net, const Money.zero(vnd));
    });

    test('income with no expense still reads as no spending', () {
      // 77:291 requires an EmptyState rather than a 0% donut, and a period
      // holding only income has nothing for a spend chart to describe.
      final summary = summarise([
        income('i', 32000000, DateTime.utc(2026, 9, 5)),
      ]);
      expect(summary.hasNoSpending, isTrue);
      expect(summary.totalIncome, const Money(32000000, vnd));
    });

    test('one expense is 100% of its category and of the total', () {
      final summary = summarise([
        expense('a', 250000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);
      expect(summary.shareOf(summary.byCategory.single), 1.0);
      expect(summary.barFractionOf(summary.byCategory.single), 1.0);
    });

    test('a zero-amount expense does not divide by zero', () {
      final summary = summarise([
        expense('a', 0, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);
      expect(summary.shareOf(summary.byCategory.single), 0.0);
      expect(summary.barFractionOf(summary.byCategory.single), 0.0);
    });

    test('near-maximum amounts stay exact and shares stay within one', () {
      const huge = (1 << 53) + 1;
      final summary = summarise([
        expense('a', huge, SpendCategory.bills, DateTime.utc(2026, 9, 3)),
        expense('b', 1, SpendCategory.food, DateTime.utc(2026, 9, 2)),
      ]);

      expect(summary.totalExpenses, const Money(huge + 1, vnd));
      for (final category in summary.byCategory) {
        expect(summary.shareOf(category), lessThanOrEqualTo(1));
        expect(summary.barFractionOf(category), lessThanOrEqualTo(1));
      }
    });

    test('a currency mismatch is reported, naming the offender', () {
      expect(
        () => InsightsSummary.of(
          entries: [
            expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
            InsightsEntry(
              id: 'usd',
              title: 'Trip',
              category: SpendCategory.shopping,
              direction: TransactionDirection.expense,
              amount: const Money(1200, Currency.usd),
              occurredAt: DateTime.utc(2026, 9, 3),
            ),
          ],
          period: InsightsPeriod.thisMonth,
          now: now,
          currency: vnd,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            allOf(contains('USD'), contains('Trip')),
          ),
        ),
      );
    });

    test('a mismatch OUTSIDE the window is not reported', () {
      // Only what is charted has to agree. Refusing over a row the period does
      // not include would make one old foreign-currency purchase break every
      // period for ever.
      final summary = InsightsSummary.of(
        entries: [
          expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
          InsightsEntry(
            id: 'usd',
            title: 'Old trip',
            category: SpendCategory.shopping,
            direction: TransactionDirection.expense,
            amount: const Money(1200, Currency.usd),
            occurredAt: DateTime.utc(2024, 3, 3),
          ),
        ],
        period: InsightsPeriod.thisMonth,
        now: now,
        currency: vnd,
      );
      expect(summary.totalExpenses, const Money(100000, vnd));
    });

    test('entries outside the window are excluded from every figure', () {
      final summary = summarise([
        expense('in', 100000, SpendCategory.food, DateTime.utc(2026, 9, 2)),
        expense('out', 900000, SpendCategory.bills, DateTime.utc(2026, 8, 2)),
      ]);

      expect(summary.totalExpenses, const Money(100000, vnd));
      expect(summary.byCategory, hasLength(1));
      expect(summary.topExpenses.map((e) => e.id), ['in']);
    });
  });
}
