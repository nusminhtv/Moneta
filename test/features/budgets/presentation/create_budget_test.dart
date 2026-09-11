import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/molecules/amount_input.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/presentation/create_budget_amount_screen.dart';
import 'package:moneta/features/budgets/presentation/create_budget_category_screen.dart';

import '../../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;

  group('step 1 — the category grid', () {
    Future<void> pumpStep1(
      WidgetTester tester, {
      SpendCategory? selected,
      Map<SpendCategory, CategoryUnavailable> unavailable = const {},
      ValueChanged<SpendCategory>? onSelect,
      VoidCallback? onContinue,
    }) => pumpMonetaWidget(
      tester,
      SizedBox(
        width: 393,
        height: 852,
        child: CreateBudgetCategoryScreen(
          selected: selected,
          unavailable: unavailable,
          onSelect: onSelect,
          onContinue: onContinue,
        ),
      ),
      surfaceSize: const Size(393, 852),
    );

    testWidgets('every category is listed, including the disabled ones', (
      tester,
    ) async {
      // 04.03: "Income categories are visibly disabled rather than hidden, so
      // the user is not left wondering where Salary went."
      await pumpStep1(
        tester,
        unavailable: const {SpendCategory.salary: CategoryUnavailable.income},
      );
      for (final category in SpendCategory.values) {
        expect(
          find.text(category.label),
          findsOneWidget,
          reason: '${category.label} is missing from the grid',
        );
      }
    });

    testWidgets('the reason is written down, not left to the dimming', (
      tester,
    ) async {
      // A low-vision user may never see 35% opacity. The sentence is the only
      // signal that survives.
      await pumpStep1(
        tester,
        unavailable: const {
          SpendCategory.salary: CategoryUnavailable.income,
          SpendCategory.food: CategoryUnavailable.alreadyBudgeted,
        },
      );
      expect(
        find.text(CategoryUnavailable.income.explanation),
        findsOneWidget,
      );
      expect(
        find.text(CategoryUnavailable.alreadyBudgeted.explanation),
        findsOneWidget,
      );
    });

    test('each reason is printed once, however many categories share it', () {
      final reasons = CreateBudgetCategoryScreen.reasonsFor(const {
        SpendCategory.food: CategoryUnavailable.alreadyBudgeted,
        SpendCategory.bills: CategoryUnavailable.alreadyBudgeted,
        SpendCategory.salary: CategoryUnavailable.income,
      });
      expect(reasons, hasLength(2));
      expect(reasons.toSet(), hasLength(2));
    });

    test('no reasons are printed when nothing is disabled', () {
      expect(CreateBudgetCategoryScreen.reasonsFor(const {}), isEmpty);
    });

    testWidgets('a disabled category cannot be selected', (tester) async {
      var selections = 0;
      await pumpStep1(
        tester,
        unavailable: const {SpendCategory.salary: CategoryUnavailable.income},
        onSelect: (_) => selections++,
      );
      await tester.tap(find.text(SpendCategory.salary.label));
      expect(selections, 0);

      await tester.tap(find.text(SpendCategory.food.label));
      expect(selections, 1);
    });

    testWidgets('continue is disabled until a category is chosen', (
      tester,
    ) async {
      await pumpStep1(tester);
      expect(
        tester
            .widget<MonetaButton>(
              find.widgetWithText(MonetaButton, 'Continue'),
            )
            .onPressed,
        isNull,
      );

      await pumpStep1(
        tester,
        selected: SpendCategory.food,
        onContinue: () {},
      );
      expect(
        tester
            .widget<MonetaButton>(
              find.widgetWithText(MonetaButton, 'Continue'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('selecting does not nudge the grid', (tester) async {
      // The selection ring is 2px on every cell — invisible until chosen —
      // rather than appearing only on the selected one, which would reflow the
      // row every time the user changes their mind.
      await pumpStep1(tester);
      final before = tester.getRect(find.text(SpendCategory.bills.label));

      await pumpStep1(tester, selected: SpendCategory.food);
      expect(tester.getRect(find.text(SpendCategory.bills.label)), before);
    });
  });

  group('step 2 — amount, period and options', () {
    Future<void> pumpStep2(
      WidgetTester tester, {
      Money amount = const Money(0, vnd),
      Money? average,
      String? errorText,
      bool rollsOver = false,
      double threshold = 0.8,
      ValueChanged<Money>? onAmountChanged,
      VoidCallback? onSubmit,
    }) => pumpMonetaWidget(
      tester,
      SizedBox(
        width: 393,
        height: 852,
        child: CreateBudgetAmountScreen(
          category: SpendCategory.food,
          amount: amount,
          period: BudgetPeriod.monthly,
          startsOn: DateTime.utc(2026, 9),
          rollsOver: rollsOver,
          alertThreshold: threshold,
          threeMonthAverage: average,
          errorText: errorText,
          onAmountChanged: onAmountChanged,
          onSubmit: onSubmit,
        ),
      ),
      surfaceSize: const Size(393, 852),
    );

    testWidgets('the amount can actually be entered', (tester) async {
      // The bug this guards against has already happened once in this project:
      // a form that demanded a value and gave no way to supply it. Figma pairs
      // the hero amount with a Numpad the design system lacked when this screen
      // shipped, so it carries a hidden field instead. `Numpad` exists now, and
      // rewiring this screen to it is deferred — this test holds either way,
      // because it asserts that the amount can be entered, not how.
      final entered = <Money>[];
      await pumpStep2(tester, onAmountChanged: entered.add);

      await tester.enterText(
        find.byKey(CreateBudgetAmountScreen.amountInputKey),
        '620000',
      );
      expect(entered.last, const Money(620000, vnd));
    });

    testWidgets('non-digits are rejected as they are typed', (tester) async {
      final entered = <Money>[];
      await pumpStep2(tester, onAmountChanged: entered.add);

      await tester.enterText(
        find.byKey(CreateBudgetAmountScreen.amountInputKey),
        '-6.2e4',
      );
      expect(entered.last, const Money(624, vnd));
    });

    testWidgets('the hidden field is in the tree, so it can take focus', (
      tester,
    ) async {
      // Offstage would keep it out of the tree, it could never focus and the
      // keyboard would never appear — the mistake the OTP screen shipped first.
      await pumpStep2(tester);
      expect(
        find.byKey(CreateBudgetAmountScreen.amountInputKey),
        findsOneWidget,
      );
      // Asserting "no Offstage anywhere" was the first attempt and it failed:
      // Flutter puts one inside EditableText itself. The property that actually
      // matters is that tapping the figure focuses the field — an Offstage
      // wrapper of mine would break exactly that.
      await tester.tap(find.byType(AmountInput));
      await tester.pump();
      expect(
        tester
            .state<EditableTextState>(
              find.byKey(CreateBudgetAmountScreen.amountInputKey),
            )
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('submit is disabled until there is an amount', (tester) async {
      await pumpStep2(tester);
      expect(
        tester
            .widget<MonetaButton>(
              find.widgetWithText(MonetaButton, 'Create budget'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an error lands on the amount, not in a banner', (
      tester,
    ) async {
      await pumpStep2(
        tester,
        amount: const Money(620000, vnd),
        errorText: 'A monthly budget already covers Food & drink.',
      );
      expect(
        find.text('A monthly budget already covers Food & drink.'),
        findsOneWidget,
      );
      expect(
        tester.widget<AmountInput>(find.byType(AmountInput)).hasError,
        isTrue,
      );
    });

    testWidgets('the three options from 66:534 are all present', (
      tester,
    ) async {
      await pumpStep2(tester, rollsOver: true, threshold: 0.6);
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(rows.map((r) => r.title), [
        'Starts',
        'Rolls over unused',
        'Alert me at',
      ]);
      expect(rows[1].value, 'Yes');
      expect(rows[2].value, '60%');
    });

    test('the helper says the average, or says nothing made up', () {
      expect(
        CreateBudgetAmountScreen.helperFor(const Money(3200000, vnd)),
        contains(const Money(3200000, vnd).format()),
      );
      // 04.04 calls the average "the only number that makes a limit
      // meaningful". A fabricated one makes a wrong limit, so with no history
      // the line says something true instead.
      final none = CreateBudgetAmountScreen.helperFor(null);
      expect(none, isNot(contains('0')));
      expect(none, isNotEmpty);
    });

    test('the start label reads as a date', () {
      expect(
        CreateBudgetAmountScreen.startLabel(DateTime.utc(2026, 9)),
        '1 Sep 2026',
      );
    });
  });
}
