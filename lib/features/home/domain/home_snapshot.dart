import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';

/// One row in Home's recent list.
///
/// A pure value type over `core` types only. Home renders these; it never sees a
/// `Transaction`, a repository or a database.
final class RecentEntry extends Equatable {
  /// Creates a recent entry.
  const RecentEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.direction,
    required this.category,
    required this.occurredAt,
  });

  /// Stable identity, so a list can key its rows.
  final String id;

  /// What to show as the row's title.
  final String title;

  /// The amount moved. Always positive; [direction] carries the sign.
  final Money amount;

  /// Which way the money went.
  ///
  /// `TransactionDirection` lives in `lib/core`, so `features/home` may use it
  /// directly — no duplicate enum, and no mapping to get wrong.
  final TransactionDirection direction;

  /// The category, which fixes the row's colour and glyph.
  final SpendCategory category;

  /// When it happened, in UTC.
  final DateTime occurredAt;

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    direction,
    category,
    occurredAt,
  ];
}

/// Everything Home needs to render, assembled before it is built.
///
/// Home takes one of these and does no arithmetic of its own beyond grouping the
/// recent list by day. Totals are computed where the 85% coverage gate reaches
/// them, which `presentation` is not.
final class HomeSnapshot extends Equatable {
  /// Creates a snapshot.
  const HomeSnapshot({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.recent,
  });

  /// An empty wallet — a first run, before anything is recorded.
  factory HomeSnapshot.empty(Currency currency) => HomeSnapshot(
    totalBalance: Money.zero(currency),
    income: Money.zero(currency),
    expenses: Money.zero(currency),
    recent: const [],
  );

  /// Income minus expenses, across everything recorded up to now.
  final Money totalBalance;

  /// Money in over the period.
  final Money income;

  /// Money out over the period, as a positive amount.
  final Money expenses;

  /// The most recent entries, newest first.
  final List<RecentEntry> recent;

  /// Whether there is nothing at all to show.
  bool get isEmpty => recent.isEmpty;

  @override
  List<Object?> get props => [totalBalance, income, expenses, recent];
}
