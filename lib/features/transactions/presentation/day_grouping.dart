import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

/// One calendar day's transactions, with the day's net.
final class TransactionDay extends Equatable {
  /// Creates a day group.
  const TransactionDay({
    required this.date,
    required this.transactions,
    required this.net,
  });

  /// Midnight at the start of the day, in the device's **local** zone.
  final DateTime date;

  /// The day's transactions, in the order they arrived (newest first).
  final List<Transaction> transactions;

  /// Income minus expenses for the day.
  final Money net;

  @override
  List<Object?> get props => [date, transactions, net];

  @override
  String toString() =>
      'TransactionDay(${date.toIso8601String()}, '
      '${transactions.length} txs, net ${net.format()})';
}

/// Groups [transactions] by local calendar day, preserving their order.
///
/// Grouping is by **local** day while storage is UTC, which is why this happens
/// here and not in SQL: a `GROUP BY` would have to bake in a fixed offset, and
/// that is wrong the moment the device changes zone or crosses a DST boundary.
///
/// [currency] is needed because an empty input still has to produce well-formed
/// zero totals, and a currency cannot be inferred from nothing.
List<TransactionDay> groupByLocalDay(
  List<Transaction> transactions,
  Currency currency,
) {
  if (transactions.isEmpty) return const [];

  final byDate = <DateTime, List<Transaction>>{};
  for (final transaction in transactions) {
    final local = transaction.occurredAt.toLocal();
    // Constructing from y/m/d rather than subtracting a duration: a day with a
    // DST transition is 23 or 25 hours, so "midnight minus 24 hours" lands in
    // the wrong day twice a year.
    final date = DateTime(local.year, local.month, local.day);
    (byDate[date] ??= []).add(transaction);
  }

  final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

  return [
    for (final date in dates)
      TransactionDay(
        date: date,
        transactions: List.unmodifiable(byDate[date]!),
        net: byDate[date]!.fold(
          Money.zero(currency),
          (total, t) => total + t.signedAmount,
        ),
      ),
  ];
}
