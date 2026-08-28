import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/motion.dart';
import 'package:moneta/design_system/tokens/radii.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

import '../../support/pump.dart';

void main() {
  group('reachability from context', () {
    testWidgets('every token group is readable from a pumped widget', (
      tester,
    ) async {
      MonetaTheme? seen;
      await pumpMonetaWidget(
        tester,
        Builder(
          builder: (context) {
            seen = context.moneta;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(seen, isNotNull);
      expect(seen!.colors.income, const Color(0xFF22D19A));
      expect(seen!.text.amountXl.fontSize, 40);
      expect(seen!.spacing.x3l, 16);
      expect(seen!.radii.xl, 24);
      expect(seen!.elevation.level3, hasLength(1));
      expect(seen!.motion.normal, const Duration(milliseconds: 250));
    });

    testWidgets('throws a directive error when the extension is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Deliberately no MonetaTheme extension.
              expect(
                () => context.moneta,
                throwsA(
                  isA<FlutterError>().having(
                    (e) => e.message,
                    'message',
                    allOf(
                      contains('No MonetaTheme found'),
                      contains('pumpMonetaWidget'),
                    ),
                  ),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('test-time override', () {
    testWidgets('a substituted token set reaches the widget', (tester) async {
      const magenta = Color(0xFFFF00FF);
      const base = MonetaColors.dark();
      // Replace exactly one role, to prove the override is granular rather
      // than all-or-nothing.
      final theme = MonetaTheme.dark().copyWith(
        colors: MonetaColors(
          canvas: magenta,
          surface: base.surface,
          surfaceRaised: base.surfaceRaised,
          track: base.track,
          borderSubtle: base.borderSubtle,
          borderStrong: base.borderStrong,
          borderDefault: base.borderDefault,
          borderFocus: base.borderFocus,
          textPrimary: base.textPrimary,
          textSecondary: base.textSecondary,
          textTertiary: base.textTertiary,
          textDisabled: base.textDisabled,
          textOnBrand: base.textOnBrand,
          brand: base.brand,
          brandOnSurface: base.brandOnSurface,
          income: base.income,
          incomeSubtle: base.incomeSubtle,
          expense: base.expense,
          expenseSubtle: base.expenseSubtle,
          warning: base.warning,
          warningSubtle: base.warningSubtle,
          info: base.info,
          infoSubtle: base.infoSubtle,
          chart: base.chart,
        ),
      );

      Color? seen;
      await pumpMonetaWidget(
        tester,
        Builder(
          builder: (context) {
            seen = context.moneta.colors.canvas;
            return const SizedBox.shrink();
          },
        ),
        theme: theme,
      );

      expect(seen, magenta);
    });

    testWidgets('overriding one role leaves the others intact', (tester) async {
      MonetaTheme? seen;
      await pumpMonetaWidget(
        tester,
        Builder(
          builder: (context) {
            seen = context.moneta;
            return const SizedBox.shrink();
          },
        ),
        theme: MonetaTheme.dark().copyWith(
          motion: const MonetaMotion(
            fast: Duration.zero,
            normal: Duration.zero,
            slow: Duration.zero,
            standard: Curves.linear,
            emphasised: Curves.linear,
          ),
        ),
      );
      expect(seen!.motion.normal, Duration.zero);
      expect(seen!.colors.income, const MonetaColors.dark().income);
      expect(seen!.radii.xl, 24);
    });
  });

  group('toThemeData', () {
    final data = MonetaTheme.dark().toThemeData();
    const colors = MonetaColors.dark();

    test('carries the extension', () {
      expect(data.extension<MonetaTheme>(), isNotNull);
    });

    test('is dark and uses Material 3', () {
      expect(data.brightness, Brightness.dark);
      expect(data.useMaterial3, isTrue);
    });

    test('maps tokens onto Material colour slots', () {
      expect(data.colorScheme.primary, colors.brand);
      expect(data.colorScheme.surface, colors.surface);
      expect(data.colorScheme.error, colors.expense);
      expect(data.colorScheme.onSurface, colors.textPrimary);
    });

    test('paints the canvas, so an unstyled Scaffold is not Material grey', () {
      expect(data.scaffoldBackgroundColor, colors.canvas);
      expect(data.canvasColor, colors.canvas);
    });

    test('maps the type scale onto Material text slots', () {
      final type = MonetaTypography.figma();
      expect(data.textTheme.displayLarge!.fontSize, type.amountXl.fontSize);
      expect(data.textTheme.headlineLarge!.fontSize, type.headingH1.fontSize);
      expect(data.textTheme.bodyMedium!.fontSize, type.bodyMd.fontSize);
      expect(data.textTheme.labelMedium!.fontSize, type.labelSm.fontSize);
    });

    test('text defaults to the primary text colour, not Material white', () {
      expect(data.textTheme.bodyMedium!.color, colors.textPrimary);
      expect(data.textTheme.displayLarge!.color, colors.textPrimary);
    });

    test('defaults the font family to the text family', () {
      // An unstyled Text must not fall back to Roboto.
      expect(data.textTheme.bodyMedium!.fontFamily, MonetaFontFamily.text);
    });
  });

  group('lerp', () {
    test('returns itself when the other side is null', () {
      final theme = MonetaTheme.dark();
      expect(theme.lerp(null, 0.5), same(theme));
    });

    test('interpolates colours but snaps structural tokens', () {
      final a = MonetaTheme.dark();
      final b = a.copyWith(
        spacing: const MonetaSpacing.figma(),
        radii: const MonetaRadii(xs: 0, md: 1, lg: 2, xl: 3, pill: 4),
      );

      // Below the midpoint, structural tokens stay on the source side...
      expect(a.lerp(b, 0.2).radii.xl, a.radii.xl);
      // ...and above it they snap to the target, never landing between.
      expect(a.lerp(b, 0.8).radii.xl, 3);
      expect(a.lerp(b, 0.5).radii.xl, 3);
    });

    test('copyWith replaces only what it is given', () {
      final a = MonetaTheme.dark();
      final b = a.copyWith(motion: const MonetaMotion.defaults());
      expect(b.colors, same(a.colors));
      expect(b.text, same(a.text));
      expect(b.radii, same(a.radii));
    });
  });
}
