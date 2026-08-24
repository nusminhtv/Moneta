import 'package:equatable/equatable.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';

/// A filtered read of the transaction store.
///
/// The date range is **inclusive of [start] and exclusive of [end]**, so
/// adjacent ranges neither overlap nor drop a transaction that lands exactly on
/// a boundary. Every caller that slices by month depends on that.
final class TransactionQuery extends Equatable {
  const TransactionQuery._({
    required this.categories,
    required this.start,
    required this.end,
    required this.limit,
  });

  /// Everything, unfiltered.
  static const TransactionQuery all = TransactionQuery._(
    categories: {},
    start: null,
    end: null,
    limit: null,
  );

  /// Builds a query, validating the range.
  ///
  /// An inverted range is a caller bug. It is reported as a validation failure
  /// rather than quietly matching nothing, because an empty list would look
  /// like "no transactions" and hide it.
  static Result<TransactionQuery> build({
    Set<SpendCategory> categories = const {},
    DateTime? start,
    DateTime? end,
    int? limit,
  }) {
    final utcStart = start?.toUtc();
    final utcEnd = end?.toUtc();

    if (utcStart != null && utcEnd != null && !utcEnd.isAfter(utcStart)) {
      return const Err(
        AppFailure.validation('Range end must be after range start'),
      );
    }
    if (limit != null && limit <= 0) {
      return const Err(AppFailure.validation('Limit must be positive'));
    }

    return Ok(
      TransactionQuery._(
        categories: categories,
        start: utcStart,
        end: utcEnd,
        limit: limit,
      ),
    );
  }

  /// Categories to include. Empty means every category.
  final Set<SpendCategory> categories;

  /// Inclusive lower bound, UTC. Null means unbounded.
  final DateTime? start;

  /// Exclusive upper bound, UTC. Null means unbounded.
  final DateTime? end;

  /// Maximum rows to return. Null means unbounded.
  final int? limit;

  /// Whether this query restricts anything at all.
  bool get isUnfiltered =>
      categories.isEmpty && start == null && end == null && limit == null;

  /// Whether [instant] falls inside this query's range.
  ///
  /// Mirrors the SQL the DAO issues, so the boundary rule is stated once in
  /// Dart and once in SQL and tested against both.
  bool containsInstant(DateTime instant) {
    final utc = instant.toUtc();
    if (start != null && utc.isBefore(start!)) return false;
    if (end != null && !utc.isBefore(end!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [categories, start, end, limit];
}
