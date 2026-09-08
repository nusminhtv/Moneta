import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/create_budget_controller.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_repository.dart';
import 'package:moneta/features/budgets/presentation/create_budget_category_screen.dart';

/// An in-memory [BudgetRepository], so the flow can be tested without SQLite.
class _FakeBudgetRepository implements BudgetRepository {
  final List<Budget> saved = [];
  AppFailure? failNextAdd;

  @override
  Future<Result<void>> add(Budget budget) async {
    if (failNextAdd case final failure?) {
      failNextAdd = null;
      return Err(failure);
    }
    saved.add(budget);
    return const Ok(null);
  }

  @override
  Future<Result<List<Budget>>> list() async => Ok(saved);

  @override
  Future<Result<Budget>> byId(String id) async {
    for (final budget in saved) {
      if (budget.id == id) return Ok(budget);
    }
    return Err(AppFailure.notFound('no $id'));
  }

  @override
  Future<Result<void>> update(Budget budget) async => const Ok(null);

  @override
  Future<Result<void>> remove(String id) async => const Ok(null);

  @override
  Future<Result<bool>> exists({
    required SpendCategory category,
    required BudgetPeriod period,
  }) async => Ok(
    saved.any((b) => b.category == category && b.period == period),
  );
}

void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 8, 14, 32);

  ({ProviderContainer container, _FakeBudgetRepository repository}) build() {
    final repository = _FakeBudgetRepository();
    final container = ProviderContainer(
      overrides: [
        budgetRepositoryProvider.overrideWith((ref) async => repository),
        clockProvider.overrideWithValue(FixedClock(now)),
        idGeneratorProvider.overrideWithValue(
          FixedIdGenerator(prefix: 'b'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, repository: repository);
  }

  group('nothing is written until submit', () {
    test('filling in every field writes no row', () async {
      final (:container, :repository) = build();
      container.read(createBudgetControllerProvider.notifier)
        ..chooseCategory(SpendCategory.food)
        ..setLimit(const Money(4000000, vnd))
        ..setPeriod(BudgetPeriod.weekly)
        ..toggleRollover()
        ..setAlertThreshold(0.6);

      expect(repository.saved, isEmpty);
    });

    test('abandoning the flow leaves nothing behind', () async {
      final (:container, :repository) = build();
      container.read(createBudgetControllerProvider.notifier)
        ..chooseCategory(SpendCategory.food)
        ..setLimit(const Money(4000000, vnd))
        ..reset();

      expect(repository.saved, isEmpty);
      expect(
        container.read(createBudgetControllerProvider).category,
        isNull,
        reason: 'a stale category would greet the user next time',
      );
    });

    test('submit writes exactly one row with what was entered', () async {
      final (:container, :repository) = build();
      final controller = container.read(createBudgetControllerProvider.notifier)
        ..chooseCategory(SpendCategory.food)
        ..setLimit(const Money(4000000, vnd))
        ..setPeriod(BudgetPeriod.weekly)
        ..toggleRollover()
        ..setAlertThreshold(0.6);

      expect(await controller.submit(), isNull);
      expect(repository.saved, hasLength(1));

      final budget = repository.saved.single;
      expect(budget.category, SpendCategory.food);
      expect(budget.limit, const Money(4000000, vnd));
      expect(budget.period, BudgetPeriod.weekly);
      expect(budget.rollsOver, isTrue);
      expect(budget.alertThreshold, 0.6);
    });
  });

  group('the anchor is a whole day', () {
    test(
      'a budget started now begins at midnight, not mid-afternoon',
      () async {
        // The clock says 14:32. A budget anchored there would make every window
        // boundary fall mid-afternoon, so "1 September" would start on the
        // afternoon of the 1st.
        final (:container, :repository) = build();
        final controller =
            container.read(createBudgetControllerProvider.notifier)
              ..chooseCategory(SpendCategory.food)
              ..setLimit(const Money(4000000, vnd));
        await controller.submit();

        expect(repository.saved.single.startsOn, DateTime.utc(2026, 9, 8));
      },
    );

    test('a picked date is also flattened to midnight UTC', () async {
      final (:container, :repository) = build();
      final controller =
          container.read(
              createBudgetControllerProvider.notifier,
            )
            ..chooseCategory(SpendCategory.food)
            ..setLimit(const Money(4000000, vnd))
            ..setStartsOn(DateTime.utc(2026, 10, 3, 19, 5));
      await controller.submit();

      expect(repository.saved.single.startsOn, DateTime.utc(2026, 10, 3));
      expect(repository.saved.single.startsOn.isUtc, isTrue);
    });
  });

  group('failures', () {
    test('a zero amount is refused with a message on the field', () async {
      final (:container, :repository) = build();
      final controller = container.read(
        createBudgetControllerProvider.notifier,
      )..chooseCategory(SpendCategory.food);

      final failure = await controller.submit();
      expect(failure, isNotNull);
      expect(failure!.kind, FailureKind.validation);
      expect(repository.saved, isEmpty);
      expect(
        container.read(createBudgetControllerProvider).errorText,
        failure.message,
      );
    });

    test('a repository failure reaches the field, not the void', () async {
      final (:container, :repository) = build();
      repository.failNextAdd = const AppFailure.validation(
        'A monthly budget already covers Food & drink.',
      );
      final controller =
          container.read(
              createBudgetControllerProvider.notifier,
            )
            ..chooseCategory(SpendCategory.food)
            ..setLimit(const Money(4000000, vnd));

      final failure = await controller.submit();
      expect(failure, isNotNull);
      expect(
        container.read(createBudgetControllerProvider).errorText,
        'A monthly budget already covers Food & drink.',
      );
    });

    test('editing after an error clears the message', () async {
      // A message that outlives its cause is worse than none.
      final container = build().container;
      final controller = container.read(
        createBudgetControllerProvider.notifier,
      )..chooseCategory(SpendCategory.food);
      await controller.submit();
      expect(
        container.read(createBudgetControllerProvider).errorText,
        isNotNull,
      );

      controller.setLimit(const Money(4000000, vnd));
      expect(
        container.read(createBudgetControllerProvider).errorText,
        isNull,
      );
    });
  });

  group('canSubmit', () {
    test('needs both a category and an amount above zero', () {
      final container = build().container;
      final controller = container.read(
        createBudgetControllerProvider.notifier,
      );
      expect(container.read(createBudgetControllerProvider).canSubmit, isFalse);
      controller.chooseCategory(SpendCategory.food);
      expect(container.read(createBudgetControllerProvider).canSubmit, isFalse);

      controller.setLimit(const Money(4000000, vnd));
      expect(container.read(createBudgetControllerProvider).canSubmit, isTrue);

      controller.setLimit(const Money(0, vnd));
      expect(container.read(createBudgetControllerProvider).canSubmit, isFalse);
    });
  });

  group('unavailableCategories', () {
    Budget existing(SpendCategory category, BudgetPeriod period) =>
        Budget.fromStorage(
          id: category.name,
          category: category,
          limit: const Money(1000, vnd),
          period: period,
          startsOn: DateTime.utc(2026, 9),
          rollsOver: false,
          alertThreshold: 0.8,
          createdAt: DateTime.utc(2026, 9),
        );

    test('income categories are always unavailable', () {
      final map = unavailableCategories(
        budgets: const [],
        period: BudgetPeriod.monthly,
      );
      expect(map[SpendCategory.salary], CategoryUnavailable.income);
      expect(map[SpendCategory.food], isNull);
    });

    test('a category budgeted for this period is unavailable', () {
      final map = unavailableCategories(
        budgets: [existing(SpendCategory.food, BudgetPeriod.monthly)],
        period: BudgetPeriod.monthly,
      );
      expect(map[SpendCategory.food], CategoryUnavailable.alreadyBudgeted);
    });

    test('the same category under another period stays available', () {
      final map = unavailableCategories(
        budgets: [existing(SpendCategory.food, BudgetPeriod.weekly)],
        period: BudgetPeriod.monthly,
      );
      expect(map[SpendCategory.food], isNull);
    });

    test('gifts stay available, because a gift can go either way', () {
      final map = unavailableCategories(
        budgets: const [],
        period: BudgetPeriod.monthly,
      );
      expect(map[SpendCategory.gift], isNull);
    });
  });
}
