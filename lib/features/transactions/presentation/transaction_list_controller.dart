import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:moneta/features/transactions/presentation/day_grouping.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// A deletion the user can still undo.
final class PendingUndo extends Equatable {
  /// Creates a pending undo.
  const PendingUndo({required this.transaction, required this.expiresAt});

  /// The removed transaction, held so undo restores the same record — same id,
  /// same fields — rather than a copy.
  final Transaction transaction;

  /// When the undo window closes, in UTC.
  final DateTime expiresAt;

  @override
  List<Object?> get props => [transaction, expiresAt];
}

/// What the transaction list screen renders.
final class TransactionListState extends Equatable {
  /// Creates a state.
  const TransactionListState({
    required this.days,
    required this.summary,
    this.pendingUndo,
  });

  /// Transactions grouped by local day, most recent first.
  final List<TransactionDay> days;

  /// Totals for the period.
  final PeriodSummary summary;

  /// The deletion still inside its undo window, if any.
  final PendingUndo? pendingUndo;

  /// True when there is nothing to show.
  ///
  /// Distinct from a failure: an empty wallet and an unreadable one are
  /// different situations and the screen renders them differently.
  bool get isEmpty => days.isEmpty;

  /// Returns a copy with the given fields replaced.
  TransactionListState copyWith({
    List<TransactionDay>? days,
    PeriodSummary? summary,
    PendingUndo? pendingUndo,
    bool clearPendingUndo = false,
  }) {
    return TransactionListState(
      days: days ?? this.days,
      summary: summary ?? this.summary,
      pendingUndo: clearPendingUndo ? null : (pendingUndo ?? this.pendingUndo),
    );
  }

  @override
  List<Object?> get props => [days, summary, pendingUndo];
}

/// Loads and mutates the transaction list.
class TransactionListController extends AsyncNotifier<TransactionListState> {
  /// How long a deletion stays undoable.
  ///
  /// A product decision, not a design transcription: Figma's `Snackbar`
  /// component has no duration property.
  static const Duration undoWindow = Duration(seconds: 5);

  TransactionQuery _query = TransactionQuery.all;

  /// The filter currently applied.
  TransactionQuery get query => _query;

  @override
  Future<TransactionListState> build() => _load();

  Future<TransactionListState> _load() async {
    final repository = await ref.watch(transactionRepositoryProvider.future);
    final currency = ref.watch(walletCurrencyProvider);

    final listed = await repository.list(_query);
    if (listed is Err<List<Transaction>>) {
      // Thrown, not returned as an empty list: AsyncValue.error is how the
      // screen tells "we could not look" apart from "there is nothing here".
      throw TransactionListFailure(listed.failure);
    }

    final summarised = await repository.summarise(_query);
    if (summarised is Err<PeriodSummary>) {
      throw TransactionListFailure(summarised.failure);
    }

    return TransactionListState(
      days: groupByLocalDay((listed as Ok<List<Transaction>>).value, currency),
      summary: (summarised as Ok<PeriodSummary>).value,
      pendingUndo: state.value?.pendingUndo,
    );
  }

  /// Reloads, showing a loading state.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Applies [query] and reloads.
  Future<void> applyFilter(TransactionQuery query) async {
    _query = query;
    await refresh();
  }

  /// Records [transaction] and reloads so the list shows it immediately.
  Future<Result<Transaction>> add(Transaction transaction) async {
    final repository = await ref.read(transactionRepositoryProvider.future);
    final result = await repository.add(transaction);
    if (result.isOk) await refresh();
    return result;
  }

  /// Deletes [transaction] and opens an undo window.
  ///
  /// The delete is real immediately — no `deleted_at` column — and the entity
  /// is held in memory so undo can re-insert the same record. If the process
  /// dies inside the window, the deletion stands, which is the correct reading
  /// of "the user deleted it".
  Future<Result<void>> delete(Transaction transaction) async {
    final repository = await ref.read(transactionRepositoryProvider.future);
    final clock = ref.read(clockProvider);

    final result = await repository.delete(transaction.id);
    if (result is Err<void>) return result;

    await refresh();
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          pendingUndo: PendingUndo(
            transaction: transaction,
            expiresAt: clock.nowUtc().add(undoWindow),
          ),
        ),
      );
    }
    return const Ok(null);
  }

  /// Restores the pending deletion, if the window is still open.
  Future<Result<void>> undoDelete() async {
    final pending = state.value?.pendingUndo;
    if (pending == null) {
      return const Err(AppFailure.notFound('Nothing to undo'));
    }

    final clock = ref.read(clockProvider);
    if (!clock.nowUtc().isBefore(pending.expiresAt)) {
      _clearPendingUndo();
      return const Err(AppFailure.notFound('The undo window has closed'));
    }

    final repository = await ref.read(transactionRepositoryProvider.future);
    final result = await repository.add(pending.transaction);
    if (result is Err<Transaction>) return Err(result.failure);

    await refresh();
    _clearPendingUndo();
    return const Ok(null);
  }

  /// Drops the pending undo without restoring it.
  void dismissUndo() => _clearPendingUndo();

  void _clearPendingUndo() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(clearPendingUndo: true));
    }
  }
}

/// Wraps an [AppFailure] so it can travel through [AsyncValue.error].
final class TransactionListFailure implements Exception {
  /// Creates the wrapper.
  const TransactionListFailure(this.failure);

  /// The underlying failure.
  final AppFailure failure;

  @override
  String toString() => failure.message;
}

/// The transaction list.
final transactionListControllerProvider =
    AsyncNotifierProvider<TransactionListController, TransactionListState>(
      TransactionListController.new,
    );
