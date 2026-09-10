import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';

/// One transaction, as the Insights aggregation needs it.
///
/// **Its own type, not `Transaction`.** `tool/check_architecture.dart` forbids
/// `features/insights` from importing `features/transactions`, and that rule is
/// right here rather than inconvenient: the aggregation reads six fields, so
/// taking six fields makes that true in the type instead of in a comment.
/// `lib/app/insights_providers.dart` maps repository rows into this.
///
/// Same shape and same reason as `features/budgets`' `SpendEntry`.
@immutable
class InsightsEntry extends Equatable {
  /// Creates an entry.
  const InsightsEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.direction,
    required this.amount,
    required this.occurredAt,
  });

  /// The originating transaction's id, so a screen can find it again.
  final String id;

  /// What to call it in a list — the note, or the category's name.
  final String title;

  /// What the money was for.
  final SpendCategory category;

  /// In or out.
  final TransactionDirection direction;

  /// A positive magnitude; the sign lives in [direction].
  final Money amount;

  /// When it happened, in UTC.
  final DateTime occurredAt;

  /// Whether this entry is money leaving.
  bool get isExpense => direction == TransactionDirection.expense;

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    direction,
    amount,
    occurredAt,
  ];
}
