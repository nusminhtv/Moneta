import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/presentation/create_budget_category_screen.dart';

/// The in-progress budget, held between the two steps.
///
/// Nothing is written until [CreateBudgetController.submit]. A half-created
/// budget row with no limit would need every reader to handle it, and there is
/// no draft the user asked to keep.
class CreateBudgetDraft {
  /// Creates a draft.
  const CreateBudgetDraft({
    required this.startsOn,
    required this.limit,
    this.category,
    this.period = BudgetPeriod.monthly,
    this.rollsOver = false,
    this.alertThreshold = BudgetStatus.defaultNearLimitThreshold,
    this.errorText,
  });

  /// The category from step 1, or null before one is chosen.
  final SpendCategory? category;

  /// The limit being entered.
  final Money limit;

  /// How often it resets.
  final BudgetPeriod period;

  /// The anchor date, UTC.
  final DateTime startsOn;

  /// Whether an unspent remainder raises the next period's limit.
  final bool rollsOver;

  /// Where the warning state begins.
  final double alertThreshold;

  /// The message shown on the amount, or null.
  final String? errorText;

  /// Whether step 2 can be submitted.
  bool get canSubmit => category != null && limit.minorUnits > 0;

  /// A copy with the given fields replaced.
  ///
  /// [errorText] clears unless explicitly given: every edit is an attempt to
  /// fix whatever the error was, and a message that outlives its cause is worse
  /// than none.
  CreateBudgetDraft copyWith({
    SpendCategory? category,
    Money? limit,
    BudgetPeriod? period,
    DateTime? startsOn,
    bool? rollsOver,
    double? alertThreshold,
    String? errorText,
  }) => CreateBudgetDraft(
    category: category ?? this.category,
    limit: limit ?? this.limit,
    period: period ?? this.period,
    startsOn: startsOn ?? this.startsOn,
    rollsOver: rollsOver ?? this.rollsOver,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    errorText: errorText,
  );
}

/// Drives the two-step create flow.
class CreateBudgetController extends Notifier<CreateBudgetDraft> {
  @override
  CreateBudgetDraft build() => CreateBudgetDraft(
    startsOn: _startOfDay(ref.watch(clockProvider).nowUtc()),
    limit: Money(0, ref.watch(walletCurrencyProvider)),
  );

  /// Chooses the category. A disabled one never reaches here.
  void chooseCategory(SpendCategory category) =>
      state = state.copyWith(category: category);

  /// Sets the limit.
  void setLimit(Money limit) => state = state.copyWith(limit: limit);

  /// Sets the period.
  void setPeriod(BudgetPeriod period) => state = state.copyWith(period: period);

  /// Sets the anchor date.
  void setStartsOn(DateTime date) =>
      state = state.copyWith(startsOn: _startOfDay(date.toUtc()));

  /// Flips the rollover setting.
  void toggleRollover() => state = state.copyWith(rollsOver: !state.rollsOver);

  /// Sets the alert threshold.
  void setAlertThreshold(double threshold) =>
      state = state.copyWith(alertThreshold: threshold);

  /// Abandons the draft, writing nothing.
  void reset() => ref.invalidateSelf();

  /// Creates the budget. Returns the failure to show, or null on success.
  Future<AppFailure?> submit() async {
    final category = state.category;
    if (category == null || state.limit.minorUnits <= 0) {
      const failure = AppFailure.validation(
        'Enter an amount above zero to create this budget.',
      );
      state = state.copyWith(errorText: failure.message);
      return failure;
    }

    final now = ref.read(clockProvider).nowUtc();
    final budget = Budget.create(
      id: ref.read(idGeneratorProvider).next(),
      category: category,
      limit: state.limit,
      period: state.period,
      startsOn: state.startsOn,
      createdAt: now,
      rollsOver: state.rollsOver,
      alertThreshold: state.alertThreshold,
    );
    if (budget case Err(:final failure)) {
      state = state.copyWith(errorText: failure.message);
      return failure;
    }

    final repository = await ref.read(budgetRepositoryProvider.future);
    final saved = await repository.add((budget as Ok<Budget>).value);
    if (saved case Err(:final failure)) {
      state = state.copyWith(errorText: failure.message);
      return failure;
    }

    ref.invalidate(budgetListProvider);
    return null;
  }

  /// Midnight UTC of [instant]'s day.
  ///
  /// A budget anchored at 14:32 would make its window boundaries fall
  /// mid-afternoon, so "1 September" would start on the afternoon of the 1st.
  static DateTime _startOfDay(DateTime instant) =>
      DateTime.utc(instant.year, instant.month, instant.day);
}

/// The create flow's state.
final createBudgetControllerProvider =
    NotifierProvider<CreateBudgetController, CreateBudgetDraft>(
      CreateBudgetController.new,
    );

/// Why each category cannot be budgeted for `period`, keyed by category.
///
/// Annotation `04.03` requires both rules, and requires the reason to be
/// written down rather than inferred from the dimming: income categories are
/// disabled because a budget caps spending, and a category that already has a
/// budget for this period is disabled because one budget per category per
/// period is what makes the totals mean anything.
///
/// A plain function rather than a family provider: it is pure, and a caller
/// with a list of budgets can test it without a container.
Map<SpendCategory, CategoryUnavailable> unavailableCategories({
  required List<Budget> budgets,
  required BudgetPeriod period,
}) {
  final taken = {
    for (final budget in budgets)
      if (budget.period == period) budget.category,
  };
  return {
    for (final category in SpendCategory.values)
      if (category.isIncome)
        category: CategoryUnavailable.income
      else if (taken.contains(category))
        category: CategoryUnavailable.alreadyBudgeted,
  };
}
