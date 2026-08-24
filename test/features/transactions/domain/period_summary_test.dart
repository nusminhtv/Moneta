import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';

void main() {
  const vnd = Currency.vnd;

  test('net is income minus expenses', () {
    const summary = PeriodSummary(
      income: Money(32000000, vnd),
      expenses: Money(25840000, vnd),
    );
    expect(summary.net.minorUnits, 6160000);
  });

  test('net is negative when a period overspends', () {
    const summary = PeriodSummary(
      income: Money(1000, vnd),
      expenses: Money(2500, vnd),
    );
    expect(summary.net.minorUnits, -1500);
    expect(summary.net.isNegative, isTrue);
  });

  test('a zero summary is zero on every axis', () {
    final summary = PeriodSummary.zero(vnd);
    expect(summary.income.isZero, isTrue);
    expect(summary.expenses.isZero, isTrue);
    expect(summary.net.isZero, isTrue);
  });

  test('zero respects the currency it was asked for', () {
    expect(PeriodSummary.zero(Currency.usd).income.currency, Currency.usd);
  });

  test('summaries with the same totals are equal', () {
    expect(PeriodSummary.zero(vnd), PeriodSummary.zero(vnd));
    expect(
      const PeriodSummary(income: Money(1, vnd), expenses: Money(2, vnd)),
      const PeriodSummary(income: Money(1, vnd), expenses: Money(2, vnd)),
    );
    expect(
      const PeriodSummary(income: Money(1, vnd), expenses: Money(2, vnd)),
      isNot(
        const PeriodSummary(income: Money(1, vnd), expenses: Money(3, vnd)),
      ),
    );
  });

  test('toString shows both directions', () {
    final text = PeriodSummary.zero(vnd).toString();
    expect(text, contains('in'));
    expect(text, contains('out'));
  });

  test('mixing currencies in a summary is an error, not a wrong net', () {
    const summary = PeriodSummary(
      income: Money(100, Currency.vnd),
      expenses: Money(100, Currency.usd),
    );
    expect(() => summary.net, throwsArgumentError);
  });
}
