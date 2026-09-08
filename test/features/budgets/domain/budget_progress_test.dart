import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';

void main() {
  const vnd = Currency.vnd;
  const usd = Currency.usd;
  final september = DateTime.utc(2026, 9);

  Budget budget({
    Money limit = const Money(4000000, vnd),
    bool rollsOver = false,
    double threshold = 0.8,
    String id = 'b1',
    SpendCategory category = SpendCategory.food,
    DateTime? startsOn,
  }) => Budget.create(
    id: id,
    category: category,
    limit: limit,
    period: BudgetPeriod.monthly,
    startsOn: startsOn ?? september,
    createdAt: DateTime.utc(2026, 8, 30),
    rollsOver: rollsOver,
    alertThreshold: threshold,
  ).valueOrNull!;

  SpendEntry entry(
    int minor, {
    DateTime? at,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    Currency currency = vnd,
    String id = 'e1',
  }) => SpendEntry(
    id: id,
    category: category,
    direction: direction,
    amount: Money(minor, currency),
    occurredAt: at ?? DateTime.utc(2026, 9, 10),
  );

  BudgetProgress progressOf(
    List<SpendEntry> entries, {
    Budget? b,
    DateTime? now,
  }) => BudgetProgress.compute(
    budget: b ?? budget(),
    entries: entries,
    now: now ?? DateTime.utc(2026, 9, 20),
  );

  group('spend counts only what the budget measures', () {
    test('expenses in the category and window are summed', () {
      final p = progressOf([entry(1000000), entry(500000, id: 'e2')]);
      expect(p.spent, const Money(1500000, vnd));
    });

    test('income in the same category is not spend', () {
      // A refund does not reduce the spend, and it certainly does not add to it.
      final p = progressOf([
        entry(1000000),
        entry(400000, id: 'e2', direction: TransactionDirection.income),
      ]);
      expect(p.spent, const Money(1000000, vnd));
    });

    test('another category is not counted', () {
      final p = progressOf([
        entry(1000000),
        entry(900000, id: 'e2', category: SpendCategory.transport),
      ]);
      expect(p.spent, const Money(1000000, vnd));
    });

    test('outside the window is not counted', () {
      final p = progressOf([
        entry(1000000),
        entry(900000, id: 'e2', at: DateTime.utc(2026, 8, 31)),
        entry(700000, id: 'e3', at: DateTime.utc(2026, 10, 1)),
      ]);
      expect(p.spent, const Money(1000000, vnd));
    });

    test('the window is half-open at both ends', () {
      final p = progressOf([
        entry(100, at: DateTime.utc(2026, 9)),
        entry(200, id: 'e2', at: DateTime.utc(2026, 10)),
      ]);
      expect(
        p.spent,
        const Money(100, vnd),
        reason: 'the start instant counts and the end instant does not',
      );
    });

    test('a foreign currency is skipped and disclosed, not converted', () {
      // There is no exchange rate in a local-first app, and inventing one puts
      // a made-up number inside a total the user trusts.
      final p = progressOf([
        entry(1000000),
        entry(5000, id: 'e2', currency: usd),
      ]);
      expect(p.spent, const Money(1000000, vnd));
      expect(p.skippedForeignCurrency, 1);
    });

    test('nothing skipped reports zero', () {
      expect(progressOf([entry(1000000)]).skippedForeignCurrency, 0);
    });

    test('an empty ledger is zero spend, not an error', () {
      final p = progressOf([]);
      expect(p.spent, const Money(0, vnd));
      expect(p.fraction, 0);
      expect(p.status, BudgetStatus.onTrack);
    });
  });

  group('status uses the budget own threshold', () {
    test('a budget alerting at 50% warns at 60% spent', () {
      final p = progressOf(
        [entry(2400000)],
        b: budget(threshold: 0.5),
      );
      expect(p.status, BudgetStatus.nearLimit);
      expect(
        progressOf([entry(2400000)]).status,
        BudgetStatus.onTrack,
        reason: 'the same spend at the default 0.8 is on track',
      );
    });

    test('over the limit is over regardless of threshold', () {
      final p = progressOf(
        [entry(5000000)],
        b: budget(threshold: 1),
      );
      expect(p.status, BudgetStatus.over);
    });
  });

  group('daily allowance', () {
    test('remainder divided by days left', () {
      // 4,000,000 limit, 1,000,000 spent, now 21 Sep → 10 days to 1 Oct.
      final p = progressOf([entry(1000000)], now: DateTime.utc(2026, 9, 21));
      expect(p.daysRemaining, 10);
      expect(p.dailyAllowance, const Money(300000, vnd));
    });

    test('the last day gives the whole remainder', () {
      final p = progressOf([
        entry(1000000),
      ], now: DateTime.utc(2026, 9, 30, 12));
      expect(p.daysRemaining, 1);
      expect(p.dailyAllowance, const Money(3000000, vnd));
    });

    test('over budget allows zero, not a negative number', () {
      final p = progressOf([entry(5000000)]);
      expect(p.dailyAllowance, const Money(0, vnd));
      expect(p.remaining, const Money(0, vnd));
      expect(
        p.fraction,
        greaterThan(1),
        reason: 'the true fraction survives so the screen can say by how much',
      );
    });

    test('rounds down, never up', () {
      // 10 remaining over 3 days is 3.33; 4 is an allowance the user cannot
      // actually spend every day.
      final p = progressOf(
        [entry(90)],
        b: budget(limit: const Money(100, vnd)),
        now: DateTime.utc(2026, 9, 29),
      );
      expect(p.daysRemaining, 2);
      expect(p.dailyAllowance, const Money(5, vnd));

      final p2 = progressOf(
        [entry(91)],
        b: budget(limit: const Money(100, vnd)),
        now: DateTime.utc(2026, 9, 29),
      );
      expect(p2.dailyAllowance, const Money(4, vnd));
    });
  });

  group('rollover', () {
    test('unspent last month raises this month effective limit', () {
      final p = progressOf(
        [entry(3000000, at: DateTime.utc(2026, 8, 10))],
        b: budget(
          rollsOver: true,
          startsOn: DateTime.utc(2026, 8),
        ),
      );
      expect(p.carriedIn, const Money(1000000, vnd));
      expect(p.effectiveLimit, const Money(5000000, vnd));
      expect(
        p.budget.limit,
        const Money(4000000, vnd),
        reason: 'the carry is reported separately from the limit the user set',
      );
    });

    test('overspending does not carry a debt forward', () {
      final p = progressOf(
        [entry(4500000, at: DateTime.utc(2026, 8, 10))],
        b: budget(rollsOver: true, startsOn: DateTime.utc(2026, 8)),
      );
      expect(p.carriedIn, const Money(0, vnd));
      expect(p.effectiveLimit, const Money(4000000, vnd));
    });

    test('rollover off carries nothing', () {
      final p = progressOf(
        [entry(3000000, at: DateTime.utc(2026, 8, 10))],
        b: budget(startsOn: DateTime.utc(2026, 8)),
      );
      expect(p.carriedIn, const Money(0, vnd));
      expect(p.effectiveLimit, const Money(4000000, vnd));
    });

    test('the carry is one window deep, not all of them', () {
      // Underspent July and August. Only August reaches September.
      final p = progressOf(
        [
          entry(0, at: DateTime.utc(2026, 7, 10)),
          entry(3000000, id: 'e2', at: DateTime.utc(2026, 8, 10)),
        ],
        b: budget(rollsOver: true, startsOn: DateTime.utc(2026, 7)),
      );
      expect(
        p.carriedIn,
        const Money(1000000, vnd),
        reason: 'a recursive carry would give 5,000,000 from two windows',
      );
    });

    test('a window before the budget existed carries nothing', () {
      final p = progressOf(
        [],
        b: budget(rollsOver: true, startsOn: september),
      );
      expect(p.carriedIn, const Money(0, vnd));
    });
  });

  group('ranking', () {
    BudgetProgress at(String id, int spentMinor) => progressOf(
      [entry(spentMinor, id: 'x$id')],
      b: budget(id: id),
    );

    test('worst first', () {
      final list = [at('a', 1800000), at('b', 4800000), at('c', 3280000)]
        ..sort(compareWorstFirst);
      expect(list.map((p) => p.budget.id), ['b', 'c', 'a']);
    });

    test('ties are stable across repeated sorts', () {
      final first = [at('z', 2000000), at('a', 2000000)]
        ..sort(compareWorstFirst);
      final second = [at('a', 2000000), at('z', 2000000)]
        ..sort(compareWorstFirst);
      expect(first.map((p) => p.budget.id), second.map((p) => p.budget.id));
    });

    test('a budget with no spend is last, not omitted', () {
      final list = [at('a', 0), at('b', 1000000)]..sort(compareWorstFirst);
      expect(list.map((p) => p.budget.id), ['b', 'a']);
      expect(list, hasLength(2));
    });
  });

  group('a budget that has not started', () {
    test('reports zero spent against the full limit', () {
      final p = progressOf(
        [entry(900000, at: DateTime.utc(2026, 9, 10))],
        b: budget(startsOn: DateTime.utc(2026, 10)),
      );
      expect(p.window.start, DateTime.utc(2026, 10));
      expect(p.spent, const Money(0, vnd));
      expect(p.effectiveLimit, const Money(4000000, vnd));
    });
  });
}
