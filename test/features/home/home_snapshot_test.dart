import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';

/// Covers the value types themselves.
///
/// `features/home/domain` is in `tool/coverage_critical.txt` at 85%, and the
/// provider tests exercise these types only incidentally — equality and `props`
/// are never reached by building a snapshot and reading it back.
void main() {
  const vnd = Currency.vnd;
  final at = DateTime.utc(2026, 8, 20, 9, 24);

  RecentEntry entry({
    String id = 'a',
    String title = 'Highlands Coffee',
    int minor = 45000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? occurredAt,
  }) => RecentEntry(
    id: id,
    title: title,
    amount: Money(minor, vnd),
    direction: direction,
    category: category,
    occurredAt: occurredAt ?? at,
  );

  group('RecentEntry', () {
    test('two entries with the same content are equal', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
    });

    test('every field participates in equality', () {
      // One assertion per field, so a field dropped from `props` is caught. A
      // single "different id" check would leave the other five unguarded.
      expect(entry(), isNot(entry(id: 'b')));
      expect(entry(), isNot(entry(title: 'Grab')));
      expect(entry(), isNot(entry(minor: 1)));
      expect(
        entry(),
        isNot(entry(direction: TransactionDirection.income)),
      );
      expect(entry(), isNot(entry(category: SpendCategory.salary)));
      expect(
        entry(),
        isNot(entry(occurredAt: DateTime.utc(2026, 8, 21))),
      );
    });

    test('the amount is a positive magnitude; direction carries the sign', () {
      final expense = entry();
      final income = entry(direction: TransactionDirection.income);
      expect(expense.amount.isNegative, isFalse);
      expect(income.amount, expense.amount);
      expect(income.direction, isNot(expense.direction));
    });
  });

  group('HomeSnapshot', () {
    HomeSnapshot snapshot({
      int balance = 100,
      int income = 200,
      int expenses = 100,
      List<RecentEntry>? recent,
    }) => HomeSnapshot(
      totalBalance: Money(balance, vnd),
      income: Money(income, vnd),
      expenses: Money(expenses, vnd),
      recent: recent ?? [entry()],
    );

    test('every field participates in equality', () {
      expect(snapshot(), snapshot());
      expect(snapshot(), isNot(snapshot(balance: 999)));
      expect(snapshot(), isNot(snapshot(income: 999)));
      expect(snapshot(), isNot(snapshot(expenses: 999)));
      expect(snapshot(), isNot(snapshot(recent: [])));
    });

    test('empty is zero in the given currency and reports itself empty', () {
      final empty = HomeSnapshot.empty(vnd);
      expect(empty.totalBalance, const Money.zero(vnd));
      expect(empty.income, const Money.zero(vnd));
      expect(empty.expenses, const Money.zero(vnd));
      expect(empty.recent, isEmpty);
      expect(empty.isEmpty, isTrue);
    });

    test('empty respects the currency it is given', () {
      expect(
        HomeSnapshot.empty(Currency.usd).totalBalance.currency,
        Currency.usd,
      );
    });

    test('a snapshot with entries is not empty, even at a zero balance', () {
      // Emptiness is about the list, not the money: a wallet whose income and
      // expenses cancel out still has transactions to show.
      final zeroed = snapshot(balance: 0, income: 100, expenses: 100);
      expect(zeroed.totalBalance, const Money.zero(vnd));
      expect(zeroed.isEmpty, isFalse);
    });
  });
}
