import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/day_grouping.dart';

void main() {
  const vnd = Currency.vnd;
  var counter = 0;

  Transaction tx({
    required DateTime at,
    int amount = 1000,
    TransactionDirection direction = TransactionDirection.expense,
  }) {
    counter++;
    return Transaction.create(
      id: 'tx-$counter',
      amount: Money(amount, vnd),
      direction: direction,
      category: SpendCategory.food,
      occurredAt: at,
      createdAt: at,
    ).valueOrNull!;
  }

  setUp(() => counter = 0);

  group('grouping', () {
    test('an empty list groups to nothing', () {
      expect(groupByLocalDay(const [], vnd), isEmpty);
    });

    test('one day, one group', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 24, 9).toUtc()),
        tx(at: DateTime(2026, 8, 24, 18).toUtc()),
      ], vnd);

      expect(groups, hasLength(1));
      expect(groups.single.transactions, hasLength(2));
      expect(groups.single.date, DateTime(2026, 8, 24));
    });

    test('days are ordered most recent first', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 24, 9).toUtc()),
        tx(at: DateTime(2026, 8, 26, 9).toUtc()),
        tx(at: DateTime(2026, 8, 25, 9).toUtc()),
      ], vnd);

      expect(
        groups.map((g) => g.date.day),
        [26, 25, 24],
      );
    });

    test('days with no transactions produce no group', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 20, 9).toUtc()),
        tx(at: DateTime(2026, 8, 24, 9).toUtc()),
      ], vnd);

      // The 21st through 23rd are absent, not empty groups.
      expect(groups.map((g) => g.date.day), [24, 20]);
    });

    test('order within a day is preserved', () {
      final first = tx(at: DateTime(2026, 8, 24, 18).toUtc());
      final second = tx(at: DateTime(2026, 8, 24, 9).toUtc());
      final groups = groupByLocalDay([first, second], vnd);
      expect(groups.single.transactions, [first, second]);
    });

    test('the group list is unmodifiable', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 24, 9).toUtc()),
      ], vnd);
      expect(
        () => groups.single.transactions.add(
          tx(at: DateTime(2026, 8, 24, 9).toUtc()),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('day net', () {
    test('is income minus expenses', () {
      final groups = groupByLocalDay([
        tx(
          at: DateTime(2026, 8, 24, 9).toUtc(),
          amount: 5000,
          direction: TransactionDirection.income,
        ),
        tx(at: DateTime(2026, 8, 24, 10).toUtc(), amount: 2000),
      ], vnd);

      expect(groups.single.net.minorUnits, 3000);
    });

    test('is negative on an expense-only day', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 24, 9).toUtc(), amount: 2000),
      ], vnd);
      expect(groups.single.net.minorUnits, -2000);
    });

    test('is zero when a day cancels out', () {
      final groups = groupByLocalDay([
        tx(
          at: DateTime(2026, 8, 24, 9).toUtc(),
          amount: 2000,
          direction: TransactionDirection.income,
        ),
        tx(at: DateTime(2026, 8, 24, 10).toUtc(), amount: 2000),
      ], vnd);
      expect(groups.single.net.isZero, isTrue);
    });

    test('each day nets independently', () {
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 25, 9).toUtc(), amount: 500),
        tx(at: DateTime(2026, 8, 24, 9).toUtc(), amount: 1500),
      ], vnd);
      expect(groups[0].net.minorUnits, -500);
      expect(groups[1].net.minorUnits, -1500);
    });
  });

  group('local day boundaries', () {
    test('instants either side of local midnight land in different days', () {
      final beforeMidnight = DateTime(2026, 8, 24, 23, 59).toUtc();
      final afterMidnight = DateTime(2026, 8, 25, 0, 1).toUtc();

      final groups = groupByLocalDay([
        tx(at: afterMidnight),
        tx(at: beforeMidnight),
      ], vnd);

      expect(groups, hasLength(2));
      expect(groups[0].date, DateTime(2026, 8, 25));
      expect(groups[1].date, DateTime(2026, 8, 24));
    });

    test('grouping is by local day, not UTC day', () {
      // 23:30 local on the 24th may be the 25th in UTC, or vice versa. Whatever
      // the runner's zone, both of these must land on the local 24th.
      final groups = groupByLocalDay([
        tx(at: DateTime(2026, 8, 24, 0, 30).toUtc()),
        tx(at: DateTime(2026, 8, 24, 23, 30).toUtc()),
      ], vnd);

      expect(groups, hasLength(1));
      expect(groups.single.date, DateTime(2026, 8, 24));
    });

    test('a day containing a DST transition still groups as one day', () {
      // Constructed from y/m/d rather than by subtracting 24 hours: a DST day is
      // 23 or 25 hours long, so duration arithmetic lands in the wrong day.
      // These dates are DST transitions in several common zones; in a zone with
      // no DST they are ordinary days, and the assertion holds either way.
      for (final day in [
        DateTime(2026, 3, 29),
        DateTime(2026, 10, 25),
        DateTime(2026, 3, 8),
        DateTime(2026, 11, 1),
      ]) {
        final groups = groupByLocalDay([
          tx(at: DateTime(day.year, day.month, day.day, 1, 30).toUtc()),
          tx(at: DateTime(day.year, day.month, day.day, 12).toUtc()),
          tx(at: DateTime(day.year, day.month, day.day, 22, 30).toUtc()),
        ], vnd);

        expect(
          groups,
          hasLength(1),
          reason: '${day.toIso8601String()} split into ${groups.length} groups',
        );
        expect(groups.single.transactions, hasLength(3));
      }
    });
  });

  test('toString is debuggable', () {
    final groups = groupByLocalDay([
      tx(at: DateTime(2026, 8, 24, 9).toUtc()),
    ], vnd);
    expect(groups.single.toString(), contains('1 txs'));
  });
}
