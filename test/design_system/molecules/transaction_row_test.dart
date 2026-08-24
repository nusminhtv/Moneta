import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/theme/category_colors.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final occurred = DateTime.utc(2026, 8, 24, 9, 5);

  Future<void> pumpRow(
    WidgetTester tester, {
    String title = 'Cà phê sữa đá',
    int amount = 45000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? at,
    double width = 353,
    VoidCallback? onTap,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: TransactionRow(
          title: title,
          amount: Money(amount, Currency.vnd),
          direction: direction,
          category: category,
          occurredAt: at ?? occurred,
          onTap: onTap,
        ),
      ),
      surfaceSize: Size(width + 40, 200),
    );
  }

  Text amountText(WidgetTester tester) =>
      tester.widget<Text>(find.textContaining('₫'));

  group('direction', () {
    testWidgets('an expense is negative and uses the expense colour', (
      tester,
    ) async {
      await pumpRow(tester, direction: TransactionDirection.expense);
      final text = amountText(tester);
      expect(text.data, startsWith('-'));
      expect(text.style!.color, colors.expense);
    });

    testWidgets('income is positive and uses the income colour', (
      tester,
    ) async {
      await pumpRow(
        tester,
        direction: TransactionDirection.income,
        category: SpendCategory.salary,
      );
      final text = amountText(tester);
      expect(text.data, startsWith('+'));
      expect(text.style!.color, colors.income);
    });

    testWidgets('the caller passes a magnitude; the row owns the sign', (
      tester,
    ) async {
      // Both directions are given the same positive amount.
      await pumpRow(tester, direction: TransactionDirection.expense);
      final expense = amountText(tester).data!;
      await pumpRow(
        tester,
        direction: TransactionDirection.income,
        category: SpendCategory.salary,
      );
      final income = amountText(tester).data!;

      expect(expense.substring(1), income.substring(1));
      expect(expense[0], '-');
      expect(income[0], '+');
    });

    testWidgets('uses the amount type style', (tester) async {
      await pumpRow(tester);
      expect(amountText(tester).style!.fontSize, 20);
    });
  });

  group('category', () {
    testWidgets('the disc comes from the shared binding', (tester) async {
      for (final category in [
        SpendCategory.food,
        SpendCategory.bills,
        SpendCategory.entertainment,
      ]) {
        await pumpRow(tester, category: category);
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(CategoryIcon),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect(
          (box.decoration as BoxDecoration).color,
          colors.categorySubtle(category),
          reason: category.name,
        );
      }
    });

    testWidgets('uses the small disc, as the ADR specifies', (tester) async {
      await pumpRow(tester);
      expect(
        tester.getSize(find.byType(CategoryIcon)),
        Size.square(CategoryIconSize.sm.diameter),
      );
    });
  });

  group('title', () {
    testWidgets('shows the supplied title', (tester) async {
      await pumpRow(tester, title: 'Cà phê sữa đá');
      expect(find.text('Cà phê sữa đá'), findsOneWidget);
    });

    testWidgets('shows the category name when that is what it is given', (
      tester,
    ) async {
      // The fallback is the caller's job — only the domain knows there is no
      // note — so the row simply renders what it is handed.
      await pumpRow(tester, title: SpendCategory.bills.label);
      expect(find.text(SpendCategory.bills.label), findsOneWidget);
    });

    testWidgets('truncates on one line without displacing the amount', (
      tester,
    ) async {
      await pumpRow(tester, title: 'a' * 300, width: 300);
      expect(tester.takeException(), isNull);

      final title = tester.widget<Text>(find.text('a' * 300));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);

      final row = tester.getRect(find.byType(TransactionRow));
      final amount = tester.getRect(find.textContaining('₫'));
      expect(amount.right, lessThanOrEqualTo(row.right));
      expect(amount.width, greaterThan(0));
    });

    testWidgets('a very large amount does not overflow the row', (
      tester,
    ) async {
      await pumpRow(tester, amount: 999999999999, width: 300);
      expect(tester.takeException(), isNull);
    });
  });

  group('time', () {
    testWidgets('shows the local time of day', (tester) async {
      await pumpRow(tester, at: occurred);
      expect(
        find.text(TransactionRow.formatTimeOfDay(occurred)),
        findsOneWidget,
      );
    });

    test('converts UTC to local exactly once', () {
      final instant = DateTime.utc(2026, 8, 24, 22, 30);
      expect(
        TransactionRow.formatTimeOfDay(instant),
        TransactionRow.formatTimeOfDay(instant.toLocal()),
      );
    });

    test('pads to two digits', () {
      final instant = DateTime(2026, 8, 24, 9, 5);
      expect(TransactionRow.formatTimeOfDay(instant), '09:05');
    });
  });

  group('interaction', () {
    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await pumpRow(tester, onTap: () => taps++);
      await tester.tap(find.byType(TransactionRow));
      expect(taps, 1);
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpRow(tester);
      await tester.tap(find.byType(TransactionRow));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
