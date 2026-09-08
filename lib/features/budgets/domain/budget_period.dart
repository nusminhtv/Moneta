import 'package:meta/meta.dart';

/// How often a budget resets, from the segmented control on `66:117`.
enum BudgetPeriod {
  /// Seven days from the anchor.
  weekly('Weekly'),

  /// The same day-of-month, one month on. The default on `04.04`.
  monthly('Monthly'),

  /// The same date, one year on.
  yearly('Yearly');

  const BudgetPeriod(this.label);

  /// The label the period switcher shows.
  final String label;
}

/// One period of a budget: half-open, `[start, end)`.
///
/// Half-open so a transaction at exactly the boundary is counted once across
/// two adjacent windows rather than twice or not at all.
@immutable
class BudgetWindow {
  /// Creates a window.
  const BudgetWindow({required this.start, required this.end});

  /// The window containing [now] for a budget anchored at [start].
  ///
  /// Walks forward from the anchor rather than computing an offset, because a
  /// monthly period is not a fixed number of days: a budget anchored on the
  /// 31st has windows of 28 to 31 days, and dividing elapsed days by 30 drifts.
  ///
  /// A budget whose anchor is still in the future gets its **first** window,
  /// not a window in the past — it has not started, so there is nothing spent
  /// against it yet and reporting a stale window would be a lie.
  factory BudgetWindow.currentFor({
    required DateTime anchor,
    required BudgetPeriod period,
    required DateTime now,
  }) {
    var index = 0;
    var start = anchor;
    var end = _stepFromAnchor(anchor, period, 1);

    if (now.isBefore(anchor)) return BudgetWindow(start: start, end: end);

    while (!now.isBefore(end)) {
      index++;
      start = end;
      end = _stepFromAnchor(anchor, period, index + 1);
      // Guards a period that fails to advance, which would spin forever. It
      // cannot happen with the three periods above; it could with a fourth
      // added carelessly.
      if (!end.isAfter(start)) break;
    }
    return BudgetWindow(start: start, end: end);
  }

  /// Inclusive start, UTC.
  final DateTime start;

  /// Exclusive end, UTC.
  final DateTime end;

  /// Whether [instant] falls inside this window.
  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  /// Whole days from [now] to [end], never less than one.
  ///
  /// One rather than zero on the last day: `04.05` divides by this to get the
  /// daily allowance, and "you may spend the remainder today" is the right
  /// answer on the final day, not a division by zero.
  int daysRemainingFrom(DateTime now) {
    if (!now.isBefore(end)) return 1;
    final days = end.difference(now).inDays;
    return days < 1 ? 1 : days;
  }

  /// The window immediately before this one, for a rollover carry.
  BudgetWindow previous(BudgetPeriod period) =>
      BudgetWindow(start: _step(start, period, -1), end: start);

  @override
  bool operator ==(Object other) =>
      other is BudgetWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'BudgetWindow($start → $end)';

  /// [anchor] advanced by [count] periods.
  ///
  /// Always measured from the anchor, never from the previous window's start.
  /// Stepping month by month from a 31st anchor would land on 28 Feb and then
  /// stay on the 28th forever; measuring from the anchor restores the 31st as
  /// soon as the month is long enough, which is what `04.04`'s "Starts"
  /// setting means.
  static DateTime _stepFromAnchor(
    DateTime anchor,
    BudgetPeriod period,
    int count,
  ) => switch (period) {
    BudgetPeriod.weekly => anchor.add(Duration(days: 7 * count)),
    BudgetPeriod.monthly => _clampedMonth(anchor, count),
    BudgetPeriod.yearly => _clampedMonth(anchor, 12 * count),
  };

  static DateTime _step(DateTime from, BudgetPeriod period, int count) =>
      switch (period) {
        BudgetPeriod.weekly => from.add(Duration(days: 7 * count)),
        BudgetPeriod.monthly => _clampedMonth(from, count),
        BudgetPeriod.yearly => _clampedMonth(from, 12 * count),
      };

  /// [from] advanced by [months], with the day clamped to the target month's
  /// length.
  ///
  /// `DateTime.utc(2026, 2, 31)` silently becomes 3 March. That would move a
  /// budget's boundary into the following month and count three days of March
  /// spending against February.
  static DateTime _clampedMonth(DateTime from, int months) {
    final totalMonths = from.month - 1 + months;
    final year = from.year + (totalMonths / 12).floor();
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(
      year,
      month,
      from.day < lastDay ? from.day : lastDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }
}
