import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/typography.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final text = MonetaTypography.figma();

  Future<void> pumpButton(
    WidgetTester tester, {
    MonetaButtonStyle style = MonetaButtonStyle.primary,
    MonetaButtonSize size = MonetaButtonSize.md,
    MonetaButtonState state = MonetaButtonState.normal,
    String label = 'Next',
    VoidCallback? onPressed,
    bool expand = false,
    MonetaIconName? leading,
    MonetaIconName? trailing,
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
          trailingIcon: trailing,
        ),
      ),
      surfaceSize: const Size(420, 300),
    );
  }

  /// The style actually applied to the rendered label.
  ///
  /// The foreground and label-style tests below went through
  /// `MonetaButton.foregroundFor(...)` and `size.labelStyle(...)` — the pure
  /// lookup tables — and never through the widget. Both tables were correct and
  /// neither was wired to anything a test could see: swapping the label colour
  /// for `colors.income`, and `lg`'s style from `titleMd` to `labelSm`, each
  /// passed the whole suite. This reads the render tree instead.
  TextStyle labelStyleOf(WidgetTester tester, {String label = 'Next'}) {
    final text = tester.widget<Text>(find.text(label));
    return text.style!;
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
            // Background, foreground and label style asserted on the rendered
            // widget, not on the lookup tables. tasks.md 2.1 claimed this loop
            // already covered background and foreground; it covered neither.
            final decoration = decorationOf(tester);
            expect(
              decoration.color,
              MonetaButton.backgroundFor(style, state, colors),
              reason: '${style.name}/${size.name}/${state.name} background',
            );
            final applied = labelStyleOf(tester);
            expect(
              applied.color,
              MonetaButton.foregroundFor(style, state, colors),
              reason: '${style.name}/${size.name}/${state.name} foreground',
            );
            expect(
              (applied.fontSize, applied.fontWeight, applied.fontFamily),
              (
                size.labelStyle(text).fontSize,
                size.labelStyle(text).fontWeight,
                size.labelStyle(text).fontFamily,
              ),
              reason: '${style.name}/${size.name}/${state.name} label style',
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

    testWidgets('a trailing icon takes the icon size for that button size', (
      tester,
    ) async {
      // This branch had no test at all and was the only uncovered code in the
      // component.
      await pumpButton(
        tester,
        size: MonetaButtonSize.sm,
        trailing: MonetaIconName.chevronRight,
      );
      final icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      expect(icon.size, MonetaButtonSize.sm.iconSize);
    });

    testWidgets('a leading and a trailing icon sit either side of the label', (
      tester,
    ) async {
      await pumpButton(
        tester,
        leading: MonetaIconName.plus,
        trailing: MonetaIconName.chevronRight,
      );
      final icons = tester.widgetList<MonetaIcon>(find.byType(MonetaIcon));
      expect(icons, hasLength(2));
      final label = tester.getRect(find.text('Next'));
      final first = tester.getRect(find.byType(MonetaIcon).first);
      final last = tester.getRect(find.byType(MonetaIcon).last);
      expect(first.right, lessThanOrEqualTo(label.left));
      expect(last.left, greaterThanOrEqualTo(label.right));
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
  group('the foreground table is pinned to tokens', () {
    // The 45-loop compares the rendered label colour to `foregroundFor(...)` —
    // the table against itself. That catches a broken wiring and nothing else:
    // repointing secondary/tertiary/ghost to `colors.income` passed all 617
    // tests. Only primary and disabled were pinned to a token anywhere.
    test('every style in the normal state names its expected token', () {
      const expected = {
        MonetaButtonStyle.primary: 'textOnBrand',
        MonetaButtonStyle.secondary: 'textPrimary',
        MonetaButtonStyle.tertiary: 'textPrimary',
        MonetaButtonStyle.ghost: 'textPrimary',
        MonetaButtonStyle.destructive: 'textOnBrand',
      };
      final tokens = {
        'textOnBrand': colors.textOnBrand,
        'textPrimary': colors.textPrimary,
      };

      expect(
        expected.keys,
        containsAll(MonetaButtonStyle.values),
        reason: 'a style was added without pinning its label colour',
      );
      for (final entry in expected.entries) {
        expect(
          MonetaButton.foregroundFor(
            entry.key,
            MonetaButtonState.normal,
            colors,
          ),
          tokens[entry.value],
          reason: '${entry.key.name} label colour is not ${entry.value}',
        );
      }
    });

    test('a disabled button of any style uses the tertiary text token', () {
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

    test(
      'the brand-filled and the flat styles do not share a label colour',
      () {
        expect(
          MonetaButton.foregroundFor(
            MonetaButtonStyle.primary,
            MonetaButtonState.normal,
            colors,
          ),
          isNot(
            MonetaButton.foregroundFor(
              MonetaButtonStyle.ghost,
              MonetaButtonState.normal,
              colors,
            ),
          ),
        );
      },
    );
  });

  group('the size table is pinned to Figma', () {
    // horizontalPadding and iconSize were pinned nowhere: sm's padding could go
    // 14 -> 40 and every iconSize could collapse to 24 with a green suite. The
    // existing icon test asserted `icon.size == size.iconSize`, the
    // implementation against itself.
    //
    // figma-map.md records that these paddings and icon sizes were never read
    // from a node inspection. Pinning them here does not make them verified
    // against Figma; it makes them unable to drift silently, which is a
    // different and lesser claim.
    test('each size keeps its authored height, padding and icon size', () {
      const expected = {
        MonetaButtonSize.sm: (height: 36.0, padding: 14.0, icon: 16.0),
        MonetaButtonSize.md: (height: 44.0, padding: 20.0, icon: 20.0),
        MonetaButtonSize.lg: (height: 56.0, padding: 24.0, icon: 24.0),
      };
      expect(expected.keys, containsAll(MonetaButtonSize.values));
      for (final entry in expected.entries) {
        expect(entry.key.height, entry.value.height, reason: entry.key.name);
        expect(
          entry.key.horizontalPadding,
          entry.value.padding,
          reason: entry.key.name,
        );
        expect(entry.key.iconSize, entry.value.icon, reason: entry.key.name);
      }
    });

    testWidgets('the rendered icon takes the size the table names', (
      tester,
    ) async {
      const expected = {
        MonetaButtonSize.sm: 16.0,
        MonetaButtonSize.md: 20.0,
        MonetaButtonSize.lg: 24.0,
      };
      for (final entry in expected.entries) {
        await pumpButton(
          tester,
          size: entry.key,
          leading: MonetaIconName.plus,
        );
        final icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
        expect(icon.size, entry.value, reason: entry.key.name);
      }
    });

    testWidgets('the rendered padding is the one the table names', (
      tester,
    ) async {
      // Read off the render tree, not the enum. `pumpButton` constrains the
      // button to 353px, so comparing overall widths proves nothing — my first
      // version of this test did exactly that and failed for the right reason.
      const expected = {
        MonetaButtonSize.sm: 14.0,
        MonetaButtonSize.md: 20.0,
        MonetaButtonSize.lg: 24.0,
      };
      for (final entry in expected.entries) {
        await pumpButton(tester, size: entry.key);
        final padding = tester.widget<Padding>(
          find
              .descendant(
                of: find.byType(MonetaButton),
                matching: find.byType(Padding),
              )
              .first,
        );
        expect(
          padding.padding.resolve(TextDirection.ltr).left,
          entry.value,
          reason: entry.key.name,
        );
      }
    });
  });

  group('the border table is pinned to tokens', () {
    test('only the bordered styles have a border, in both states', () {
      for (final state in [
        MonetaButtonState.normal,
        MonetaButtonState.disabled,
      ]) {
        expect(
          MonetaButton.borderFor(
            MonetaButtonStyle.tertiary,
            state,
            colors,
          ),
          state == MonetaButtonState.disabled
              ? colors.borderSubtle
              : colors.borderStrong,
          reason: 'tertiary border in ${state.name}',
        );
        for (final style in [
          MonetaButtonStyle.primary,
          MonetaButtonStyle.ghost,
          MonetaButtonStyle.destructive,
        ]) {
          expect(
            MonetaButton.borderFor(style, state, colors),
            isNull,
            reason: '${style.name} should have no border in ${state.name}',
          );
        }
      }
    });
  });

  group('label type scale', () {
    test('the three sizes do not all share one label style', () {
      // Figma authors lg with the title style and the smaller two with a label
      // style. Collapsing the table onto a single style would go unnoticed
      // otherwise — it was, until a mutation caught it.
      final sm = MonetaButtonSize.sm.labelStyle(text);
      final md = MonetaButtonSize.md.labelStyle(text);
      final lg = MonetaButtonSize.lg.labelStyle(text);

      expect(lg.fontSize, isNot(sm.fontSize));
      expect(md.fontSize, sm.fontSize);
      expect(lg.fontSize, 16, reason: 'lg is title/md at 16');
      expect(sm.fontSize, 14, reason: 'sm and md are label/md at 14');
      // Weight as well as size: `titleMd` -> `bodyLg` keeps 16px and drops the
      // semibold, and that mutation survived a size-only assertion.
      expect(lg.fontWeight, FontWeight.w600, reason: 'lg is semibold');
      expect(sm.fontWeight, FontWeight.w500, reason: 'sm and md are medium');
    });

    testWidgets('a lg button renders a visibly larger label than a sm one', (
      tester,
    ) async {
      await pumpButton(tester, size: MonetaButtonSize.sm);
      final small = labelStyleOf(tester).fontSize!;
      await pumpButton(tester, size: MonetaButtonSize.lg);
      final large = labelStyleOf(tester).fontSize!;
      expect(large, greaterThan(small));
    });
  });
}
