import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';

void main() {
  Money usd(int cents) => Money(cents, Currency.usd);

  group('fromFraction', () {
    test('classifies the Figma thresholds', () {
      expect(BudgetStatus.fromFraction(0), BudgetStatus.onTrack);
      expect(BudgetStatus.fromFraction(0.62), BudgetStatus.onTrack);
      expect(BudgetStatus.fromFraction(0.799), BudgetStatus.onTrack);
      expect(BudgetStatus.fromFraction(0.8), BudgetStatus.nearLimit);
      expect(BudgetStatus.fromFraction(0.88), BudgetStatus.nearLimit);
      expect(BudgetStatus.fromFraction(1), BudgetStatus.nearLimit);
      expect(BudgetStatus.fromFraction(1.0001), BudgetStatus.over);
      expect(BudgetStatus.fromFraction(4), BudgetStatus.over);
    });

    test('exactly at the limit is near, not over', () {
      // The limit has been reached, not exceeded. Getting this wrong shows a
      // red card to someone who spent exactly their budget.
      expect(BudgetStatus.fromFraction(1), BudgetStatus.nearLimit);
    });

    test('the threshold constant is the documented 80%', () {
      expect(BudgetStatus.nearLimitThreshold, 0.8);
    });

    test('a negative fraction reads as on track', () {
      expect(BudgetStatus.fromFraction(-1), BudgetStatus.onTrack);
    });

    test('NaN does not classify as over budget', () {
      // 0/0 must not turn a card red.
      expect(BudgetStatus.fromFraction(double.nan), BudgetStatus.onTrack);
    });

    test('infinity reads as over', () {
      expect(BudgetStatus.fromFraction(double.infinity), BudgetStatus.over);
    });
  });

  group('fromSpend', () {
    test('classifies from money, matching the fraction thresholds', () {
      expect(
        BudgetStatus.fromSpend(usd(2450), usd(4000)),
        BudgetStatus.onTrack,
      );
      expect(
        BudgetStatus.fromSpend(usd(3200), usd(4000)),
        BudgetStatus.nearLimit,
      );
      expect(
        BudgetStatus.fromSpend(usd(4000), usd(4000)),
        BudgetStatus.nearLimit,
      );
      expect(BudgetStatus.fromSpend(usd(4001), usd(4000)), BudgetStatus.over);
    });

    test('zero spend is on track whatever the limit', () {
      expect(BudgetStatus.fromSpend(usd(0), usd(4000)), BudgetStatus.onTrack);
      expect(BudgetStatus.fromSpend(usd(0), usd(0)), BudgetStatus.onTrack);
    });

    test('any spend against a zero limit is over budget', () {
      // A clamped ratio would report 0 here and render as on-track, which is
      // the opposite of the truth.
      expect(BudgetStatus.fromSpend(usd(1), usd(0)), BudgetStatus.over);
      expect(BudgetStatus.fromSpend(usd(999999), usd(0)), BudgetStatus.over);
    });

    test('a refund larger than the spend is on track, not over', () {
      expect(
        BudgetStatus.fromSpend(usd(-500), usd(4000)),
        BudgetStatus.onTrack,
      );
      expect(BudgetStatus.fromSpend(usd(-500), usd(0)), BudgetStatus.onTrack);
    });

    test('very large amounts do not overflow into a wrong state', () {
      const big = 9007199254740991;
      expect(
        BudgetStatus.fromSpend(usd(big), usd(1)),
        BudgetStatus.over,
      );
      expect(
        BudgetStatus.fromSpend(usd(1), usd(big)),
        BudgetStatus.onTrack,
      );
    });

    test('mixing currencies is an error, not a wrong answer', () {
      expect(
        () => BudgetStatus.fromSpend(usd(100), const Money(100, Currency.vnd)),
        throwsArgumentError,
      );
    });
  });

  group('fractionOf', () {
    test('is the raw unclamped ratio', () {
      expect(BudgetStatus.fractionOf(usd(2450), usd(4000)), 0.6125);
      expect(BudgetStatus.fractionOf(usd(8000), usd(4000)), 2.0);
    });

    test('returns 0 for a zero limit rather than dividing by zero', () {
      expect(BudgetStatus.fractionOf(usd(500), usd(0)), 0);
    });
  });
}
