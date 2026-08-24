import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';

// Re-exported so callers inside the feature need one import, while the enum
// itself stays in core where the design system can reach it.
export 'package:moneta/core/transaction_direction.dart';

/// One recorded movement of money.
final class Transaction extends Equatable {
  const Transaction._({
    required this.id,
    required this.amount,
    required this.direction,
    required this.category,
    required this.occurredAt,
    required this.createdAt,
    required this.note,
  });

  /// Validates and creates a transaction.
  ///
  /// Returns [Err] with a validation failure rather than throwing, so a caller
  /// reading a malformed row can decide what to do instead of crashing.
  static Result<Transaction> create({
    required String id,
    required Money amount,
    required TransactionDirection direction,
    required SpendCategory category,
    required DateTime occurredAt,
    required DateTime createdAt,
    String? note,
  }) {
    if (id.isEmpty) {
      return const Err(AppFailure.validation('A transaction needs an id'));
    }
    if (amount.minorUnits <= 0) {
      return const Err(
        AppFailure.validation(
          'Amount must be a positive magnitude; use direction for the sign',
        ),
      );
    }
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.length > maxNoteLength) {
      return const Err(
        AppFailure.validation('Note must be at most $maxNoteLength characters'),
      );
    }

    return Ok(
      Transaction._(
        id: id,
        amount: amount,
        direction: direction,
        category: category,
        // Storing and comparing in UTC is the only way two devices in different
        // zones agree about when something happened.
        occurredAt: occurredAt.toUtc(),
        createdAt: createdAt.toUtc(),
        // An empty note is the same as no note; keeping both would give two
        // representations of one state.
        note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      ),
    );
  }

  /// Longest note the app accepts.
  static const int maxNoteLength = 200;

  /// Stable unique identifier.
  final String id;

  /// Positive magnitude.
  final Money amount;

  /// Whether this is money in or out.
  final TransactionDirection direction;

  /// What it was for.
  final SpendCategory category;

  /// When it happened, in UTC.
  final DateTime occurredAt;

  /// When it was recorded, in UTC.
  final DateTime createdAt;

  /// Optional free text. Never an empty string.
  final String? note;

  /// The amount with its direction applied: negative for an expense.
  Money get signedAmount =>
      direction == TransactionDirection.expense ? -amount : amount;

  /// True when this is money in.
  bool get isIncome => direction == TransactionDirection.income;

  /// What to show as the row's primary line: the note, or the category name.
  String get displayTitle => note ?? category.label;

  /// Returns a copy with the given fields replaced, re-running validation.
  Result<Transaction> copyWith({
    Money? amount,
    TransactionDirection? direction,
    SpendCategory? category,
    DateTime? occurredAt,
    String? note,
    bool clearNote = false,
  }) {
    return Transaction.create(
      id: id,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      category: category ?? this.category,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    direction,
    category,
    occurredAt,
    createdAt,
    note,
  ];

  @override
  String toString() =>
      'Transaction($id, ${signedAmount.format()}, ${category.name}, '
      '${occurredAt.toIso8601String()})';
}
