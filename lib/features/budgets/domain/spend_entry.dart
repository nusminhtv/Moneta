import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';

/// One movement of money, as far as a budget is concerned.
///
/// Budgets measure transactions, but `features/budgets` may not import
/// `features/transactions` — cross-feature imports are forbidden, and
/// `tool/check_architecture.dart` rejects them. Rather than move `Transaction`
/// into `core` to satisfy one consumer, budgets state the shape they need and
/// `lib/app` maps the ledger onto it.
///
/// It carries [direction] rather than only expenses, so the rule *"a refund
/// recorded as income in this category is not spend"* is a rule of the budget
/// domain with a test, not a filter buried in whoever built the list.
class SpendEntry extends Equatable {
  /// Creates an entry.
  const SpendEntry({
    required this.id,
    required this.category,
    required this.direction,
    required this.amount,
    required this.occurredAt,
  });

  /// The originating transaction's id, so a screen can find it again.
  final String id;

  /// What the money was for.
  final SpendCategory category;

  /// Which way it moved.
  final TransactionDirection direction;

  /// A positive magnitude; the sign lives in [direction].
  final Money amount;

  /// When it happened, UTC.
  final DateTime occurredAt;

  @override
  List<Object?> get props => [id, category, direction, amount, occurredAt];
}
