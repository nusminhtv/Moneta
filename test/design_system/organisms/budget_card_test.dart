import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const limit = Money(4000000, Currency.vnd);

  Future<void> pumpCard(
    WidgetTester tester, {
    required Money spent,
    Money budgetLimit = limit,
    SpendCategory category = SpendCategory.food,
    String note = '61% used · 9 days left',
    VoidCallback? onTap,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: 353,
        child: BudgetCard(
          category: category,
          spent: spent,
          limit: budgetLimit,
          note: note,
          onTap: onTap,
        ),
      ),
      surfaceSize: const Size(420, 400),
    );
  }

  Money vnd(int amount) => Money(amount, Currency.vnd);

  BoxDecoration cardDecoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(BudgetCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  Color spentColor(WidgetTester tester) {
    final text = tester.widget<Text>(find.textContaining('₫').first);
    return text.style!.color!;
  }

  Color noteColour(WidgetTester tester, String note) =>
      tester.widget<Text>(find.text(note)).style!.color!;

  Color barColour(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(MonetaProgressBar.fillKey),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  group('derived state — table over the thresholds', () {
    // percent of limit -> expected colour role
    final cases = <String, (Money, Color, bool)>{
      '0%': (vnd(0), colors.income, false),
      '25%': (vnd(1000000), colors.income, false),
      '79%': (vnd(3160000), colors.income, false),
      '80%': (vnd(3200000), colors.warning, false),
      '99%': (vnd(3960000), colors.warning, false),
      '100%': (vnd(4000000), colors.warning, false),
      '101%': (vnd(4040000), colors.expense, true),
      '400%': (vnd(16000000), colors.expense, true),
    };

    for (final entry in cases.entries) {
      testWidgets('at ${entry.key} the card is consistent everywhere', (
        tester,
      ) async {
        final (spent, expected, expectExpenseBorder) = entry.value;
        await pumpCard(tester, spent: spent);

        expect(spentColor(tester), expected, reason: 'amount at ${entry.key}');
        expect(
          noteColour(tester, '61% used · 9 days left'),
          expected,
          reason: 'note at ${entry.key}',
        );
        expect(barColour(tester), expected, reason: 'bar at ${entry.key}');
        expect(
          cardDecoration(tester).border,
          Border.all(
            color: expectExpenseBorder ? colors.expense : colors.borderSubtle,
          ),
          reason: 'border at ${entry.key}',
        );
      });
    }

    testWidgets('exactly at the limit is warning, not over', (tester) async {
      await pumpCard(tester, spent: limit);
      expect(spentColor(tester), colors.warning);
      expect(
        cardDecoration(tester).border,
        Border.all(color: colors.borderSubtle),
      );
    });

    testWidgets('a zero limit with spend is over budget', (tester) async {
      await pumpCard(
        tester,
        spent: vnd(500000),
        budgetLimit: const Money.zero(Currency.vnd),
      );
      expect(spentColor(tester), colors.expense);
      expect(
        cardDecoration(tester).border,
        Border.all(color: colors.expense),
      );
    });

    testWidgets('a zero limit with no spend is on track', (tester) async {
      await pumpCard(
        tester,
        spent: const Money.zero(Currency.vnd),
        budgetLimit: const Money.zero(Currency.vnd),
      );
      expect(spentColor(tester), colors.income);
    });

    testWidgets('the bar never paints outside the track', (tester) async {
      await pumpCard(tester, spent: vnd(16000000));
      final bar = tester.getRect(find.byType(MonetaProgressBar));
      final fill = tester.getRect(find.byKey(MonetaProgressBar.fillKey));
      expect(fill.width, closeTo(bar.width, 0.01));
      expect(fill.right, lessThanOrEqualTo(bar.right + 0.01));
    });

    testWidgets('exposes its status without re-deriving the rule', (
      tester,
    ) async {
      await pumpCard(tester, spent: vnd(3200000));
      final card = tester.widget<BudgetCard>(find.byType(BudgetCard));
      expect(card.status, BudgetStatus.nearLimit);
    });
  });

  group('content', () {
    testWidgets('shows the category name, spend and limit', (tester) async {
      await pumpCard(tester, spent: vnd(2450000));
      expect(find.text('Food & drink'), findsOneWidget);
      expect(find.text(vnd(2450000).format()), findsOneWidget);
      expect(find.text('of ${limit.format()}'), findsOneWidget);
    });

    testWidgets('renders the caller-supplied note verbatim', (tester) async {
      await pumpCard(tester, spent: vnd(100), note: '3% used · 21 days left');
      expect(find.text('3% used · 21 days left'), findsOneWidget);
    });

    testWidgets('uses the raised surface and the large radius', (tester) async {
      await pumpCard(tester, spent: vnd(100));
      final decoration = cardDecoration(tester);
      expect(decoration.color, colors.surfaceRaised);
      expect(decoration.borderRadius, BorderRadius.circular(18));
    });

    testWidgets('shows the category disc for the right category', (
      tester,
    ) async {
      await pumpCard(tester, spent: vnd(100), category: SpendCategory.shopping);
      expect(find.text('Shopping'), findsOneWidget);
    });
  });

  group('overflow', () {
    testWidgets('a long name truncates on one line', (tester) async {
      // Figma: "a status sentence clipped mid-word reads as a rendering bug".
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 220,
          child: BudgetCard(
            category: SpendCategory.entertainment,
            spent: vnd(2450000),
            limit: limit,
            note: 'a very long supporting note that cannot possibly fit here',
          ),
        ),
        surfaceSize: const Size(300, 400),
      );
      expect(tester.takeException(), isNull);

      final title = tester.widget<Text>(find.text('Entertainment'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('the amount is not displaced by a long note', (tester) async {
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 260,
          child: BudgetCard(
            category: SpendCategory.food,
            spent: vnd(2450000),
            limit: limit,
            note: 'a' * 200,
          ),
        ),
        surfaceSize: const Size(320, 400),
      );
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(BudgetCard));
      final amount = tester.getRect(find.text(vnd(2450000).format()));
      expect(amount.right, lessThanOrEqualTo(card.right));
      expect(amount.width, greaterThan(0));
    });

    testWidgets('a very large amount does not overflow the card', (
      tester,
    ) async {
      await pumpCard(tester, spent: vnd(999999999999));
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(BudgetCard));
      final amount = tester.getRect(find.textContaining('₫').first);
      expect(amount.right, lessThanOrEqualTo(card.right));
    });

    testWidgets('the amount column never exceeds its share of the row', (
      tester,
    ) async {
      // Deliberately not asserted in terms of text width: flutter test renders
      // with a metrics-only placeholder font where every glyph is exactly
      // fontSize wide, so any assertion about how wide a string "looks" is
      // measuring the test font, not the design. What is font-independent — and
      // what actually protects the layout — is that the amount column is capped
      // and the name column takes whatever is left, with nothing overflowing.
      for (final spent in [vnd(0), vnd(2450000), vnd(999999999999)]) {
        await pumpCard(tester, spent: spent);
        expect(tester.takeException(), isNull, reason: '$spent');

        final row = tester.getRect(find.byType(Row));
        final title = tester.getRect(find.text('Food & drink'));
        final amount = tester.getRect(find.textContaining('₫').first);

        expect(
          amount.width,
          lessThanOrEqualTo(row.width * 0.56),
          reason: 'amount column exceeded its cap at $spent',
        );
        expect(amount.right, lessThanOrEqualTo(row.right + 0.01));
        expect(
          title.width,
          greaterThan(0),
          reason: 'the name was squeezed to nothing at $spent',
        );
        expect(title.right, lessThanOrEqualTo(amount.left + 0.01));
      }
    });
  });

  group('interaction', () {
    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await pumpCard(tester, spent: vnd(100), onTap: () => taps++);
      await tester.tap(find.byType(BudgetCard));
      expect(taps, 1);
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpCard(tester, spent: vnd(100));
      await tester.tap(find.byType(BudgetCard));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the bar is labelled by category, and not doubled up', (
      tester,
    ) async {
      await pumpCard(tester, spent: vnd(2450000));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Food & drink budget'), findsOneWidget);
      // The name appears exactly once — from the visible title. The category
      // disc must not add a second node saying the same thing.
      expect(find.bySemanticsLabel('Food & drink'), findsOneWidget);
    });
  });
}
