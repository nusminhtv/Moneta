import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/moneta_otp_field.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpOtp(WidgetTester tester, String code, {int length = 6}) =>
      pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: MonetaOtpField(code: code, length: length),
        ),
        surfaceSize: const Size(393, 200),
      );

  List<BoxDecoration> boxes(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MonetaOtpField),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((b) => b.decoration as BoxDecoration)
      .toList();

  group('fill state is derived from the code', () {
    test('empty, partial and complete follow the code length', () {
      expect(MonetaOtpField.stateOf('', 6), MonetaOtpFillState.empty);
      expect(MonetaOtpField.stateOf('4', 6), MonetaOtpFillState.partial);
      expect(MonetaOtpField.stateOf('48291', 6), MonetaOtpFillState.partial);
      expect(MonetaOtpField.stateOf('482915', 6), MonetaOtpFillState.complete);
    });

    testWidgets('a caller cannot render complete while holding a short code', (
      tester,
    ) async {
      await pumpOtp(tester, '482');
      final field = tester.widget<MonetaOtpField>(find.byType(MonetaOtpField));
      expect(field.state, MonetaOtpFillState.partial);
    });

    test('a code longer than the field is a programming error', () {
      // Rendering a truncated code as "complete" would tell the user their
      // entry was accepted when six of eight digits were dropped.
      expect(
        () => MonetaOtpField(code: '12345678', length: 6),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the boxes', () {
    testWidgets('there is one per position', (tester) async {
      await pumpOtp(tester, '48');
      expect(boxes(tester), hasLength(6));
    });

    testWidgets('a filled position shows its digit, an empty one shows none', (
      tester,
    ) async {
      await pumpOtp(tester, '482');
      // Distinguishable by content, not by colour.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text(''), findsNWidgets(3));
    });

    testWidgets('each box is 56 tall, clearing the touch target', (
      tester,
    ) async {
      await pumpOtp(tester, '');
      expect(MonetaOtpField.boxHeight, 56);
      expect(
        tester.getSize(find.byType(MonetaOtpField)).height,
        MonetaOtpField.boxHeight,
      );
    });

    testWidgets('digits use the tabular amount style, not body text', (
      tester,
    ) async {
      // Figma: "a code that shifts width as you type feels broken."
      await pumpOtp(tester, '4');
      final style = tester.widget<Text>(find.text('4')).style!;
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  group('the focus ring marks the next empty box', () {
    testWidgets('empty puts it on the first box', (tester) async {
      await pumpOtp(tester, '');
      final all = boxes(tester);
      expect((all.first.border! as Border).top.color, colors.borderFocus);
      expect(
        (all.first.border! as Border).top.width,
        MonetaLayout.borderWidthFocus,
      );
      expect((all[1].border! as Border).top.color, colors.borderDefault);
    });

    testWidgets('partial puts it on the first unfilled box', (tester) async {
      await pumpOtp(tester, '482');
      final all = boxes(tester);
      expect((all[3].border! as Border).top.color, colors.borderFocus);
      expect((all[2].border! as Border).top.color, colors.borderDefault);
    });

    testWidgets('complete has no focus ring', (tester) async {
      await pumpOtp(tester, '482915');
      final field = tester.widget<MonetaOtpField>(find.byType(MonetaOtpField));
      expect(field.focusedIndex, isNull);
      for (final box in boxes(tester)) {
        expect((box.border! as Border).top.color, colors.borderDefault);
      }
    });
  });

  group('length', () {
    testWidgets('a four-box field renders four boxes', (tester) async {
      await pumpOtp(tester, '12', length: 4);
      expect(boxes(tester), hasLength(4));
      final field = tester.widget<MonetaOtpField>(find.byType(MonetaOtpField));
      expect(field.state, MonetaOtpFillState.partial);
    });
  });
}
