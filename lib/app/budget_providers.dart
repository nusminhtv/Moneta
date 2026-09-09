/// Wiring for budgets.
///
/// This file is the bridge the architecture rules require: `features/budgets`
/// may not import `features/transactions`, and `lib/app` may import anything.
/// So the mapping from the ledger onto [SpendEntry] lives here and nowhere else.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/budgets/data/budget_dao.dart';
import 'package:moneta/features/budgets/data/sqlite_budget_repository.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
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

/// How many periods the switcher on `66:117` offers.
///
/// Three, as authored — `66:118`, `66:120`, `66:122`.
const int budgetPeriodSegments = 3;

/// One budget's progress [offset] periods back from [now], or null if the
/// budget did not exist that far back.
///
/// Null rather than its first window: a budget created last month has no
/// figures for the month before, and showing its opening window under an
/// earlier label would invent history.
BudgetProgress? progressAt({
  required Budget budget,
  required List<SpendEntry> entries,
  required DateTime now,
  required int offset,
}) {
  var window = budget.windowAt(now);
  for (var i = 0; i < offset; i++) {
    final earlier = window.previous(budget.period, anchor: budget.startsOn);
    if (earlier == null) return null;
    window = earlier;
  }
  // `window.start` is inclusive, so the window containing it is `window`.
  return BudgetProgress.compute(
    budget: budget,
    entries: entries,
    now: window.start,
  );
}

/// Every budget's progress [offset] periods back, worst first.
///
/// The switcher at `66:117` selects **which period to look at** — its authored
/// labels are `Jul`, `Aug`, `Sep`. It is not a filter on the *kind* of period a
/// budget uses, which is what this screen did until 2026-09-09: it showed only
/// budgets whose `BudgetPeriod` matched the selected segment, so tapping a
/// segment could empty the list and drive the "No budgets yet" state for a user
/// who has several. A budget's period is fixed when it is created; there is
/// nothing to switch between.
///
/// Each budget steps back through **its own** periods, so a weekly budget moves
/// a week while a monthly one moves a month. That is what makes
/// "every card recomputes against the new window" mean anything for a mixed
/// set.
List<BudgetProgress> progressAtOffset({
  required List<Budget> budgets,
  required List<SpendEntry> entries,
  required DateTime now,
  required int offset,
}) {
  final out = <BudgetProgress>[];
  for (final budget in budgets) {
    final p = progressAt(
      budget: budget,
      entries: entries,
      now: now,
      offset: offset,
    );
    if (p != null) out.add(p);
  }
  return out..sort(compareWorstFirst);
}

/// The three segment labels for `66:117`, newest last.
///
/// **The labelling rule is a decision, not a transcription.** `66:117` authors
/// `Jul / Aug / Sep`, which is what a set of monthly budgets should read — but
/// the file only ever shows monthly budgets, and one row of three labels has to
/// serve a mixed set too. So: when every budget shares a period, the labels name
/// that kind of calendar period; when periods are mixed, or there are no budgets
/// to read a period from, they fall back to relative words.
///
/// **They are computed from [now] alone, never from a budget's windows.** Two
/// defects came from doing the latter, both found by review:
///
/// - Walking back through `BudgetWindow.previous` stopped at the budget's anchor
///   and reused the last window it reached, so a wallet younger than three
///   periods got the *same label three times* — `[Sep, Sep, Sep]` on a budget
///   created this month. That is the first-run path, and tapping two of three
///   identical segments showed "nothing to show for this period".
/// - The walk needed one budget to read an anchor from, and took
///   `budgets.first`. `BudgetDao.all()` has no `ORDER BY`, so the labels moved
///   with database row order: the same wallet could label the current segment
///   `Aug` on 15 September depending on which row came back first.
///
/// A label names a calendar period, so it must not depend on which budgets
/// exist or on how they are stored. What each budget *does* at a given offset is
/// still per-budget — see [progressAtOffset].
List<String> budgetPeriodLabels({
  required List<Budget> budgets,
  required DateTime now,
  String? locale,
}) {
  final periods = {for (final b in budgets) b.period};
  if (periods.length != 1) {
    return const ['Two back', 'Last', 'This'];
  }

  final local = now.toLocal();
  final labels = <String>[];
  for (var offset = budgetPeriodSegments - 1; offset >= 0; offset--) {
    labels.add(
      switch (periods.single) {
        BudgetPeriod.monthly => DateFormat.MMM(locale).format(
          DateTime(local.year, local.month - offset),
        ),
        BudgetPeriod.yearly => DateFormat.y(locale).format(
          DateTime(local.year - offset),
        ),
        BudgetPeriod.weekly => DateFormat.MMMd(locale).format(
          local.subtract(Duration(days: 7 * offset)),
        ),
      },
    );
  }
  return labels;
}
