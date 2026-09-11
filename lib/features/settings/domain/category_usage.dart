import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';

/// One transaction, as the category-usage count needs it.
///
/// **Its own type, not `Transaction`.** `tool/check_architecture.dart` forbids
/// `features/settings` from importing `features/transactions`, and the rule is
/// right here rather than inconvenient: this aggregation reads three fields, so
/// taking three makes that true in the type instead of in a comment.
/// `lib/app/category_usage_providers.dart` maps repository rows into this.
///
/// Same shape and same reason as `InsightsEntry` and `SpendEntry`.
@immutable
class UsageEntry extends Equatable {
  /// Creates an entry.
  const UsageEntry({
    required this.category,
    required this.direction,
    required this.amount,
    required this.occurredAt,
  });

  /// What the money was for.
  final SpendCategory category;

  /// In or out. **This** is what `08.08`'s filter reads.
  final TransactionDirection direction;

  /// A positive magnitude; the sign lives in [direction].
  final Money amount;

  /// When it happened, in UTC.
  final DateTime occurredAt;

  @override
  List<Object?> get props => [category, direction, amount, occurredAt];
}

/// How much one category was used.
@immutable
class CategoryUsage extends Equatable {
  /// Creates a usage row.
  const CategoryUsage({
    required this.category,
    required this.count,
    required this.total,
  });

  /// Which category.
  final SpendCategory category;

  /// How many transactions it carried in the period.
  final int count;

  /// What they came to.
  final Money total;

  @override
  List<Object?> get props => [category, count, total];
}

/// The whole calendar month containing [clock]'s now, in **local** time.
///
/// Local, not UTC, and that distinction is the whole point: a transaction at
/// `2026-08-31T18:00Z` happened on **1 September** in `Asia/Ho_Chi_Minh`, and
/// a boundary computed in UTC would drop it from September's totals. The gate
/// pins `TZ=Asia/Ho_Chi_Minh` precisely so a test can tell the two apart —
/// under UTC the correct and the incorrect implementation agree.
///
/// Returned in UTC, because that is what entries carry.
({DateTime startUtc, DateTime endUtc}) monthWindow(Clock clock) {
  final local = clock.nowUtc().toLocal();
  final start = DateTime(local.year, local.month);
  final end = DateTime(local.year, local.month + 1);
  return (startUtc: start.toUtc(), endUtc: end.toUtc());
}

/// Every category with its usage in the window, largest total first.
///
/// **A category with no transactions is listed at zero, not dropped.** Its
/// absence is the information `08.08` exists to show: "you have never used
/// this" is an answer, and a missing row is not.
///
/// Ties keep [SpendCategory]'s own order, so the list is stable rather than
/// reshuffling between builds.
///
/// Throws `ArgumentError` when one category holds more than one currency,
/// which is what `Money`'s own addition does and what `DonutChart` relies on.
List<CategoryUsage> categoryUsage({
  required Iterable<UsageEntry> entries,
  required TransactionDirection direction,
  required DateTime startUtc,
  required DateTime endUtc,
  required Currency currency,
}) {
  final counts = <SpendCategory, int>{};
  final totals = <SpendCategory, Money>{};

  for (final entry in entries) {
    if (entry.direction != direction) continue;
    final at = entry.occurredAt.toUtc();
    // Half-open: the first instant of the next month belongs to that month.
    if (at.isBefore(startUtc) || !at.isBefore(endUtc)) continue;

    counts[entry.category] = (counts[entry.category] ?? 0) + 1;
    final running = totals[entry.category];
    // `Money.+` throws on a currency mismatch, which is the reporting this
    // needs — a category holding two currencies has no single total.
    totals[entry.category] = running == null
        ? entry.amount
        : running + entry.amount;
  }

  final rows = [
    for (final category in SpendCategory.values)
      CategoryUsage(
        category: category,
        count: counts[category] ?? 0,
        total: totals[category] ?? Money(0, currency),
      ),
  ];

  // Largest first, ties in enum order. `SpendCategory.values.indexOf` is the
  // tiebreak rather than the name, so the order is the one the app already
  // uses everywhere else.
  return rows..sort((a, b) {
    final byTotal = b.total.minorUnits.compareTo(a.total.minorUnits);
    if (byTotal != 0) return byTotal;
    return SpendCategory.values
        .indexOf(a.category)
        .compareTo(SpendCategory.values.indexOf(b.category));
  });
}
