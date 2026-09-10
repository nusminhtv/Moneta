import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/insights/domain/insights_entry.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';

/// Spend in one category over the period.
@immutable
class CategorySpend extends Equatable {
  /// Creates a total.
  const CategorySpend({required this.category, required this.amount});

  /// The category.
  final SpendCategory category;

  /// What was spent in it.
  final Money amount;

  @override
  List<Object?> get props => [category, amount];
}

/// Income and expense for one calendar month.
@immutable
class MonthlyFlow extends Equatable {
  /// Creates a month.
  const MonthlyFlow({
    required this.month,
    required this.income,
    required this.expenses,
  });

  /// First instant of the month, in UTC.
  final DateTime month;

  /// Money in.
  final Money income;

  /// Money out.
  final Money expenses;

  /// Income less expenses. Negative when more went out than came in.
  Money get net => income - expenses;

  @override
  List<Object?> get props => [month, income, expenses];
}

/// Everything the Insights screens show for one period.
///
/// Computed by [InsightsSummary.of], which is **pure**: a function from entries
/// and a window to figures, with no I/O. The interesting content of this
/// feature is the arithmetic, and a screen is the most expensive place to test
/// arithmetic.
@immutable
class InsightsSummary extends Equatable {
  /// Creates a summary.
  const InsightsSummary({
    required this.period,
    required this.window,
    required this.byCategory,
    required this.monthly,
    required this.topExpenses,
    required this.totalIncome,
    required this.totalExpenses,
  });

  /// Aggregates [entries] for [period] at [now].
  ///
  /// Reports a currency mismatch rather than summing across currencies — the
  /// same refusal `Money` itself makes, surfaced here so a screen never shows a
  /// total that added two currencies together.
  factory InsightsSummary.of({
    required List<InsightsEntry> entries,
    required InsightsPeriod period,
    required DateTime now,
    required Currency currency,
  }) {
    final window = period.windowAt(now);
    final inWindow = [
      for (final entry in entries)
        if (window.contains(entry.occurredAt)) entry,
    ];

    for (final entry in inWindow) {
      if (entry.amount.currency != currency) {
        throw ArgumentError.value(
          entry.amount,
          'entries',
          'currency mismatch: the wallet is ${currency.code} and '
              '"${entry.title}" is ${entry.amount.currency.code}. Insights '
              'cannot sum two currencies, and converting would put an invented '
              'rate in a total the user trusts.',
        );
      }
    }

    var income = Money.zero(currency);
    var expenses = Money.zero(currency);
    final categoryTotals = <SpendCategory, int>{};

    for (final entry in inWindow) {
      if (entry.isExpense) {
        expenses += entry.amount;
        categoryTotals[entry.category] =
            (categoryTotals[entry.category] ?? 0) + entry.amount.minorUnits;
      } else {
        income += entry.amount;
      }
    }

    final ranked =
        categoryTotals.entries
            .map(
              (e) => CategorySpend(
                category: e.key,
                amount: Money(e.value, currency),
              ),
            )
            .toList()
          ..sort(
            (a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits),
          );

    // One entry per calendar month in the window, so a silent month is a zero
    // point rather than a gap. A gap would shift every later point one place
    // left and misalign the line with the calendar.
    final monthly = <MonthlyFlow>[];
    for (final month in window.months) {
      final next = DateTime.utc(month.year, month.month + 1);
      var monthIncome = Money.zero(currency);
      var monthExpenses = Money.zero(currency);
      for (final entry in inWindow) {
        if (entry.occurredAt.isBefore(month)) continue;
        if (!entry.occurredAt.isBefore(next)) continue;
        if (entry.isExpense) {
          monthExpenses += entry.amount;
        } else {
          monthIncome += entry.amount;
        }
      }
      monthly.add(
        MonthlyFlow(
          month: month,
          income: monthIncome,
          expenses: monthExpenses,
        ),
      );
    }

    final expensesOnly = [
      for (final e in inWindow)
        if (e.isExpense) e,
    ]..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));

    return InsightsSummary(
      period: period,
      window: window,
      byCategory: ranked,
      monthly: monthly,
      topExpenses: expensesOnly.take(topExpenseCount).toList(),
      totalIncome: income,
      totalExpenses: expenses,
    );
  }

  /// The period these figures describe.
  final InsightsPeriod period;

  /// The window it resolved to.
  final InsightsWindow window;

  /// Spend per category, largest first.
  final List<CategorySpend> byCategory;

  /// One entry per calendar month in the window, oldest first.
  final List<MonthlyFlow> monthly;

  /// The largest single expenses, largest first — `77:287`'s "top merchants".
  final List<InsightsEntry> topExpenses;

  /// Money in over the period.
  final Money totalIncome;

  /// Money out over the period.
  final Money totalExpenses;

  /// How many rows `77:2` lists below the donut.
  static const int topExpenseCount = 3;

  /// True when there is nothing to chart.
  ///
  /// **Spending**, specifically. Annotation `77:291` requires an `EmptyState`
  /// rather than a 0% donut, and a period holding income but no expense has
  /// nothing for a spend chart to describe.
  bool get hasNoSpending => byCategory.isEmpty;

  /// Income less expenses over the period.
  Money get net => totalIncome - totalExpenses;

  /// [category]'s share of total spend, `0.0`–`1.0`.
  double shareOf(CategorySpend category) =>
      category.amount.ratioOf(totalExpenses);

  /// [category]'s size relative to the **largest** category, `0.0`–`1.0`.
  ///
  /// This is what the bars on `07.03` are drawn from, and it is not the same
  /// number as [shareOf]. Annotation `77:587`: rank is carried by *length and
  /// order*, so the largest bar is full and every other is a visible
  /// proportion of it. A share-of-total fraction would leave the top bar a
  /// third full and waste two-thirds of the width.
  double barFractionOf(CategorySpend category) {
    if (byCategory.isEmpty) return 0;
    final largest = byCategory.first.amount;
    if (largest.minorUnits == 0) return 0;
    return category.amount.ratioOf(largest);
  }

  @override
  List<Object?> get props => [
    period,
    byCategory,
    monthly,
    topExpenses,
    totalIncome,
    totalExpenses,
  ];
}
