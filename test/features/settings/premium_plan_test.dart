import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/settings/domain/premium_plan.dart';

void main() {
  const vnd = Currency.vnd;

  group('the saving is arithmetic, not a string', () {
    test('the authored prices give exactly 31', () {
      // `102:1185`: "59,000 ₫ × 12 = 708,000 ₫ against 490,000 ₫ yearly, which
      // is the 31% the badge claims."
      expect(
        yearlySavingPercent(
          monthly: const Money(59000, vnd),
          yearly: const Money(490000, vnd),
        ),
        31,
      );
    });

    test('and the rounding mode is what makes it 31 rather than 30', () {
      // The exact value is 30.79…, so `round` and `floor` disagree. Asserting
      // the mode here means a future edit to "simplify" it to truncation
      // fails rather than quietly contradicting the badge.
      const monthly = 59000;
      const yearly = 490000;
      const exact = (1 - yearly / (monthly * 12)) * 100;
      expect(exact, closeTo(30.79, 0.01));
      expect(exact.round(), 31);
      expect(exact.floor(), 30);
    });

    test('changing a price changes the claim', () {
      expect(
        yearlySavingPercent(
          monthly: const Money(59000, vnd),
          yearly: const Money(600000, vnd),
        ),
        15,
      );
      expect(
        yearlySavingPercent(
          monthly: const Money(100000, vnd),
          yearly: const Money(600000, vnd),
        ),
        50,
      );
    });

    test('the plans on the screen are the authored three', () {
      expect(premiumPlans, hasLength(3));
      expect(
        premiumPlans.map((p) => p.period),
        PremiumPeriod.values,
      );
      expect(
        premiumPlans.firstWhere((p) => p.period == PremiumPeriod.monthly).price,
        const Money(59000, vnd),
      );
      expect(
        premiumPlans.firstWhere((p) => p.period == PremiumPeriod.yearly).price,
        const Money(490000, vnd),
      );
    });
  });

  group('degenerate prices give no claim rather than a wrong one', () {
    test('a zero monthly price does not divide by zero', () {
      expect(
        yearlySavingPercent(
          monthly: const Money(0, vnd),
          yearly: const Money(490000, vnd),
        ),
        isNull,
      );
    });

    test('a negative monthly price gives nothing', () {
      expect(
        yearlySavingPercent(
          monthly: const Money(-59000, vnd),
          yearly: const Money(490000, vnd),
        ),
        isNull,
      );
    });

    test('a yearly price above twelve months is not a saving', () {
      expect(
        yearlySavingPercent(
          monthly: const Money(59000, vnd),
          yearly: const Money(800000, vnd),
        ),
        isNull,
        reason: 'a negative saving is not a saving',
      );
      // Exactly twelve months is no saving either.
      expect(
        yearlySavingPercent(
          monthly: const Money(59000, vnd),
          yearly: const Money(708000, vnd),
        ),
        isNull,
      );
    });

    test('mixed currencies are refused, not compared', () {
      expect(
        () => yearlySavingPercent(
          monthly: const Money(59000, vnd),
          yearly: const Money(20, Currency.usd),
        ),
        throwsArgumentError,
      );
    });
  });

  group('the comparison table', () {
    test('six rows, two of them in the free tier', () {
      expect(PremiumFeature.values, hasLength(6));
      expect(
        PremiumFeature.values.where((f) => f.inFree).map((f) => f.label),
        ['Unlimited accounts', 'Budgets and goals'],
      );
    });

    test('every row says something different', () {
      expect(
        PremiumFeature.values.map((f) => f.label).toSet(),
        hasLength(PremiumFeature.values.length),
      );
    });
  });
}
