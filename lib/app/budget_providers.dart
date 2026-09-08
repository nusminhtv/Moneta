/// Wiring for budgets.
///
/// This file is the bridge the architecture rules require: `features/budgets`
/// may not import `features/transactions`, and `lib/app` may import anything.
/// So the mapping from the ledger onto [SpendEntry] lives here and nowhere else.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/data/sqlite_budget_repository.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/budget_repository.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';

/// Storage for budgets.
final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final opened = await ref.watch(appDatabaseProvider).open();
  return opened.when(
    ok: (db) => SqliteBudgetRepository(BudgetDao(db)),
    // Same reasoning as the transaction repository: a repository that cannot be
    // built is not something a caller can work around, and a FutureProvider's
    // error state is what the UI already renders.
    err: (failure) => throw StateError(failure.message),
  );
});

/// The stored budgets, unranked — ranking needs spend, which storage lacks.
final budgetListProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = await ref.watch(budgetRepositoryProvider.future);
  final result = await repository.list();
  return result.when(ok: (budgets) => budgets, err: (_) => const []);
});

/// Maps one transaction onto the shape budgets understand.
SpendEntry toSpendEntry(Transaction transaction) => SpendEntry(
  id: transaction.id,
  category: transaction.category,
  direction: transaction.direction,
  amount: transaction.amount,
  occurredAt: transaction.occurredAt,
);

/// Every transaction, as budget input.
///
/// Derived from `transactionListControllerProvider`, **not** from a second read
/// of the repository. Home learned that lesson the expensive way: a screen with
/// its own read of the ledger goes stale the moment a transaction is added, and
/// no amount of remembering to invalidate fixes it reliably.
final spendEntriesProvider = Provider<AsyncValue<List<SpendEntry>>>((ref) {
  return ref
      .watch(transactionListControllerProvider)
      .whenData(
        (state) => [
          for (final day in state.days)
            for (final transaction in day.transactions)
              toSpendEntry(transaction),
        ],
      );
});

/// Every budget with its computed progress, worst first.
///
/// Annotation `04.01`: *"cards sort by percentage used descending, so an
/// over-limit budget can never be below the fold."*
final budgetProgressProvider = Provider<AsyncValue<List<BudgetProgress>>>((
  ref,
) {
  final now = ref.watch(clockProvider).nowUtc();
  final budgets = ref.watch(budgetListProvider);
  final entries = ref.watch(spendEntriesProvider);

  if (budgets case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  if (entries case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  final budgetList = budgets.value;
  final entryList = entries.value;
  if (budgetList == null || entryList == null) return const AsyncLoading();

  final progress = <BudgetProgress>[
    for (final budget in budgetList)
      BudgetProgress.compute(budget: budget, entries: entryList, now: now),
  ]..sort(compareWorstFirst);
  return AsyncData(progress);
});
