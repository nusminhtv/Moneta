import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpButton(
    WidgetTester tester, {
    MonetaButtonStyle style = MonetaButtonStyle.primary,
    MonetaButtonSize size = MonetaButtonSize.md,
    MonetaButtonState state = MonetaButtonState.normal,
    String label = 'Next',
    VoidCallback? onPressed,
    bool expand = false,
    MonetaIconName? leading,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: 353,
        child: MonetaButton(
          label: label,
          style: style,
          size: size,
          state: state,
          onPressed: onPressed,
          expand: expand,
          leadingIcon: leading,
        ),
      ),
      surfaceSize: const Size(420, 300),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MonetaButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  group('all 45 variants resolve', () {
    testWidgets('every style × size × state builds and has the right height', (
      tester,
    ) async {
      var built = 0;
      for (final style in MonetaButtonStyle.values) {
        for (final size in MonetaButtonSize.values) {
          for (final state in MonetaButtonState.values) {
            await pumpButton(tester, style: style, size: size, state: state);
            expect(
              tester.takeException(),
              isNull,
              reason: '${style.name}/${size.name}/${state.name}',
            );
            expect(
              tester.getSize(find.byType(MonetaButton)).height,
              size.height,
              reason: '${style.name}/${size.name}/${state.name} height',
            );
            built++;
          }
        }
      }
      expect(built, 45, reason: 'Figma 13:2 is 5 styles × 3 sizes × 3 states');
    });

    test('the sizes are the authored heights', () {
      expect(MonetaButtonSize.sm.height, 36);
      expect(MonetaButtonSize.md.height, 44);
      expect(MonetaButtonSize.lg.height, 56);
    });

    test('md meets the touch target on its own; sm does not', () {
      // Figma: "md (44px) meets the touch target on its own; Sm (36px) must sit
      // inside a >=44px row."
      expect(MonetaButtonSize.md.height, greaterThanOrEqualTo(44));
      expect(MonetaButtonSize.sm.height, lessThan(44));
    });
  });

  group('style resolution', () {
    testWidgets('primary fills with brand, on-brand label', (tester) async {
      await pumpButton(tester);
      expect(decorationOf(tester).color, colors.brand);
      expect(
        MonetaButton.foregroundFor(
          MonetaButtonStyle.primary,
          MonetaButtonState.normal,
          colors,
        ),
        colors.textOnBrand,
      );
    });

    testWidgets('secondary fills with the raised surface', (tester) async {
      await pumpButton(tester, style: MonetaButtonStyle.secondary);
      expect(decorationOf(tester).color, colors.surfaceRaised);
    });

    testWidgets('destructive fills with the expense colour', (tester) async {
      await pumpButton(tester, style: MonetaButtonStyle.destructive);
      expect(decorationOf(tester).color, colors.expense);
    });

    testWidgets('ghost has no fill at all — not a transparent one', (
      tester,
    ) async {
      await pumpButton(tester, style: MonetaButtonStyle.ghost);
      expect(decorationOf(tester).color, isNull);
      expect(decorationOf(tester).border, isNull);
    });

    testWidgets('tertiary has no fill but does have a border', (tester) async {
      await pumpButton(tester, style: MonetaButtonStyle.tertiary);
      expect(decorationOf(tester).color, isNull);
      expect(decorationOf(tester).border, isNotNull);
    });

    testWidgets('every style is a pill', (tester) async {
      for (final style in MonetaButtonStyle.values) {
        await pumpButton(tester, style: style);
        expect(
          decorationOf(tester).borderRadius,
          BorderRadius.circular(999),
          reason: style.name,
        );
      }
    });
  });

  group('disabled', () {
    testWidgets('collapses every filled style onto the raised surface', (
      tester,
    ) async {
      // A disabled brand button is not a dimmer brand button — it stops looking
      // like the primary action entirely, as IconButton already does.
      for (final style in [
        MonetaButtonStyle.primary,
        MonetaButtonStyle.secondary,
        MonetaButtonStyle.destructive,
      ]) {
        await pumpButton(
          tester,
          style: style,
          state: MonetaButtonState.disabled,
        );
        expect(
          decorationOf(tester).color,
          colors.surfaceRaised,
          reason: style.name,
        );
      }
    });

    testWidgets('uses tertiary text for every style', (tester) async {
      for (final style in MonetaButtonStyle.values) {
        expect(
          MonetaButton.foregroundFor(
            style,
            MonetaButtonState.disabled,
            colors,
          ),
          colors.textTertiary,
          reason: style.name,
        );
      }
    });

    testWidgets('does not fire its callback', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        state: MonetaButtonState.disabled,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(MonetaButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('is reported disabled to assistive technology', (tester) async {
      await pumpButton(
        tester,
        state: MonetaButtonState.disabled,
        onPressed: () {},
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byType(MonetaButton));
      expect(node.flagsCollection.isEnabled, isNot(Tristate.isTrue));
    });
  });

  group('loading', () {
    testWidgets('keeps the button width stable', (tester) async {
      // Figma states this explicitly, and it is the one state with a layout
      // consequence: a button that shrinks to spinner width mid-action moves
      // everything beside it.
      await pumpButton(tester, label: 'Create my account');
      final normalWidth = tester.getSize(find.byType(MonetaButton)).width;

      await pumpButton(
        tester,
        label: 'Create my account',
        state: MonetaButtonState.loading,
      );
      final loadingWidth = tester.getSize(find.byType(MonetaButton)).width;

      expect(loadingWidth, normalWidth);
    });

    testWidgets('shows a spinner and hides the label', (tester) async {
      await pumpButton(tester, state: MonetaButtonState.loading);
      expect(find.byKey(MonetaButton.spinnerKey), findsOneWidget);

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Next'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0);
    });

    testWidgets('does not fire its callback', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        state: MonetaButtonState.loading,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(MonetaButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('no spinner when not loading', (tester) async {
      await pumpButton(tester);
      expect(find.byKey(MonetaButton.spinnerKey), findsNothing);
    });
  });

  group('content', () {
    testWidgets('renders the label', (tester) async {
      await pumpButton(tester, label: 'Get started');
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('a long label truncates rather than overflowing', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 120,
          child: MonetaButton(label: 'An extremely long button label here'),
        ),
        surfaceSize: const Size(200, 200),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a leading icon takes the icon size for that button size', (
      tester,
    ) async {
      await pumpButton(
        tester,
        size: MonetaButtonSize.lg,
        leading: MonetaIconName.plus,
      );
      final icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      expect(icon.size, MonetaButtonSize.lg.iconSize);
    });

    testWidgets('expand fills the available width', (tester) async {
      await pumpButton(tester, expand: true);
      expect(tester.getSize(find.byType(MonetaButton)).width, 353);
    });
  });

  group('interaction', () {
    testWidgets('fires when enabled', (tester) async {
      var taps = 0;
      await pumpButton(tester, onPressed: () => taps++);
      await tester.tap(find.byType(MonetaButton));
      expect(taps, 1);
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpButton(tester);
      await tester.tap(find.byType(MonetaButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
