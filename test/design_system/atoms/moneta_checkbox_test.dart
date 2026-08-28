import 'dart:ui' show CheckedState;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_checkbox.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpBox(
    WidgetTester tester, {
    MonetaCheckboxState state = MonetaCheckboxState.unchecked,
    bool enabled = true,
    ValueChanged<MonetaCheckboxState>? onChanged,
  }) => pumpMonetaWidget(
    tester,
    MonetaCheckbox(
      state: state,
      semanticLabel: 'Remember me',
      enabled: enabled,
      onChanged: onChanged,
    ),
    surfaceSize: const Size(200, 200),
  );

  group('the three states differ by mark, not by tint', () {
    testWidgets('checked draws a check glyph', (tester) async {
      await pumpBox(tester, state: MonetaCheckboxState.checked);
      expect(find.byType(MonetaIcon), findsOneWidget);
      expect(
        tester.widget<MonetaIcon>(find.byType(MonetaIcon)).icon,
        MonetaIconName.check,
      );
    });

    testWidgets('indeterminate draws a bar, not the check glyph', (
      tester,
    ) async {
      await pumpBox(tester, state: MonetaCheckboxState.indeterminate);
      expect(
        find.byType(MonetaIcon),
        findsNothing,
        reason: 'indeterminate reused the checked glyph',
      );
      // The bar: a box of the authored width, distinct in shape from a check.
      final bar = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where(
            (b) => b.width == MonetaCheckbox.indeterminateBarWidth,
          );
      expect(bar, isNotEmpty);
    });

    testWidgets('unchecked draws neither', (tester) async {
      await pumpBox(tester);
      expect(find.byType(MonetaIcon), findsNothing);
      expect(
        tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .where(
              (b) => b.width == MonetaCheckbox.indeterminateBarWidth,
            ),
        isEmpty,
      );
    });
  });

  group('semantics', () {
    testWidgets('indeterminate reports itself mixed, not checked', (
      tester,
    ) async {
      await pumpBox(tester, state: MonetaCheckboxState.indeterminate);
      final semantics = tester.getSemantics(find.byType(MonetaCheckbox));
      expect(semantics.flagsCollection.isChecked, isNot(CheckedState.isTrue));
      expect(semantics.label, 'Remember me');
    });

    testWidgets('checked reports itself checked', (tester) async {
      await pumpBox(tester, state: MonetaCheckboxState.checked);
      expect(
        tester
            .getSemantics(find.byType(MonetaCheckbox))
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
    });
  });

  group('interaction', () {
    testWidgets('tapping unchecked asks for checked', (tester) async {
      MonetaCheckboxState? asked;
      await pumpBox(tester, onChanged: (s) => asked = s);
      await tester.tap(find.byType(MonetaCheckbox));
      expect(asked, MonetaCheckboxState.checked);
    });

    testWidgets('tapping indeterminate asks for checked', (tester) async {
      MonetaCheckboxState? asked;
      await pumpBox(
        tester,
        state: MonetaCheckboxState.indeterminate,
        onChanged: (s) => asked = s,
      );
      await tester.tap(find.byType(MonetaCheckbox));
      expect(asked, MonetaCheckboxState.checked);
    });

    testWidgets('a disabled checkbox does not change', (tester) async {
      MonetaCheckboxState? asked;
      await pumpBox(tester, enabled: false, onChanged: (s) => asked = s);
      await tester.tap(find.byType(MonetaCheckbox), warnIfMissed: false);
      expect(asked, isNull);
    });
  });

  group('touch target', () {
    testWidgets('the drawn box is 22 but the hit area meets 44', (
      tester,
    ) async {
      await pumpBox(tester, state: MonetaCheckboxState.checked);
      expect(MonetaCheckbox.boxSize, 22);
      expect(
        tester.getSize(find.byType(MonetaCheckbox)).width,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('disabled appearance', () {
    testWidgets('a disabled checked box does not use the brand fill', (
      tester,
    ) async {
      await pumpBox(
        tester,
        state: MonetaCheckboxState.checked,
        enabled: false,
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MonetaCheckbox),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).color, isNot(colors.brand));
    });
  });
}
