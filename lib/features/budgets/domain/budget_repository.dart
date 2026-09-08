import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';

/// Storage for budgets.
///
/// Returns [Result] rather than throwing: a duplicate category and a missing
/// budget are expected outcomes of a form and a stale link, not programming
/// errors.
abstract interface class BudgetRepository {
  /// Every budget, in no particular order — ranking is a domain concern and
  /// depends on spend, which storage does not hold.
  Future<Result<List<Budget>>> list();

  /// One budget, or a `notFound` failure.
  Future<Result<Budget>> byId(String id);

  /// Saves a new budget.
  ///
  /// Fails with `validation` when a budget already exists for the same category
  /// and period: two budgets over one category would split the same spend
  /// between them and neither total would mean anything.
  Future<Result<void>> add(Budget budget);

  /// Replaces an existing budget.
  Future<Result<void>> update(Budget budget);

  /// Removes a budget. Removing one that is not there is not an error.
  Future<Result<void>> remove(String id);

  /// Whether a budget already covers [category] for [period].
  Future<Result<bool>> exists({
    required SpendCategory category,
    required BudgetPeriod period,
  });
}
