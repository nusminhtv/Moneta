import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';

void main() {
  const vnd = Currency.vnd;

  Result<Budget> make({
    Money limit = const Money(4000000, vnd),
    double threshold = 0.8,
    BudgetPeriod period = BudgetPeriod.monthly,
    bool rollsOver = false,
    DateTime? startsOn,
  }) => Budget.create(
    id: 'b1',
    category: SpendCategory.food,
    limit: limit,
    period: period,
    startsOn: startsOn ?? DateTime.utc(2026, 9),
    createdAt: DateTime.utc(2026, 8, 30),
    rollsOver: rollsOver,
    alertThreshold: threshold,
  );

  group('everything 04.04 collects round-trips', () {
    test('a valid budget keeps all six values', () {
      final budget = make(rollsOver: true, threshold: 0.6).valueOrNull!;
      expect(budget.category, SpendCategory.food);
      expect(budget.limit, const Money(4000000, vnd));
      expect(budget.period, BudgetPeriod.monthly);
      expect(budget.startsOn, DateTime.utc(2026, 9));
      expect(budget.rollsOver, isTrue);
      expect(budget.alertThreshold, 0.6);
    });

    test('the limit is integer minor units, not a double', () {
      final budget = make().valueOrNull!;
      expect(budget.limit.minorUnits, isA<int>());
      expect(budget.limit.minorUnits, 4000000);
    });

    test('the default threshold is the design system default', () {
      final budget = Budget.create(
        id: 'b1',
        category: SpendCategory.food,
        limit: const Money(4000000, vnd),
        period: BudgetPeriod.monthly,
        startsOn: DateTime.utc(2026, 9),
        createdAt: DateTime.utc(2026, 8, 30),
      ).valueOrNull!;
      expect(
        budget.alertThreshold,
        BudgetStatus.defaultNearLimitThreshold,
      );
    });
  });

  group('validation', () {
    test('a zero limit is refused, and the message says why', () {
      final result = make(limit: const Money(0, vnd));
      expect(result, isA<Err<Budget>>());
      final failure = (result as Err<Budget>).failure;
      expect(failure.kind, FailureKind.validation);
      expect(failure.message, contains('over'));
      expect(failure.message, contains('under'));
    });

    test('a negative limit is refused', () {
      expect(make(limit: const Money(-1, vnd)), isA<Err<Budget>>());
    });

    test('a threshold outside 0 to 1 is refused', () {
      for (final t in [0.0, -0.2, 1.5, 2.0]) {
        expect(
          make(threshold: t),
          isA<Err<Budget>>(),
          reason: 'threshold $t was accepted',
        );
      }
    });

    test('a threshold of exactly 1.0 is accepted', () {
      // "Warn me only when I actually reach the limit" is a real choice.
      expect(make(threshold: 1), isA<Ok<Budget>>());
    });

    test('a non-UTC start date is refused', () {
      expect(
        make(startsOn: DateTime(2026, 9)),
        isA<Err<Budget>>(),
        reason: 'a local DateTime would shift the window by the offset',
      );
    });
  });

  group('fromStorage does not re-validate', () {
    test('a row written under an older rule still reads back', () {
      // Refusing to read stored data because a rule changed after it was
      // written strands the user's own budgets. Validation belongs at the door.
      final stored = Budget.fromStorage(
        id: 'b1',
        category: SpendCategory.food,
        limit: const Money(0, vnd),
        period: BudgetPeriod.monthly,
        startsOn: DateTime.utc(2026, 9),
        rollsOver: false,
        alertThreshold: 0.8,
        createdAt: DateTime.utc(2026, 8, 30),
      );
      expect(stored.limit, const Money(0, vnd));
    });
  });

  group('copyWith', () {
    test('changes only what is named', () {
      final budget = make().valueOrNull!;
      final edited = budget.copyWith(limit: const Money(5000000, vnd));
      expect(edited.limit, const Money(5000000, vnd));
      expect(edited.id, budget.id);
      expect(edited.category, budget.category);
      expect(edited.period, budget.period);
      expect(edited.startsOn, budget.startsOn);
      expect(edited.alertThreshold, budget.alertThreshold);
      expect(edited.createdAt, budget.createdAt);
    });
  });

  group('windowAt', () {
    test('delegates to the period rule', () {
      final budget = make().valueOrNull!;
      final w = budget.windowAt(DateTime.utc(2026, 9, 20));
      expect(w.start, DateTime.utc(2026, 9));
      expect(w.end, DateTime.utc(2026, 10));
    });
  });
}
