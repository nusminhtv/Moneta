import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';

/// Value semantics, one field at a time.
///
/// Riverpod rebuilds on inequality, so a `props` list missing a field means a
/// screen that silently keeps showing the old number after an edit — the same
/// shape of bug as Home reading a second source of truth.
void main() {
  const vnd = Currency.vnd;
  final september = DateTime.utc(2026, 9);

  Budget budget({
    String id = 'b1',
    SpendCategory category = SpendCategory.food,
    Money limit = const Money(4000000, vnd),
    BudgetPeriod period = BudgetPeriod.monthly,
    DateTime? startsOn,
    bool rollsOver = false,
    double alertThreshold = 0.8,
    DateTime? createdAt,
  }) => Budget.fromStorage(
    id: id,
    category: category,
    limit: limit,
    period: period,
    startsOn: startsOn ?? september,
    rollsOver: rollsOver,
    alertThreshold: alertThreshold,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 30),
  );

  group('Budget', () {
    test('two budgets with the same values are equal', () {
      expect(budget(), budget());
      expect(budget().hashCode, budget().hashCode);
    });

    test('changing any single field breaks equality', () {
      final variants = <String, Budget>{
        'id': budget(id: 'b2'),
        'category': budget(category: SpendCategory.transport),
        'limit': budget(limit: const Money(1, vnd)),
        'period': budget(period: BudgetPeriod.weekly),
        'startsOn': budget(startsOn: DateTime.utc(2026, 10)),
        'rollsOver': budget(rollsOver: true),
        'alertThreshold': budget(alertThreshold: 0.5),
        'createdAt': budget(createdAt: DateTime.utc(2026, 8, 29)),
      };
      for (final entry in variants.entries) {
        expect(
          entry.value,
          isNot(budget()),
          reason: '${entry.key} is missing from props',
        );
      }
    });
  });

  group('SpendEntry', () {
    SpendEntry entry({
      String id = 'e1',
      SpendCategory category = SpendCategory.food,
      TransactionDirection direction = TransactionDirection.expense,
      Money amount = const Money(1000, vnd),
      DateTime? occurredAt,
    }) => SpendEntry(
      id: id,
      category: category,
      direction: direction,
      amount: amount,
      occurredAt: occurredAt ?? DateTime.utc(2026, 9, 10),
    );

    test('same values are equal', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
    });

    test('changing any single field breaks equality', () {
      expect(entry(id: 'e2'), isNot(entry()));
      expect(entry(category: SpendCategory.bills), isNot(entry()));
      expect(
        entry(direction: TransactionDirection.income),
        isNot(entry()),
      );
      expect(entry(amount: const Money(2000, vnd)), isNot(entry()));
      expect(entry(occurredAt: DateTime.utc(2026, 9, 11)), isNot(entry()));
    });
  });

  group('BudgetProgress', () {
    BudgetProgress progress({
      int spent = 1000,
      int carried = 0,
      int days = 10,
      int skipped = 0,
    }) => BudgetProgress(
      budget: budget(),
      window: BudgetWindow(start: september, end: DateTime.utc(2026, 10)),
      spent: Money(spent, vnd),
      carriedIn: Money(carried, vnd),
      daysRemaining: days,
      skippedForeignCurrency: skipped,
    );

    test('same values are equal', () {
      expect(progress(), progress());
      expect(progress().hashCode, progress().hashCode);
    });

    test('changing any single field breaks equality', () {
      expect(progress(spent: 2000), isNot(progress()));
      expect(progress(carried: 500), isNot(progress()));
      expect(progress(days: 9), isNot(progress()));
      expect(progress(skipped: 1), isNot(progress()));
    });
  });

  group('BudgetWindow', () {
    final w = BudgetWindow(start: september, end: DateTime.utc(2026, 10));

    test('same bounds are equal', () {
      expect(
        w,
        BudgetWindow(start: september, end: DateTime.utc(2026, 10)),
      );
      expect(
        w.hashCode,
        BudgetWindow(start: september, end: DateTime.utc(2026, 10)).hashCode,
      );
    });

    test('different bounds are not', () {
      expect(
        w,
        isNot(BudgetWindow(start: september, end: DateTime.utc(2026, 11))),
      );
      expect(
        w,
        isNot(
          BudgetWindow(
            start: DateTime.utc(2026, 8),
            end: DateTime.utc(2026, 10),
          ),
        ),
      );
      expect(w, isNot('not a window'));
    });

    test('toString names both bounds', () {
      expect(w.toString(), contains('2026-09-01'));
      expect(w.toString(), contains('2026-10-01'));
    });

    test('previous works for every period', () {
      final weekly = BudgetWindow(
        start: DateTime.utc(2026, 9, 14),
        end: DateTime.utc(2026, 9, 21),
      ).previous(BudgetPeriod.weekly, anchor: DateTime.utc(2026, 8, 31))!;
      expect(weekly.start, DateTime.utc(2026, 9, 7));
      expect(weekly.end, DateTime.utc(2026, 9, 14));

      final yearly = BudgetWindow(
        start: DateTime.utc(2026, 3, 15),
        end: DateTime.utc(2027, 3, 15),
      ).previous(BudgetPeriod.yearly, anchor: DateTime.utc(2024, 3, 15))!;
      expect(yearly.start, DateTime.utc(2025, 3, 15));

      final monthly = w.previous(
        BudgetPeriod.monthly,
        anchor: DateTime.utc(2026, 1),
      )!;
      expect(monthly.start, DateTime.utc(2026, 8));
    });
  });
}
