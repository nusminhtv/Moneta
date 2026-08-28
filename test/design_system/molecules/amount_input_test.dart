import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/amount_input.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;

  Future<void> pumpInput(WidgetTester tester, Widget input) => pumpMonetaWidget(
    tester,
    SizedBox(width: 353, child: input),
    surfaceSize: const Size(393, 300),
  );

  group('error is not colour alone', () {
    testWidgets('the error state always shows a message', (tester) async {
      await pumpInput(
        tester,
        const AmountInput.error(
          amount: Money(620000, vnd),
          message: 'That is more than the budget allows',
        ),
      );
      expect(find.text('That is more than the budget allows'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('That is more than the budget allows'))
            .style!
            .color,
        colors.expense,
      );
      expect(
        tester
            .widget<Text>(find.text(const Money(620000, vnd).digits()))
            .style!
            .color,
        colors.expense,
      );
    });

    testWidgets('the resting state can have no line at all', (tester) async {
      await pumpInput(tester, const AmountInput(amount: Money(620000, vnd)));
      expect(find.byType(Text), findsNWidgets(2));
    });

    test('an error with no message cannot be constructed', () {
      // Figma's own description of 36:76 says the error variant "differs by
      // colour only". The type is what stops that being reproduced: there is
      // no error constructor that omits the message, so this is a compile-time
      // guarantee rather than a test someone can delete.
      const withMessage = AmountInput.error(
        amount: Money(620000, vnd),
        message: 'Too much',
      );
      expect(withMessage.hasError, isTrue);
      expect(withMessage.errorText, isNotNull);

      const resting = AmountInput(amount: Money(620000, vnd));
      expect(resting.hasError, isFalse);
      expect(resting.errorText, isNull);
    });
  });

  group('the figure', () {
    testWidgets('shows digits and the currency glyph separately', (
      tester,
    ) async {
      await pumpInput(tester, const AmountInput(amount: Money(620000, vnd)));
      expect(find.text(const Money(620000, vnd).digits()), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);
    });

    testWidgets('a different currency changes the glyph', (tester) async {
      await pumpInput(
        tester,
        const AmountInput(amount: Money(62000, Currency.usd)),
      );
      expect(find.text(r'$'), findsOneWidget);
      expect(find.text('₫'), findsNothing);
    });

    testWidgets('the glyph uses heading/h2', (tester) async {
      await pumpInput(tester, const AmountInput(amount: Money(620000, vnd)));
      final glyph = tester.widget<Text>(find.text('₫')).style!;
      expect(glyph.fontSize, 22);
      expect(glyph.color, colors.textTertiary);
    });

    testWidgets('digits are tabular, so typing does not shift the width', (
      tester,
    ) async {
      // The test font gives every glyph the same advance, so measuring two
      // strings here would prove nothing about the real font. What can be
      // asserted is that the request for tabular figures reaches the style.
      await pumpInput(tester, const AmountInput(amount: Money(111111, vnd)));
      final style = tester
          .widget<Text>(find.text(const Money(111111, vnd).digits()))
          .style!;
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('the caret', () {
    testWidgets('contributes nothing to the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInput(tester, const AmountInput(amount: Money(620000, vnd)));
      expect(
        find.ancestor(
          of: find.byKey(AmountInput.caretKey),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('is drawn at its authored size', (tester) async {
      await pumpInput(tester, const AmountInput(amount: Money(620000, vnd)));
      final caret = tester.getSize(find.byKey(AmountInput.caretKey));
      expect(caret.width, AmountInput.caretWidth);
      expect(caret.height, AmountInput.caretHeight);
    });
  });

  group('long input', () {
    testWidgets('a pathological amount does not overflow', (tester) async {
      await pumpInput(
        tester,
        const AmountInput(
          amount: Money(999999999999999, vnd),
          helper: 'Tap a category below to continue',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
