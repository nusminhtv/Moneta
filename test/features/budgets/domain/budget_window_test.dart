import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';

void main() {
  BudgetWindow windowFor(
    DateTime anchor,
    BudgetPeriod period,
    DateTime now,
  ) => BudgetWindow.currentFor(anchor: anchor, period: period, now: now);

  group('monthly', () {
    test('runs start-day to start-day', () {
      final w = windowFor(
        DateTime.utc(2026, 9),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 9, 20),
      );
      expect(w.start, DateTime.utc(2026, 9));
      expect(w.end, DateTime.utc(2026, 10));
    });

    test('a 31st anchor lands on the last day February has', () {
      // DateTime.utc(2026, 2, 31) silently rolls to 3 March, which would count
      // three days of March spending against February.
      final w = windowFor(
        DateTime.utc(2026, 1, 31),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 2, 10),
      );
      expect(w.start, DateTime.utc(2026, 1, 31));
      expect(w.end, DateTime.utc(2026, 2, 28));
    });

    test('a short month does not permanently shift the anchor', () {
      // The window after February must return to the 31st. Stepping month by
      // month from each window's start would stay on the 28th forever.
      final w = windowFor(
        DateTime.utc(2026, 1, 31),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 4, 15),
      );
      expect(w.start, DateTime.utc(2026, 3, 31));
      expect(w.end, DateTime.utc(2026, 4, 30));
    });

    test('a 31st anchor gives April 30 days, not 31', () {
      final w = windowFor(
        DateTime.utc(2026, 1, 31),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 5, 1),
      );
      expect(w.start, DateTime.utc(2026, 4, 30));
      expect(w.end, DateTime.utc(2026, 5, 31));
    });

    test('a leap February keeps the 29th', () {
      final w = windowFor(
        DateTime.utc(2028, 1, 31),
        BudgetPeriod.monthly,
        DateTime.utc(2028, 2, 10),
      );
      expect(w.end, DateTime.utc(2028, 2, 29));
    });

    test('crossing a year boundary advances the year', () {
      final w = windowFor(
        DateTime.utc(2026, 12),
        BudgetPeriod.monthly,
        DateTime.utc(2027, 1, 5),
      );
      expect(w.start, DateTime.utc(2027));
      expect(w.end, DateTime.utc(2027, 2));
    });
  });

  group('weekly and yearly', () {
    test('weekly is seven days from the anchor', () {
      final w = windowFor(
        DateTime.utc(2026, 9, 7),
        BudgetPeriod.weekly,
        DateTime.utc(2026, 9, 20),
      );
      expect(
        w.start,
        DateTime.utc(2026, 9, 21).subtract(const Duration(days: 7)),
      );
      expect(w.end.difference(w.start).inDays, 7);
    });

    test('yearly is the same date one year on', () {
      final w = windowFor(
        DateTime.utc(2026, 3, 15),
        BudgetPeriod.yearly,
        DateTime.utc(2026, 11),
      );
      expect(w.start, DateTime.utc(2026, 3, 15));
      expect(w.end, DateTime.utc(2027, 3, 15));
    });

    test('a 29 Feb yearly anchor clamps in a non-leap year', () {
      final w = windowFor(
        DateTime.utc(2028, 2, 29),
        BudgetPeriod.yearly,
        DateTime.utc(2028, 6),
      );
      expect(w.end, DateTime.utc(2029, 2, 28));
    });
  });

  group('a start date in the future', () {
    test('reports the first window, not one in the past', () {
      final w = windowFor(
        DateTime.utc(2026, 10),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 9, 20),
      );
      expect(w.start, DateTime.utc(2026, 10));
      expect(w.end, DateTime.utc(2026, 11));
    });
  });

  group('contains is half-open', () {
    final w = BudgetWindow(
      start: DateTime.utc(2026, 9),
      end: DateTime.utc(2026, 10),
    );

    test('the start instant is inside', () {
      expect(w.contains(DateTime.utc(2026, 9)), isTrue);
    });

    test('the end instant belongs to the next window', () {
      expect(w.contains(DateTime.utc(2026, 10)), isFalse);
      expect(
        BudgetWindow(
          start: DateTime.utc(2026, 10),
          end: DateTime.utc(2026, 11),
        ).contains(DateTime.utc(2026, 10)),
        isTrue,
        reason: 'a boundary instant is counted once across the two windows',
      );
    });

    test('a microsecond before the end is inside', () {
      expect(
        w.contains(
          DateTime.utc(2026, 10).subtract(const Duration(microseconds: 1)),
        ),
        isTrue,
      );
    });
  });

  group('daysRemainingFrom', () {
    final w = BudgetWindow(
      start: DateTime.utc(2026, 9),
      end: DateTime.utc(2026, 10),
    );

    test('counts whole days to the end, today included', () {
      // 20 Sep to 1 Oct is 11 days, and today is one of them: the allowance
      // answers "what may I spend today", so today must be in the divisor.
      expect(w.daysRemainingFrom(DateTime.utc(2026, 9, 20)), 11);
    });

    test('is 1 on the last day, never 0', () {
      // The daily allowance divides by this.
      expect(w.daysRemainingFrom(DateTime.utc(2026, 9, 30, 12)), 1);
    });

    test('is 1 past the end rather than negative', () {
      expect(w.daysRemainingFrom(DateTime.utc(2026, 11)), 1);
    });
  });

  group('previous', () {
    test('ends exactly where this one starts', () {
      final w = windowFor(
        DateTime.utc(2026, 9),
        BudgetPeriod.monthly,
        DateTime.utc(2026, 9, 20),
      );
      final p = w.previous(
        BudgetPeriod.monthly,
        anchor: DateTime.utc(2026, 1),
      )!;
      expect(p.end, w.start);
      expect(p.start, DateTime.utc(2026, 8));
    });

    test('a clamped anchor gets the real preceding window, not start minus a '
        'month', () {
      // The defect this pins: `previous` used to step back from the window
      // start, so a 31 January anchor gave `28 Jan → 28 Feb` where the true
      // preceding window is `31 Jan → 28 Feb`. Stepping from the anchor
      // restores the 31st as soon as a month is long enough; stepping from the
      // start does not.
      final anchor = DateTime.utc(2026, 1, 31);
      final march = windowFor(
        anchor,
        BudgetPeriod.monthly,
        DateTime.utc(2026, 3, 10),
      );
      expect(march.start, DateTime.utc(2026, 2, 28));

      final p = march.previous(BudgetPeriod.monthly, anchor: anchor)!;
      expect(p.start, DateTime.utc(2026, 1, 31));
      expect(p.end, DateTime.utc(2026, 2, 28));

      // And it agrees with asking for February directly.
      final february = windowFor(
        anchor,
        BudgetPeriod.monthly,
        DateTime.utc(2026, 2, 10),
      );
      expect(p.start, february.start);
      expect(p.end, february.end);
    });

    test('the first window has no predecessor', () {
      // Returning a window equal to this one would let a budget carry its own
      // spend forward as if it were last period's underspend.
      final anchor = DateTime.utc(2026, 9);
      final first = windowFor(
        anchor,
        BudgetPeriod.monthly,
        DateTime.utc(2026, 9, 5),
      );
      expect(first.start, anchor);
      expect(first.previous(BudgetPeriod.monthly, anchor: anchor), isNull);
    });

    test('every window chains back to the anchor without gaps or overlap', () {
      // Walks a clamped anchor across the February boundary, which is where
      // stepping from the start drifted.
      final anchor = DateTime.utc(2026, 1, 31);
      var w = windowFor(
        anchor,
        BudgetPeriod.monthly,
        DateTime.utc(2026, 6, 15),
      );
      var hops = 0;
      while (true) {
        final p = w.previous(BudgetPeriod.monthly, anchor: anchor);
        if (p == null) break;
        expect(p.end, w.start, reason: 'gap or overlap before ${w.start}');
        w = p;
        hops++;
        expect(hops, lessThan(24), reason: 'previous() is not terminating');
      }
      expect(w.start, anchor, reason: 'the chain did not reach the anchor');
      expect(hops, greaterThan(3), reason: 'five months should take steps');
    });
  });
}
