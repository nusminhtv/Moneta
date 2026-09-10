import 'package:moneta/core/clock.dart';

/// The periods `77:32`'s switcher offers.
///
/// Annotation `77:291`: *"month · 3M / 6M / Year change the period, not the
/// layout"*. So this is a choice of *window*, and no screen may reshape itself
/// around it.
enum InsightsPeriod {
  /// The calendar month in progress.
  thisMonth('Month', months: 1, longLabel: 'This month'),

  /// This month and the two before it.
  threeMonths('3M', months: 3, longLabel: 'Last 3 months'),

  /// This month and the five before it.
  sixMonths('6M', months: 6, longLabel: 'Last 6 months'),

  /// This month and the eleven before it.
  year('Year', months: 12, longLabel: 'This year');

  const InsightsPeriod(
    this.label, {
    required this.months,
    required this.longLabel,
  });

  /// The switcher's label, from `77:32`.
  final String label;

  /// The picker's label, from `81:551` — the sheet has room for words.
  final String longLabel;

  /// Whole months included, the one in progress counted.
  final int months;

  /// The window this period covers at [now].
  ///
  /// Ends at `now` and starts at the first instant of the earliest included
  /// month, in UTC.
  ///
  /// **Whole months, not a rolling 30/90/180 days.** The cash-flow chart plots
  /// one point per month; a rolling window would leave a partial month at each
  /// end, making the first and last points structurally smaller than the rest
  /// — which reads as a trend that is not there.
  InsightsWindow windowAt(DateTime now) {
    final utc = now.toUtc();
    return InsightsWindow(
      start: DateTime.utc(utc.year, utc.month - (months - 1)),
      end: utc,
    );
  }

  /// The window this period covers according to [clock].
  InsightsWindow windowFrom(Clock clock) => windowAt(clock.nowUtc());
}

/// A half-open window: `start` inclusive, `end` inclusive of the instant now.
class InsightsWindow {
  /// Creates a window.
  const InsightsWindow({required this.start, required this.end});

  /// First instant included.
  final DateTime start;

  /// Last instant included — the clock's now.
  final DateTime end;

  /// Whether [instant] falls inside.
  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(start) && !utc.isAfter(end);
  }

  /// The first instant of each month in the window, oldest first.
  ///
  /// One entry per calendar month, so a month with no transactions still gets a
  /// point and the x positions stay aligned with the calendar.
  List<DateTime> get months {
    final result = <DateTime>[];
    var cursor = DateTime.utc(start.year, start.month);
    final last = DateTime.utc(end.year, end.month);
    while (!cursor.isAfter(last)) {
      result.add(cursor);
      cursor = DateTime.utc(cursor.year, cursor.month + 1);
    }
    return result;
  }

  @override
  String toString() => 'InsightsWindow($start .. $end)';
}
