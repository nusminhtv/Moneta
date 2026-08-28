import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpButton(
    WidgetTester tester, {
    MonetaIconButtonStyle style = MonetaIconButtonStyle.ghost,
    MonetaIconButtonSize size = MonetaIconButtonSize.md,
    MonetaIconButtonState state = MonetaIconButtonState.normal,
    MonetaIconName icon = MonetaIconName.search,
    String label = 'Search transactions',
    VoidCallback? onPressed,
  }) {
    return pumpMonetaWidget(
      tester,
      MonetaIconButton(
        icon: icon,
        semanticLabel: label,
        style: style,
        size: size,
        state: state,
        onPressed: onPressed,
      ),
      surfaceSize: const Size(200, 200),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MonetaIconButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  MonetaIcon glyphOf(WidgetTester tester) =>
      tester.widget<MonetaIcon>(find.byType(MonetaIcon));

  group('all 18 variants resolve', () {
    testWidgets('every style × size × state builds at its authored size', (
      tester,
    ) async {
      var built = 0;
      for (final style in MonetaIconButtonStyle.values) {
        for (final size in MonetaIconButtonSize.values) {
          for (final state in MonetaIconButtonState.values) {
            await pumpButton(tester, style: style, size: size, state: state);
            final name = '${style.name}/${size.name}/${state.name}';

            expect(tester.takeException(), isNull, reason: name);
            expect(
              tester.getSize(find.byType(MonetaIconButton)),
              Size.square(size.box),
              reason: '$name box',
            );

            // Read off the render tree, not off the table that produced it.
            // Asserting the rendered value against its own lookup leaves the
            // wiring unchecked — that is how a button shipped with its label
            // colour repointed to an unrelated token and 617 tests passed.
            expect(
              decorationOf(tester).color,
              MonetaIconButton.backgroundFor(style, state, colors),
              reason: '$name background',
            );
            expect(
              glyphOf(tester).color,
              MonetaIconButton.foregroundFor(style, state, colors),
              reason: '$name glyph colour',
            );
            expect(
              glyphOf(tester).size,
              size.iconSize,
              reason: '$name glyph size',
            );
            built++;
          }
        }
      }
      expect(
        built,
        18,
        reason: 'Figma 20:114 is 3 styles × 3 sizes × 2 states',
      );
    });
  });

  group('the tables are pinned to tokens', () {
    // The other half. The loop above catches a broken wiring and nothing else,
    // because it compares the rendered value to the table it came from. These
    // pin the table itself, exhaustively over style × state, written out rather
    // than derived — every value below was read from the node's bound variables
    // via `get_variable_defs`, not inferred from MonetaButton's mapping, which
    // would have been wrong: this component's disabled glyph is `text-disabled`
    // where the button's is `text-tertiary`.
    test('every style and state names its expected background', () {
      final expected = {
        (MonetaIconButtonStyle.filled, MonetaIconButtonState.normal):
            colors.brand,
        (MonetaIconButtonStyle.filled, MonetaIconButtonState.disabled):
            colors.surfaceRaised,
        (MonetaIconButtonStyle.tonal, MonetaIconButtonState.normal):
            colors.surfaceRaised,
        (MonetaIconButtonStyle.tonal, MonetaIconButtonState.disabled):
            colors.surfaceRaised,
        (MonetaIconButtonStyle.ghost, MonetaIconButtonState.normal): null,
        (MonetaIconButtonStyle.ghost, MonetaIconButtonState.disabled): null,
      };
      for (final style in MonetaIconButtonStyle.values) {
        for (final state in MonetaIconButtonState.values) {
          expect(
            expected.containsKey((style, state)),
            isTrue,
            reason: 'a combination was added without pinning its background',
          );
          expect(
            MonetaIconButton.backgroundFor(style, state, colors),
            expected[(style, state)],
            reason: '${style.name}/${state.name}',
          );
        }
      }
    });

    test('every style and state names its expected glyph colour', () {
      final expected = {
        (MonetaIconButtonStyle.filled, MonetaIconButtonState.normal):
            colors.textOnBrand,
        (MonetaIconButtonStyle.tonal, MonetaIconButtonState.normal):
            colors.textPrimary,
        (MonetaIconButtonStyle.ghost, MonetaIconButtonState.normal):
            colors.textSecondary,
        (MonetaIconButtonStyle.filled, MonetaIconButtonState.disabled):
            colors.textDisabled,
        (MonetaIconButtonStyle.tonal, MonetaIconButtonState.disabled):
            colors.textDisabled,
        (MonetaIconButtonStyle.ghost, MonetaIconButtonState.disabled):
            colors.textDisabled,
      };
      for (final style in MonetaIconButtonStyle.values) {
        for (final state in MonetaIconButtonState.values) {
          expect(
            expected.containsKey((style, state)),
            isTrue,
            reason: 'a combination was added without pinning its glyph colour',
          );
          expect(
            MonetaIconButton.foregroundFor(style, state, colors),
            expected[(style, state)],
            reason: '${style.name}/${state.name}',
          );
        }
      }
    });

    test('the three styles do not all resolve to the same glyph colour', () {
      final normal = MonetaIconButtonStyle.values
          .map(
            (s) => MonetaIconButton.foregroundFor(
              s,
              MonetaIconButtonState.normal,
              colors,
            ),
          )
          .toSet();
      expect(normal, hasLength(3));
    });
  });

  group('the size table is pinned to Figma', () {
    test('each size keeps its authored box and glyph size', () {
      const expected = {
        MonetaIconButtonSize.sm: (box: 36.0, icon: 16.0),
        MonetaIconButtonSize.md: (box: 44.0, icon: 20.0),
        MonetaIconButtonSize.lg: (box: 52.0, icon: 24.0),
      };
      expect(expected.keys, containsAll(MonetaIconButtonSize.values));
      for (final entry in expected.entries) {
        expect(entry.key.box, entry.value.box, reason: entry.key.name);
        expect(entry.key.iconSize, entry.value.icon, reason: entry.key.name);
      }
    });

    test('only sm falls below the 44px touch target', () {
      // Figma's note on 20:6 states this constraint; it is carried here so a
      // future size change cannot silently break it.
      expect(MonetaIconButtonSize.sm.box, lessThan(44));
      expect(MonetaIconButtonSize.md.box, greaterThanOrEqualTo(44));
      expect(MonetaIconButtonSize.lg.box, greaterThanOrEqualTo(44));
    });
  });

  group('interaction', () {
    testWidgets('fires when enabled', (tester) async {
      var taps = 0;
      await pumpButton(tester, onPressed: () => taps++);
      await tester.tap(find.byType(MonetaIconButton));
      expect(taps, 1);
    });

    testWidgets('a disabled button is inert', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        state: MonetaIconButtonState.disabled,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(MonetaIconButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpButton(tester);
      await tester.tap(find.byType(MonetaIconButton), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the label describes the action, not the glyph', (
      tester,
    ) async {
      await pumpButton(
        tester,
        icon: MonetaIconName.search,
        label: 'Search transactions',
        onPressed: () {},
      );

      final semantics = tester.getSemantics(find.byType(MonetaIconButton));
      expect(semantics.label, 'Search transactions');
      expect(
        semantics.label,
        isNot(contains(MonetaIconName.search.figmaName)),
        reason: 'the glyph name leaked into the accessible label',
      );
    });

    testWidgets('a disabled button reports itself disabled', (tester) async {
      await pumpButton(
        tester,
        state: MonetaIconButtonState.disabled,
        onPressed: () {},
      );
      final semantics = tester.getSemantics(find.byType(MonetaIconButton));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });
  });

  group('the glyph', () {
    testWidgets('is the one it was given', (tester) async {
      for (final icon in [
        MonetaIconName.search,
        MonetaIconName.chevronLeft,
        MonetaIconName.zap,
      ]) {
        await pumpButton(tester, icon: icon);
        expect(glyphOf(tester).icon, icon, reason: icon.name);
      }
    });
  });
}
