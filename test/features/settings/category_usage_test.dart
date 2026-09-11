import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/features/settings/domain/category_usage.dart';

void main() {
  const vnd = Currency.vnd;

  UsageEntry entry(
    SpendCategory category,
    int minor,
    DateTime at, {
    TransactionDirection direction = TransactionDirection.expense,
  }) => UsageEntry(
    category: category,
    direction: direction,
    amount: Money(minor, vnd),
    occurredAt: at,
  );

  /// September 2026 in `Asia/Ho_Chi_Minh`, which the gate pins.
  final window = monthWindow(FixedClock(DateTime.utc(2026, 9, 11, 3)));

  List<CategoryUsage> usageOf(
    List<UsageEntry> entries, {
    TransactionDirection direction = TransactionDirection.expense,
  }) => categoryUsage(
    entries: entries,
    direction: direction,
    startUtc: window.startUtc,
    endUtc: window.endUtc,
    currency: vnd,
  );

  CategoryUsage rowFor(List<CategoryUsage> rows, SpendCategory category) =>
      rows.firstWhere((r) => r.category == category);

  group('the counts and totals are the ledger', () {
    test('three in one category and one in another', () {
      final rows = usageOf([
        entry(SpendCategory.food, 10000, DateTime.utc(2026, 9, 2)),
        entry(SpendCategory.food, 20000, DateTime.utc(2026, 9, 3)),
        entry(SpendCategory.food, 30000, DateTime.utc(2026, 9, 4)),
        entry(SpendCategory.transport, 5000, DateTime.utc(2026, 9, 5)),
      ]);

      expect(rowFor(rows, SpendCategory.food).count, 3);
      expect(rowFor(rows, SpendCategory.food).total, const Money(60000, vnd));
      expect(rowFor(rows, SpendCategory.transport).count, 1);
      expect(
        rowFor(rows, SpendCategory.transport).total,
        const Money(5000, vnd),
      );
    });

    test('every category is listed, including the unused ones', () {
      final rows = usageOf([
        entry(SpendCategory.food, 10000, DateTime.utc(2026, 9, 2)),
      ]);

      // Absence is the information: "you have never used this" is an answer,
      // and a missing row is not.
      expect(rows, hasLength(SpendCategory.values.length));
      expect(rowFor(rows, SpendCategory.health).count, 0);
      expect(rowFor(rows, SpendCategory.health).total, const Money(0, vnd));
    });

    test('largest total first, ties in enum order', () {
      final rows = usageOf([
        entry(SpendCategory.transport, 50000, DateTime.utc(2026, 9, 2)),
        entry(SpendCategory.food, 90000, DateTime.utc(2026, 9, 3)),
        entry(SpendCategory.shopping, 50000, DateTime.utc(2026, 9, 4)),
      ]);

      expect(rows.first.category, SpendCategory.food);
      // Two at 50,000: the one earlier in the enum comes first, so the list is
      // stable rather than reshuffling between builds.
      final tied = rows.where((r) => r.total.minorUnits == 50000).toList();
      expect(
        SpendCategory.values.indexOf(tied.first.category),
        lessThan(SpendCategory.values.indexOf(tied.last.category)),
      );
    });
  });

  group('the direction is the transaction, not the category', () {
    test('an income-direction gift is counted as income', () {
      // `SpendCategory.isIncome` says only `salary` is income, and
      // `lib/core/spend_category.dart` calls that getter "a display hint
      // only" because "the direction of a transaction is a property of the
      // transaction, not of its category". Filtering by the category would
      // hide this row entirely.
      final entries = [
        entry(
          SpendCategory.gift,
          200000,
          DateTime.utc(2026, 9, 2),
          direction: TransactionDirection.income,
        ),
      ];

      expect(
        rowFor(
          usageOf(entries, direction: TransactionDirection.income),
          SpendCategory.gift,
        ).count,
        1,
      );
      expect(
        rowFor(
          usageOf(entries),
          SpendCategory.gift,
        ).count,
        0,
        reason: 'it is not an expense',
      );
    });

    test('the two directions do not leak into each other', () {
      final entries = [
        entry(SpendCategory.food, 10000, DateTime.utc(2026, 9, 2)),
        entry(
          SpendCategory.salary,
          9000000,
          DateTime.utc(2026, 9, 3),
          direction: TransactionDirection.income,
        ),
      ];

      expect(rowFor(usageOf(entries), SpendCategory.salary).count, 0);
      expect(
        rowFor(
          usageOf(entries, direction: TransactionDirection.income),
          SpendCategory.food,
        ).count,
        0,
      );
    });
  });

  group('the window is a local month', () {
    test('an entry at 18:00Z on 31 August is September here', () {
      // 2026-08-31T18:00Z is 2026-09-01T01:00 in Asia/Ho_Chi_Minh. A boundary
      // computed in UTC drops it; the gate pins TZ=+07 so this test can tell.
      final rows = usageOf([
        entry(SpendCategory.food, 10000, DateTime.utc(2026, 8, 31, 18)),
      ]);
      expect(
        rowFor(rows, SpendCategory.food).count,
        1,
        reason: 'a UTC boundary would call this August',
      );
    });

    test('an entry at 16:59Z on 31 August is still August', () {
      // 23:59 local on 31 August — one minute before the local month starts.
      final rows = usageOf([
        entry(SpendCategory.food, 10000, DateTime.utc(2026, 8, 31, 16, 59)),
      ]);
      expect(rowFor(rows, SpendCategory.food).count, 0);
    });

    test(
      'the last instant of September is in, the first of October is out',
      () {
        final rows = usageOf([
          entry(SpendCategory.food, 10000, DateTime.utc(2026, 9, 30, 16, 59)),
          entry(SpendCategory.transport, 10000, DateTime.utc(2026, 9, 30, 17)),
        ]);
        expect(rowFor(rows, SpendCategory.food).count, 1);
        expect(
          rowFor(rows, SpendCategory.transport).count,
          0,
          reason: '2026-09-30T17:00Z is 1 October here — a half-open window',
        );
      },
    );

    test('the window is the calendar month, both ends', () {
      final september = monthWindow(FixedClock(DateTime.utc(2026, 9, 11, 3)));
      expect(september.startUtc, DateTime.utc(2026, 8, 31, 17));
      expect(september.endUtc, DateTime.utc(2026, 9, 30, 17));

      // December rolls into the next year rather than month 13.
      final december = monthWindow(FixedClock(DateTime.utc(2026, 12, 20, 3)));
      expect(december.endUtc, DateTime.utc(2026, 12, 31, 17));
    });
  });

  group('boundaries', () {
    test('an empty ledger lists every category at zero', () {
      final rows = usageOf([]);
      expect(rows, hasLength(SpendCategory.values.length));
      expect(rows.every((r) => r.count == 0), isTrue);
      expect(rows.every((r) => r.total == const Money(0, vnd)), isTrue);
    });

    test('a refund subtracts', () {
      final rows = usageOf([
        entry(SpendCategory.shopping, 50000, DateTime.utc(2026, 9, 2)),
        entry(SpendCategory.shopping, -20000, DateTime.utc(2026, 9, 3)),
      ]);
      expect(rowFor(rows, SpendCategory.shopping).count, 2);
      expect(
        rowFor(rows, SpendCategory.shopping).total,
        const Money(30000, vnd),
      );
    });

    test('near-maximum amounts stay exact', () {
      const huge = (1 << 61) - 1;
      final rows = usageOf([
        entry(SpendCategory.bills, huge, DateTime.utc(2026, 9, 2)),
      ]);
      expect(rowFor(rows, SpendCategory.bills).total.minorUnits, huge);
    });

    test('two currencies in one category are reported, not summed', () {
      expect(
        () => categoryUsage(
          entries: [
            entry(SpendCategory.food, 10000, DateTime.utc(2026, 9, 2)),
            UsageEntry(
              category: SpendCategory.food,
              direction: TransactionDirection.expense,
              amount: const Money(20, Currency.usd),
              occurredAt: DateTime.utc(2026, 9, 3),
            ),
          ],
          direction: TransactionDirection.expense,
          startUtc: window.startUtc,
          endUtc: window.endUtc,
          currency: vnd,
        ),
        throwsArgumentError,
      );
    });
  });
}
