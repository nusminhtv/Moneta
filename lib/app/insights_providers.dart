/// Composes the Insights feature.
///
/// Lives in `lib/app` for the same reason `notification_providers.dart` does:
/// `features/insights` may not import `features/transactions`, and the
/// composition root is the only layer allowed to see both. It maps repository
/// rows into the feature's own `InsightsEntry` — six fields, which is what the
/// aggregation actually reads.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/features/insights/domain/insights_entry.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// The period every Insights screen is looking at.
///
/// One value for the whole feature, because `77:291` says the period is shared:
/// *"month · 3M / 6M / Year change the period, not the layout"*, and a
/// per-screen period would make moving between screens change the answer.
class InsightsPeriodController extends Notifier<InsightsPeriod> {
  @override
  InsightsPeriod build() => InsightsPeriod.thisMonth;

  /// The active period.
  InsightsPeriod get period => state;

  /// Selects [period].
  set period(InsightsPeriod period) => state = period;
}

/// See [InsightsPeriodController].
final insightsPeriodProvider =
    NotifierProvider<InsightsPeriodController, InsightsPeriod>(
      InsightsPeriodController.new,
    );

/// Every ledger row, as the Insights aggregation needs it.
final insightsEntriesProvider = FutureProvider<List<InsightsEntry>>((
  ref,
) async {
  final repository = await ref.watch(transactionRepositoryProvider.future);
  final listed = await repository.list(TransactionQuery.all);

  return listed.when(
    ok: (transactions) => [
      for (final transaction in transactions) entryOf(transaction),
    ],
    // Thrown, not returned empty: `AsyncValue.error` is how the screen tells
    // "we could not look" apart from "there is nothing here", and those are
    // different screens.
    err: (failure) => throw StateError(failure.message),
  );
});

/// Maps one ledger row into the Insights feature's own type.
///
/// The title falls back to the category's name, because `77:2` lists these
/// rows under a heading about *merchants* and a row with no label at all reads
/// as a bug.
InsightsEntry entryOf(Transaction transaction) => InsightsEntry(
  id: transaction.id,
  title: transaction.note?.trim().isNotEmpty ?? false
      ? transaction.note!.trim()
      : transaction.category.label,
  category: transaction.category,
  direction: transaction.direction,
  amount: transaction.amount,
  occurredAt: transaction.occurredAt,
);

/// The figures for the selected period.
final insightsSummaryProvider = FutureProvider<InsightsSummary>((ref) async {
  final entries = await ref.watch(insightsEntriesProvider.future);
  return InsightsSummary.of(
    entries: entries,
    period: ref.watch(insightsPeriodProvider),
    now: ref.watch(clockProvider).nowUtc(),
    currency: ref.watch(walletCurrencyProvider),
  );
});
