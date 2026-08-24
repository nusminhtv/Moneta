import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';

/// Totals for a period.
final class PeriodSummary extends Equatable {
  /// Creates a summary.
  const PeriodSummary({required this.income, required this.expenses});

  /// An all-zero summary in [currency].
  factory PeriodSummary.zero(Currency currency) => PeriodSummary(
    income: Money.zero(currency),
    expenses: Money.zero(currency),
  );

  /// Total money in.
  final Money income;

  /// Total money out, as a positive magnitude.
  final Money expenses;

  /// Income minus expenses.
  Money get net => income - expenses;

  @override
  List<Object?> get props => [income, expenses];

  @override
  String toString() =>
      'PeriodSummary(in ${income.format()}, out ${expenses.format()})';
}

/// Reading and writing transactions.
///
/// Implementations return [Result] and do not throw for expected failures, so
/// a caller cannot mistake a storage error for an empty wallet.
abstract interface class TransactionRepository {
  /// Reads transactions matching [query], newest first.
  Future<Result<List<Transaction>>> list(TransactionQuery query);

  /// Records [transaction].
  Future<Result<Transaction>> add(Transaction transaction);

  /// Deletes the transaction with [id].
  ///
  /// Reports a not-found failure when nothing matched, rather than success —
  /// silently succeeding hides a stale UI.
  Future<Result<void>> delete(String id);

  /// Totals for [query]'s range, computed by the database.
  Future<Result<PeriodSummary>> summarise(TransactionQuery query);
}
