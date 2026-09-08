import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_repository.dart';

/// SQLite-backed [BudgetRepository].
///
/// The only layer that catches storage exceptions; everything above sees
/// [Result].
final class SqliteBudgetRepository implements BudgetRepository {
  /// Creates a repository over [dao].
  const SqliteBudgetRepository(this.dao);

  /// SQL access.
  final BudgetDao dao;

  @override
  Future<Result<List<Budget>>> list() async {
    try {
      return Ok(await dao.all());
    } on Object catch (error) {
      return Err(AppFailure.storage('Could not read budgets', cause: error));
    }
  }

  @override
  Future<Result<Budget>> byId(String id) async {
    try {
      final budget = await dao.byId(id);
      if (budget == null) {
        return Err(AppFailure.notFound('No budget with id $id'));
      }
      return Ok(budget);
    } on Object catch (error) {
      return Err(AppFailure.storage('Could not read the budget', cause: error));
    }
  }

  @override
  Future<Result<void>> add(Budget budget) async {
    // Checked here for the message, and by a unique index for the guarantee.
    // This read-then-write is a race between two concurrent adds; the index is
    // what actually prevents two budgets over one category.
    final duplicate = await exists(
      category: budget.category,
      period: budget.period,
    );
    switch (duplicate) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: true):
        return Err(
          AppFailure.validation(
            'A ${budget.period.label.toLowerCase()} budget already covers '
            '${budget.category.label}. Two budgets over one category would '
            'split the same spend between them.',
          ),
        );
      case Ok():
        break;
    }

    try {
      await dao.insert(budget);
      return const Ok(null);
    } on Object catch (error) {
      return Err(AppFailure.storage('Could not save the budget', cause: error));
    }
  }

  @override
  Future<Result<void>> update(Budget budget) async {
    try {
      final rows = await dao.update(budget);
      if (rows == 0) {
        return Err(AppFailure.notFound('No budget with id ${budget.id}'));
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not update the budget', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> remove(String id) async {
    try {
      // Removing a budget that is not there is not an error: the caller wanted
      // it gone and it is gone.
      await dao.delete(id);
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not delete the budget', cause: error),
      );
    }
  }

  @override
  Future<Result<bool>> exists({
    required SpendCategory category,
    required BudgetPeriod period,
  }) async {
    try {
      return Ok(await dao.exists(category: category, period: period));
    } on Object catch (error) {
      return Err(AppFailure.storage('Could not read budgets', cause: error));
    }
  }
}
