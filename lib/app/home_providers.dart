/// Assembles Home's snapshot from the transactions feature.
///
/// This lives in `lib/app` because it is the only layer allowed to see two
/// features at once — `tool/check_architecture.dart` forbids
/// `features/home → features/transactions`. ADR 0004 chose this over inventing a
/// `HomeDataSource` interface that would have had exactly one implementation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/presentation/budgets_screen.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// How many entries Home's recent list shows.
///
/// **Five, from annotation `52:362`:** *"Recent list is capped at 5 rows
/// client-side."*
///
/// This was four, justified in a comment reading "Figma `52:2` draws four".
/// The frame does draw four. But a frame draws one instance of a rule, and the
/// rule was written down in the annotation next to it, which nobody had read.
/// Counting instances in a drawing is not reading a specification.
const int homeRecentLimit = 5;

/// One transaction, as Home sees it.
///
/// The title falls back to the category name, matching the transactions list:
/// a blank row reads as a rendering fault rather than as a note nobody wrote.
RecentEntry toRecentEntry(Transaction transaction) => RecentEntry(
  id: transaction.id,
  title: transaction.note?.trim().isNotEmpty ?? false
      ? transaction.note!.trim()
      : transaction.category.label,
  amount: transaction.amount,
  direction: transaction.direction,
  category: transaction.category,
  occurredAt: transaction.occurredAt,
);

/// Totals across every recorded transaction, plus the newest few.
///
/// Balance is income minus expenses over **everything**, not over the period:
/// a balance that resets each month is not a balance. Income and expenses are
/// the period figures the card shows beside it.
///
/// [budgets] must already be ranked worst-first, and must be **every** budget
/// in the current period — never a display-capped subset. This function does not
/// reorder them. It subtracts their unspent remainder from the balance to reach
/// safe-to-spend.
///
/// This doc comment used to say "ranked worst-first **and capped**", which is
/// the instruction that produced the bug it now warns against.
HomeSnapshot buildSnapshot({
  required List<Transaction> all,
  required Currency currency,
  List<BudgetSummary> budgets = const [],
  int limit = homeRecentLimit,
}) {
  var income = Money.zero(currency);
  var expenses = Money.zero(currency);

  for (final transaction in all) {
    // Mixing currencies would make the sum meaningless, so anything outside the
    // wallet's currency is skipped rather than silently added. The wallet is
    // single-currency today; when it is not, this is where it breaks loudly.
    if (transaction.amount.currency != currency) continue;
    switch (transaction.direction) {
      case TransactionDirection.income:
        income += transaction.amount;
      case TransactionDirection.expense:
        expenses += transaction.amount;
    }
  }

  final sorted = [...all]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final balance = income - expenses;

  return HomeSnapshot(
    totalBalance: balance,
    income: income,
    expenses: expenses,
    recent: [for (final t in sorted.take(limit)) toRecentEntry(t)],
    safeToSpend: safeToSpend(balance: balance, budgets: budgets),
    budgets: budgets,
  );
}

/// The balance minus what every budget still has unspent.
///
/// Annotation `52:362`: *"safe-to-spend = balance minus committed budgets minus
/// scheduled bills to period end."*
///
/// **It subtracts the unspent remainder, not the whole limit.** Money already
/// spent against a budget has already left the balance, so subtracting the full
/// limit would deduct it twice and understate what is safe to spend — a budget
/// of 5m fully spent would cost the user 10m of headroom. The annotation's two
/// terms are parallel and both name *future* outflows: budget money not yet
/// spent, and bills not yet paid. `BudgetProgress.remaining` clamps at zero, and
/// [BudgetSummary.remaining] matches it, so an overspent budget subtracts
/// nothing further rather than adding headroom back.
///
/// **The scheduled-bills term is missing and stays missing.** There is no bill
/// entity, table or concept in this codebase. Completing the formula would mean
/// inventing a domain from one clause of one annotation, which is exactly how
/// the invented spacing scale happened; the shortfall is recorded in
/// `docs/design-system/figma-map.md` instead.
///
/// Foreign-currency budgets are skipped for the same reason [buildSnapshot]
/// skips foreign transactions: adding them would produce a meaningless number.
Money safeToSpend({
  required Money balance,
  required List<BudgetSummary> budgets,
}) {
  var committed = Money.zero(balance.currency);
  for (final budget in budgets) {
    if (budget.remaining.currency != balance.currency) continue;
    committed += budget.remaining;
  }
  return balance - committed;
}

/// Home's data.
///
/// Derived from `transactionListControllerProvider`, **not** from a second read
/// of the repository. It used to do its own `repository.list(...)`, which made
/// two sources of truth: adding a transaction updated the controller's state
/// and left Home's future untouched, so the Transactions tab showed the new row
/// and Home did not until the app restarted.
///
/// Watching the controller means every mutation it knows about — add, delete,
/// undo — reaches Home for free, and there is no invalidation to remember.
final homeSnapshotProvider = Provider<AsyncValue<HomeSnapshot>>((ref) {
  final currency = ref.watch(walletCurrencyProvider);
  final now = ref.watch(clockProvider).nowUtc();
  final list = ref.watch(transactionListControllerProvider);
  final progress = ref.watch(budgetProgressProvider);

  // Home waits for budgets as well as transactions. Rendering as soon as the
  // ledger lands would paint safe-to-spend equal to the balance and then correct
  // it a frame later, so the first number the user reads would be the wrong one.
  // Both reads hit the same database, so this costs nothing in practice.
  if (progress case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  final ranked = progress.value;
  if (ranked == null) return const AsyncLoading();

  return list.whenData(
    (state) => buildSnapshot(
      all: [for (final day in state.days) ...day.transactions],
      currency: currency,
      // **Every** current-period budget, uncapped. How many cards Home
      // *shows* is a display decision and now lives in `HomeScreen`; while it
      // lived here it reached `safeToSpend` and made the figure wrong. Because
      // `compareWorstFirst` ranks by fraction used descending, capping drops
      // the *least*-used budgets — precisely the ones with the largest unspent
      // commitments — so safe-to-spend was overstated, and by more the more
      // budgets the user had. A limit on what a screen draws must not be able
      // to change what a number means.
      budgets: [for (final entry in ranked) toBudgetSummary(entry, now)],
    ),
  );
});

/// One budget's progress, as Home sees it.
///
/// The note reuses `BudgetsScreen.noteFor` rather than formatting its own. The
/// authored copy at `52:125` is *"61% used · 9 days left"*, which is the same
/// sentence the Budgets screen already builds; writing it twice would let the
/// same budget describe itself differently on two screens, and only one of them
/// would get fixed when the wording changed.
BudgetSummary toBudgetSummary(BudgetProgress progress, DateTime now) =>
    BudgetSummary(
      id: progress.budget.id,
      category: progress.budget.category,
      spent: progress.spent,
      limit: progress.effectiveLimit,
      // Home only ever shows the current period, so this window has not ended
      // and the note keeps its "days left" clause. Passed rather than defaulted
      // because the default used to be a finished month claiming days left.
      note: BudgetsScreen.noteFor(progress, asOf: now),
      alertThreshold: progress.budget.alertThreshold,
    );
