import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/molecules/numpad.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final theme = MonetaTheme.dark();

  Future<void> pumpPad(
    WidgetTester tester, {
    NumpadTrailing trailing = NumpadTrailing.decimalPoint,
    ValueChanged<String>? onDigit,
    VoidCallback? onDecimal,
    VoidCallback? onBackspace,
    double width = 353,
    TextDirection direction = TextDirection.ltr,
  }) => pumpMonetaWidget(
    tester,
    Directionality(
      textDirection: direction,
      child: SizedBox(
        width: width,
        child: Numpad(
          trailing: trailing,
          onDigit: onDigit,
          onDecimal: onDecimal,
          onBackspace: onBackspace,
        ),
      ),
    ),
    surfaceSize: const Size(420, 900),
  );

  group('NumpadKey is two variants, not the four claimed', () {
    testWidgets('a digit key draws its label in headingH2', (tester) async {
      await pumpMonetaWidget(
        tester,
        const NumpadKey(type: NumpadKeyType.digit, label: '7'),
      );

      final text = tester.widget<Text>(find.text('7'));
      expect(text.style!.fontSize, theme.text.headingH2.fontSize);
      expect(text.style!.fontWeight, theme.text.headingH2.fontWeight);
      expect(text.style!.color, colors.textPrimary);
      expect(find.byType(MonetaIcon), findsNothing);
    });

    testWidgets('an action key draws a 22px glyph and no label', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const NumpadKey(
          type: NumpadKeyType.action,
          glyph: Numpad.actionGlyph,
        ),
      );

      final glyph = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      expect(glyph.size, NumpadKey.glyphSize);
      expect(glyph.size, 22);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('56 tall, well above the minimum', (tester) async {
      await pumpMonetaWidget(
        tester,
        const NumpadKey(type: NumpadKeyType.digit, label: '7'),
      );
      expect(tester.getSize(find.byType(NumpadKey)).height, 56);
      expect(NumpadKey.height, greaterThan(MonetaLayout.minTouchTarget));
    });

    testWidgets('a key with no callback is inert and silent', (tester) async {
      await pumpMonetaWidget(
        tester,
        const NumpadKey(type: NumpadKeyType.digit, label: '7'),
      );
      await tester.tap(find.byType(NumpadKey));
      expect(tester.takeException(), isNull);
    });

    test('the authored radius is recorded even though nothing paints it', () {
      // `36:77` carries `radius/md` on a key with no fill, and the set has no
      // pressed state to reveal it. Kept as what the file says; asserted so
      // the number is not quietly lost.
      expect(NumpadKey.radiusOf(theme), theme.radii.md);
    });

    test('two types, and no third', () {
      expect(NumpadKeyType.values, hasLength(2));
      expect(NumpadKeyType.values.map((t) => t.figmaName), [
        'Digit',
        'Action',
      ]);
    });
  });

  group('the pad is three by four and fills its width', () {
    testWidgets('digits 1-9 in reading order, then the last row', (
      tester,
    ) async {
      await pumpPad(tester);

      // Row by row, by position rather than by tree order.
      final centres = <String, Offset>{};
      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
        centres[digit] = tester.getCenter(find.byKey(Numpad.keyFor(digit)));
      }
      for (final row in Numpad.digitRows) {
        expect(
          centres[row[0]]!.dy,
          centres[row[1]]!.dy,
          reason: '${row[0]} and ${row[1]} must share a row',
        );
        expect(centres[row[0]]!.dx, lessThan(centres[row[1]]!.dx));
        expect(centres[row[1]]!.dx, lessThan(centres[row[2]]!.dx));
      }
      expect(centres['1']!.dy, lessThan(centres['4']!.dy));
      expect(centres['4']!.dy, lessThan(centres['7']!.dy));
      expect(centres['7']!.dy, lessThan(centres['0']!.dy));

      // The last row: the trailing cell, then zero, then the action.
      expect(
        tester.getCenter(find.byKey(Numpad.decimalKey)).dx,
        lessThan(centres['0']!.dx),
      );
      expect(
        centres['0']!.dx,
        lessThan(tester.getCenter(find.byKey(Numpad.actionKey)).dx),
      );
    });

    for (final width in <double>[353, 393, 200]) {
      testWidgets('rows fill $width and the keys stay equal', (tester) async {
        await pumpPad(tester, width: width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at $width wide',
        );

        final widths = <double>[];
        for (final digit in ['1', '2', '3']) {
          widths.add(tester.getSize(find.byKey(Numpad.keyFor(digit))).width);
        }
        expect(
          widths.map((w) => w.toStringAsFixed(2)).toSet(),
          hasLength(1),
          reason: 'the three keys of a row differ: $widths',
        );
        // Three keys and two gaps span the whole width, so nothing is a fixed
        // 109 — which is what would overflow at 200.
        expect(
          widths.reduce((a, b) => a + b) + Numpad.gap * 2,
          closeTo(width, 0.01),
        );
      });
    }

    testWidgets('the pad fills the canvas colour', (tester) async {
      await pumpPad(tester);
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(Numpad),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color,
        colors.canvas,
      );
    });

    testWidgets('1 stays left of 3 under right-to-left text', (tester) async {
      // Positions, not tree order: a Row reverses what it paints under RTL
      // without reordering its children, so an order assertion over the tree
      // would pass for either. A keypad's digits are positional.
      await pumpPad(tester, direction: TextDirection.rtl);

      expect(
        tester.getCenter(find.byKey(Numpad.keyFor('1'))).dx,
        lessThan(tester.getCenter(find.byKey(Numpad.keyFor('3'))).dx),
      );
      expect(
        tester.getCenter(find.byKey(Numpad.keyFor('7'))).dx,
        lessThan(tester.getCenter(find.byKey(Numpad.keyFor('9'))).dx),
      );
    });
  });

  group('what the keys report', () {
    testWidgets('every digit reports itself', (tester) async {
      final pressed = <String>[];
      await pumpPad(tester, onDigit: pressed.add);

      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
        await tester.tap(find.byKey(Numpad.keyFor(digit)));
      }
      expect(pressed, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
    });

    testWidgets('the action key reports a delete, wearing a chevron', (
      tester,
    ) async {
      var deletes = 0;
      await pumpPad(tester, onBackspace: () => deletes++);

      await tester.tap(find.byKey(Numpad.actionKey));
      expect(deletes, 1);

      final glyph = tester.widget<NumpadKey>(find.byKey(Numpad.actionKey));
      expect(glyph.glyph, Numpad.actionGlyph);
      // The 50-icon set has no backspace glyph, which is why this is a
      // chevron. Asserted so the substitution is deliberate, not drift.
      expect(glyph.glyph!.figmaName, 'chevron-left');
    });

    testWidgets('a pad with no callbacks does not throw', (tester) async {
      await pumpPad(tester);
      for (final digit in ['1', '5', '9', '0']) {
        await tester.tap(find.byKey(Numpad.keyFor(digit)));
      }
      await tester.tap(find.byKey(Numpad.decimalKey));
      await tester.tap(find.byKey(Numpad.actionKey));
      expect(tester.takeException(), isNull);
    });
  });

  group("the third-last cell is the caller's", () {
    testWidgets('for amount entry it is the authored decimal key', (
      tester,
    ) async {
      var decimals = 0;
      await pumpPad(tester, onDecimal: () => decimals++);

      expect(find.byKey(Numpad.decimalKey), findsOneWidget);
      expect(find.byKey(Numpad.emptyCellKey), findsNothing);
      expect(find.byType(NumpadKey), findsNWidgets(12));

      await tester.tap(find.byKey(Numpad.decimalKey));
      expect(decimals, 1);
    });

    testWidgets('for a PIN it is empty, and one key fewer', (tester) async {
      var decimals = 0;
      await pumpPad(
        tester,
        trailing: NumpadTrailing.empty,
        onDecimal: () => decimals++,
      );

      expect(find.byKey(Numpad.decimalKey), findsNothing);
      expect(find.byKey(Numpad.emptyCellKey), findsOneWidget);
      // Eleven, not twelve: the cell is not a key.
      expect(find.byType(NumpadKey), findsNWidgets(11));

      // And nothing can report a decimal, because there is nothing to press.
      await tester.tap(find.byKey(Numpad.emptyCellKey), warnIfMissed: false);
      expect(decimals, 0);
    });

    testWidgets('the layout does not move when the cell is empty', (
      tester,
    ) async {
      await pumpPad(tester);
      final withKey = tester.getRect(find.byKey(Numpad.keyFor('0')));

      await pumpPad(tester, trailing: NumpadTrailing.empty);
      expect(tester.getRect(find.byKey(Numpad.keyFor('0'))), withKey);
    });
  });
}
