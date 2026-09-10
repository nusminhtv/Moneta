import 'dart:io';

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// Transcription tests.
///
/// These assert constants against constants on purpose. Every value here was
/// hand-copied from Figma (see docs/design-system/figma-tokens.md), and
/// mistyping a hex digit is exactly the failure this layer is exposed to. The
/// design-token checker stops raw values appearing *outside* this layer; only a
/// test can catch a wrong value *inside* it.
void main() {
  const colors = MonetaColors.dark();

  group('surface, text and border roles', () {
    test('match the Figma values', () {
      expect(colors.canvas, const Color(0xFF06070A));
      expect(colors.surface, const Color(0xFF0A0C11));
      expect(colors.surfaceRaised, const Color(0xFF0F1218));
      expect(colors.track, const Color(0xFF232935));
      expect(colors.textPrimary, const Color(0xFFF6F8FB));
      expect(colors.textTertiary, const Color(0xFF7C8595));
      expect(colors.textOnBrand, const Color(0xFFFFFFFF));
    });

    test('secondary text is the value read from 107:75', () {
      expect(colors.textSecondary, const Color(0xFF9AA3B4));
    });

    test('the three text tones are ordered by prominence', () {
      // primary brightest, tertiary dimmest — a reader should be able to tell
      // which is which without looking up the hex.
      expect(
        colors.textPrimary.computeLuminance(),
        greaterThan(colors.textSecondary.computeLuminance()),
      );
      expect(
        colors.textSecondary.computeLuminance(),
        greaterThan(colors.textTertiary.computeLuminance()),
      );
    });

    test('strong border is white at 18%, and stronger than subtle', () {
      expect(colors.borderStrong.r, 1.0);
      expect(colors.borderStrong.a, closeTo(0.18, 0.003));
      expect(colors.borderStrong.a, greaterThan(colors.borderSubtle.a));
    });

    test('subtle border is white at 6% opacity', () {
      expect(colors.borderSubtle.r, 1.0);
      expect(colors.borderSubtle.g, 1.0);
      expect(colors.borderSubtle.b, 1.0);
      // Figma authors 0.06; the nearest 8-bit alpha is 15/255 = 0.0588.
      expect(colors.borderSubtle.a, closeTo(0.06, 0.002));
    });
  });

  group('brand', () {
    test('base colours match Figma', () {
      expect(colors.brand, const Color(0xFF7A5AF8));
      expect(colors.brandOnSurface, const Color(0xFF876BF9));
      expect(MonetaColors.violet600, const Color(0xFF6541EA));
      expect(MonetaColors.violet500, const Color(0xFF7A5AF8));
      expect(MonetaColors.mint600, const Color(0xFF12A87A));
    });

    test('brand base is the same value as the mid gradient stop', () {
      // Not a coincidence in Figma, so not allowed to drift here either.
      expect(colors.brand, MonetaColors.violet500);
    });
  });

  group('brand gradient', () {
    final gradient = MonetaColors.brandGradient;

    test('is built from the named palette constants, not fresh literals', () {
      expect(gradient.colors, [
        MonetaColors.violet600,
        MonetaColors.violet500,
        MonetaColors.mint600,
      ]);
    });

    test('keeps the Figma stops', () {
      expect(gradient.stops, [
        closeTo(0.073529, 1e-6),
        closeTo(0.47794, 1e-6),
        closeTo(0.80882, 1e-6),
      ]);
    });

    test('direction encodes the Figma angle', () {
      const radians = MonetaColors.brandGradientAngleDegrees * math.pi / 180;
      final begin = gradient.begin as Alignment;
      final end = gradient.end as Alignment;
      expect(end.x, closeTo(math.sin(radians), 1e-9));
      expect(end.y, closeTo(-math.cos(radians), 1e-9));
      expect(begin.x, closeTo(-end.x, 1e-9));
      expect(begin.y, closeTo(-end.y, 1e-9));
    });

    test('runs down-and-right, as authored', () {
      final end = gradient.end as Alignment;
      expect(end.x, greaterThan(0));
      expect(end.y, greaterThan(0));
    });
  });

  group('semantic colours', () {
    test('base values match Figma', () {
      expect(colors.income, const Color(0xFF22D19A));
      expect(colors.expense, const Color(0xFFF4515C));
      expect(colors.warning, const Color(0xFFFFA92B));
      expect(colors.info, const Color(0xFF2E9BFF));
    });

    test('subtle companions match Figma', () {
      expect(colors.incomeSubtle, const Color(0xFF072A22));
      expect(colors.expenseSubtle, const Color(0xFF2E0F13));
      expect(colors.warningSubtle, const Color(0xFF2E1E05));
      expect(colors.infoSubtle, const Color(0xFF06203A));
      // Added by `profile-components`, from `21:106`'s bound `brand/subtle`.
      // It was the one missing member of this family, and `Avatar` fills it on
      // all twelve of its variants.
      expect(colors.brandSubtle, const Color(0xFF1A1236));
    });

    test(
      'every semantic base has a subtle counterpart, the brand included',
      () {
        // The gap this closes: four of five families had one. A test naming the
        // four could not notice the fifth was missing, which is how it stayed
        // missing until a component needed it.
        for (final pair in <(String, Color, Color)>[
          ('income', colors.income, colors.incomeSubtle),
          ('expense', colors.expense, colors.expenseSubtle),
          ('warning', colors.warning, colors.warningSubtle),
          ('info', colors.info, colors.infoSubtle),
          ('brand', colors.brand, colors.brandSubtle),
        ]) {
          expect(
            pair.$3,
            isNot(pair.$2),
            reason: '${pair.$1} subtle equals its base',
          );
        }
      },
    );

    test('brandSubtle differs from every surface it sits on', () {
      // A tint identical to its background is not a tint.
      for (final surface in [
        colors.canvas,
        colors.surface,
        colors.surfaceRaised,
      ]) {
        expect(colors.brandSubtle, isNot(surface));
      }
    });

    test('the four tones are mutually distinct', () {
      final tones = {
        colors.income,
        colors.expense,
        colors.warning,
        colors.info,
      };
      expect(tones, hasLength(4));
    });

    test('each subtle tint is darker than its base', () {
      // A tint that is not darker would fail as a background behind its base.
      for (final pair in [
        (colors.income, colors.incomeSubtle),
        (colors.expense, colors.expenseSubtle),
        (colors.warning, colors.warningSubtle),
        (colors.info, colors.infoSubtle),
        (colors.brand, colors.brandSubtle),
      ]) {
        expect(
          pair.$2.computeLuminance(),
          lessThan(pair.$1.computeLuminance()),
          reason: 'subtle tint must be darker than its base',
        );
      }
    });
  });

  group('chart palette', () {
    final chart = colors.chart;

    test('has exactly 8 base and 8 subtle slots', () {
      expect(MonetaChartPalette.slotCount, 8);
      expect(chart.bases, hasLength(8));
      expect(chart.subtles, hasLength(8));
    });

    test('base values match Figma, slot by slot', () {
      expect(chart.base(1), const Color(0xFF009E62), reason: 'mint');
      expect(chart.base(2), const Color(0xFF8879FE), reason: 'violet');
      expect(chart.base(3), const Color(0xFFB3041C), reason: 'coral');
      expect(chart.base(4), const Color(0xFF027ED8), reason: 'sky');
      expect(chart.base(5), const Color(0xFF769200), reason: 'lime');
      expect(chart.base(6), const Color(0xFFA30088), reason: 'pink');
      expect(chart.base(7), const Color(0xFFAA7705), reason: 'amber');
      expect(chart.base(8), const Color(0xFF0B9B9C), reason: 'teal');
    });

    test('subtle values match Figma, slot by slot', () {
      expect(chart.subtle(1), const Color(0xFF051F18));
      expect(chart.subtle(2), const Color(0xFF1B1931));
      expect(chart.subtle(3), const Color(0xFF22070D));
      expect(chart.subtle(4), const Color(0xFF051A2B));
      expect(chart.subtle(5), const Color(0xFF181D08));
      expect(chart.subtle(6), const Color(0xFF1F061E));
      expect(chart.subtle(7), const Color(0xFF201909));
      expect(chart.subtle(8), const Color(0xFF071F21));
    });

    test('all eight base colours are distinct', () {
      expect(chart.bases.toSet(), hasLength(8));
    });

    test('every subtle tint is darker than its own base', () {
      for (var slot = 1; slot <= 8; slot++) {
        expect(
          chart.subtle(slot).computeLuminance(),
          lessThan(chart.base(slot).computeLuminance()),
          reason: 'slot $slot',
        );
      }
    });

    test('slots are 1-based and reject out-of-range access', () {
      expect(chart.base(1), chart.bases.first);
      expect(chart.base(8), chart.bases.last);
      expect(() => chart.base(0), throwsAssertionError);
      expect(() => chart.base(9), throwsAssertionError);
      expect(() => chart.subtle(0), throwsAssertionError);
      expect(() => chart.subtle(9), throwsAssertionError);
    });
  });

  group('lerp', () {
    test('at t=0 returns the source values', () {
      const other = MonetaColors.dark();
      final mid = colors.lerp(other, 0);
      expect(mid.canvas, colors.canvas);
      expect(mid.chart.base(3), colors.chart.base(3));
    });

    test('interpolates every role, including the chart palette', () {
      const white = Color(0xFFFFFFFF);
      final target = MonetaColors(
        canvas: white,
        surface: white,
        surfaceRaised: white,
        track: white,
        borderSubtle: white,
        borderStrong: white,
        borderDefault: white,
        borderFocus: white,
        textPrimary: white,
        textSecondary: white,
        textDisabled: white,
        textTertiary: white,
        textOnBrand: white,
        brand: white,
        brandOnSurface: white,
        brandSubtle: white,
        income: white,
        incomeSubtle: white,
        expense: white,
        expenseSubtle: white,
        warning: white,
        warningSubtle: white,
        info: white,
        infoSubtle: white,
        chart: MonetaChartPalette(
          bases: List.filled(8, white),
          subtles: List.filled(8, white),
        ),
      );
      final mid = colors.lerp(target, 1);

      // Every colour, not three remembered ones. The previous version asserted
      // canvas, income and one chart slot, so a field left out of `lerp`
      // entirely was silent — dropping `borderFocus` from it passed. `all` is
      // asserted to be complete by the test below, so this cannot narrow again.
      expect(
        mid.all,
        everyElement(white),
        reason: 'a colour was not interpolated — is it missing from lerp?',
      );
      expect(mid.chart.base(5), white);
      expect(mid.chart.subtle(5), white);
    });
  });

  group('the colour set is enumerable', () {
    test('`all` lists every declared colour field', () {
      // The guard on the guard. `all` drives the lerp check above, so a field
      // missing from `all` would make that check narrow silently — the exact
      // shape of defect that let three remembered assertions stand in for
      // twenty-three colours.
      //
      // A plain test(), not testWidgets: file I/O in a FakeAsync zone never
      // completes and would hang rather than fail. See CLAUDE.md.
      final source = File(
        'lib/design_system/tokens/colors.dart',
      ).readAsStringSync();
      final declared = RegExp(
        r'^  final Color (\w+);',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toSet();
      final block = source.substring(
        source.indexOf('List<Color> get all => ['),
      );
      final listed = RegExp(r'^    (\w+),', multiLine: true)
          .allMatches(block.substring(0, block.indexOf('];')))
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        declared,
        isNotEmpty,
        reason: 'parsed no fields — check is vacuous',
      );
      expect(
        listed,
        declared,
        reason: 'a declared colour is missing from `all`, or vice versa',
      );
    });
  });
}
