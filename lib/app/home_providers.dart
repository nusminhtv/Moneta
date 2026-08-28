/// Assembles Home's snapshot from the transactions feature.
///
/// This lives in `lib/app` because it is the only layer allowed to see two
/// features at once — `tool/check_architecture.dart` forbids
/// `features/home → features/transactions`. ADR 0004 chose this over inventing a
/// `HomeDataSource` interface that would have had exactly one implementation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// How many entries Home's recent list shows.
///
/// Figma `52:2` draws four. The screen is a summary with a "See all" link, not
/// the transactions list.
const int homeRecentLimit = 4;

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
HomeSnapshot buildSnapshot({
  required List<Transaction> all,
  required Currency currency,
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

  return HomeSnapshot(
    totalBalance: income - expenses,
    income: income,
    expenses: expenses,
    recent: [for (final t in sorted.take(limit)) toRecentEntry(t)],
  );
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
  final list = ref.watch(transactionListControllerProvider);

  return list.whenData(
    (state) => buildSnapshot(
      all: [for (final day in state.days) ...day.transactions],
      currency: currency,
    ),
  );
});
