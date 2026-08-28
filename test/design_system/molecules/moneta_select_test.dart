import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpSelect(
    WidgetTester tester, {
    String? value,
    bool enabled = true,
    VoidCallback? onTap,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 353,
      child: MonetaSelect<String>(
        value: value,
        labelOf: (v) => 'Account: $v',
        placeholder: 'Select an account',
        enabled: enabled,
        onTap: onTap,
      ),
    ),
    surfaceSize: const Size(393, 200),
  );

  group('placeholder and value are visually distinct', () {
    testWidgets('the placeholder uses the tertiary text token', (
      tester,
    ) async {
      await pumpSelect(tester);
      expect(
        tester.widget<Text>(find.text('Select an account')).style!.color,
        colors.textTertiary,
      );
    });

    testWidgets('a chosen value uses the primary text token', (tester) async {
      await pumpSelect(tester, value: 'Vietcombank');
      expect(
        tester.widget<Text>(find.text('Account: Vietcombank')).style!.color,
        colors.textPrimary,
      );
      expect(colors.textPrimary, isNot(colors.textTertiary));
    });
  });

  group('it takes a domain value', () {
    testWidgets('the label comes from the function, not a formatted string', (
      tester,
    ) async {
      await pumpSelect(tester, value: 'Vietcombank');
      // The caller passed the raw value; the display text is produced by
      // labelOf, so two screens cannot format the same value differently.
      expect(find.text('Account: Vietcombank'), findsOneWidget);
      expect(find.text('Vietcombank'), findsNothing);
    });
  });

  group('activation is delegated', () {
    testWidgets('tapping fires the callback and presents nothing', (
      tester,
    ) async {
      var taps = 0;
      await pumpSelect(tester, onTap: () => taps++);
      await tester.tap(find.byType(MonetaSelect<String>));
      await tester.pump();
      expect(taps, 1);
      // The control presented nothing of its own — after the tap the only text
      // on screen is still its closed label, so no inline option list appeared.
      // (`Overlay` and `ModalBarrier` would both be wrong here: MaterialApp
      // always has one of each, so neither assertion could ever fail.)
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Select an account'), findsOneWidget);
    });

    testWidgets('a disabled select is inert', (tester) async {
      var taps = 0;
      await pumpSelect(tester, enabled: false, onTap: () => taps++);
      await tester.tap(
        find.byType(MonetaSelect<String>),
        warnIfMissed: false,
      );
      expect(taps, 0);
    });
  });

  group('geometry', () {
    testWidgets('it is the same height as a text field', (tester) async {
      await pumpSelect(tester);
      expect(
        tester.getSize(find.byType(MonetaSelect<String>)).height,
        MonetaTextField.fieldHeight,
      );
    });

    testWidgets('a long value truncates rather than overflowing', (
      tester,
    ) async {
      await pumpSelect(
        tester,
        value: 'Averyverylongaccountnamethatcannotpossiblyfitonasinglerow',
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MonetaSelect<String>)).height,
        MonetaTextField.fieldHeight,
      );
    });
  });
}
