import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/features/settings/domain/category_usage.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// Which direction `08.08` is filtering by.
class CategoryFilterController extends Notifier<TransactionDirection> {
  @override
  TransactionDirection build() => TransactionDirection.expense;

  /// The chosen direction.
  TransactionDirection get direction => state;

  /// Selects [direction].
  set direction(TransactionDirection direction) => state = direction;
}

/// See [CategoryFilterController].
final categoryFilterProvider =
    NotifierProvider<CategoryFilterController, TransactionDirection>(
      CategoryFilterController.new,
    );

/// Every ledger row, as the usage count needs it.
///
/// The mapping lives here rather than in `features/settings` because
/// `tool/check_architecture.dart` forbids one feature importing another —
/// `lib/app` may import anything, which is the same reason
/// `insights_providers.dart` maps rows into `InsightsEntry` here.
final usageEntriesProvider = FutureProvider<List<UsageEntry>>((ref) async {
  final repository = await ref.watch(transactionRepositoryProvider.future);
  final listed = await repository.list(TransactionQuery.all);

  return listed.when(
    ok: (transactions) => [
      for (final transaction in transactions) usageEntryOf(transaction),
    ],
    // Thrown, not returned empty: "we could not look" and "there is nothing
    // here" are different screens.
    err: (failure) => throw StateError(failure.message),
  );
});

/// Maps one ledger row into the three fields the count reads.
UsageEntry usageEntryOf(Transaction transaction) => UsageEntry(
  category: transaction.category,
  direction: transaction.direction,
  amount: transaction.amount,
  occurredAt: transaction.occurredAt,
);

/// One row per category for the chosen direction, this month.
final categoryUsageProvider = FutureProvider<List<CategoryUsage>>((ref) async {
  final entries = await ref.watch(usageEntriesProvider.future);
  final window = monthWindow(ref.watch(clockProvider));

  return categoryUsage(
    entries: entries,
    direction: ref.watch(categoryFilterProvider),
    startUtc: window.startUtc,
    endUtc: window.endUtc,
    // The wallet's currency: a category with no transactions has to show a
    // zero in *some* currency, and this is the one every other screen uses.
    currency: ref.watch(walletCurrencyProvider),
  );
});
