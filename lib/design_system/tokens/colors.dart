import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// The eight-slot chart palette.
///
/// Slots are 1-based to match the Figma token names (`chart/1` … `chart/8`).
/// Each slot pairs a `base` colour, used for glyphs, bars and marks, with a
/// `subtle` tint used as its background.
///
/// The Figma file records that this palette was validated as a set — worst
/// adjacent colour-vision-deficiency deltaE 16.0, all eight inside one OKLCH
/// lightness band. Changing a single slot in isolation breaks that guarantee.
@immutable
final class MonetaChartPalette {
  /// Creates a palette from explicit base and subtle lists.
  const MonetaChartPalette({required this.bases, required this.subtles});

  /// The palette read from Figma node `33:311`.
  const MonetaChartPalette.figma()
    : bases = const [
        Color(0xFF009E62), // 1 mint
        Color(0xFF8879FE), // 2 violet
        Color(0xFFB3041C), // 3 coral
        Color(0xFF027ED8), // 4 sky
        Color(0xFF769200), // 5 lime
        Color(0xFFA30088), // 6 pink
        Color(0xFFAA7705), // 7 amber
        Color(0xFF0B9B9C), // 8 teal
      ],
      subtles = const [
        Color(0xFF051F18), // 1 mint
        Color(0xFF1B1931), // 2 violet
        Color(0xFF22070D), // 3 coral
        Color(0xFF051A2B), // 4 sky
        Color(0xFF181D08), // 5 lime
        Color(0xFF1F061E), // 6 pink
        Color(0xFF201909), // 7 amber
        Color(0xFF071F21), // 8 teal
      ];

  /// Base colours, index 0 holding slot 1.
  final List<Color> bases;

  /// Subtle background tints, index 0 holding slot 1.
  final List<Color> subtles;

  /// Number of slots in the palette.
  static const int slotCount = 8;

  /// Base colour for a 1-based [slot].
  Color base(int slot) {
    assert(
      slot >= 1 && slot <= slotCount,
      'chart slot must be 1..$slotCount, got $slot',
    );
    return bases[slot - 1];
  }

  /// Subtle background tint for a 1-based [slot].
  Color subtle(int slot) {
    assert(
      slot >= 1 && slot <= slotCount,
      'chart slot must be 1..$slotCount, got $slot',
    );
    return subtles[slot - 1];
  }

  /// Linearly interpolates between two palettes.
  MonetaChartPalette lerp(MonetaChartPalette other, double t) {
    return MonetaChartPalette(
      bases: [
        for (var i = 0; i < bases.length; i++)
          Color.lerp(bases[i], other.bases[i], t)!,
      ],
      subtles: [
        for (var i = 0; i < subtles.length; i++)
          Color.lerp(subtles[i], other.subtles[i], t)!,
      ],
    );
  }
}

/// Every colour Moneta uses, grouped by role rather than by hue.
///
/// Roles are named for meaning — `income`, `expense`, `warning` — so a caller
/// cannot reach for "green" for something that is not income.
@immutable
final class MonetaColors {
  /// Creates a colour set from explicit values.
  const MonetaColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.track,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderDefault,
    required this.borderFocus,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnBrand,
    required this.brand,
    required this.brandOnSurface,
    required this.income,
    required this.incomeSubtle,
    required this.expense,
    required this.expenseSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.info,
    required this.infoSubtle,
    required this.chart,
  });

  /// The dark colour set, the only one the Figma file defines.
  const MonetaColors.dark()
    : canvas = violet900Canvas,
      surface = const Color(0xFF0A0C11),
      surfaceRaised = const Color(0xFF0F1218),
      track = const Color(0xFF232935),
      // Figma: rgba(255,255,255,0.06). 0.06 × 255 = 15.3 → 0x0F.
      borderSubtle = const Color(0x0FFFFFFF),
      // Figma: rgba(255,255,255,0.18). 0.18 × 255 = 45.9 → 0x2E.
      borderStrong = const Color(0x2EFFFFFF),
      // Figma: rgba(255,255,255,0.10). 0.10 × 255 = 25.5 → 0x1A.
      borderDefault = const Color(0x1AFFFFFF),
      borderFocus = const Color(0xFF9A83FB),
      textPrimary = const Color(0xFFF6F8FB),
      textSecondary = const Color(0xFF9AA3B4),
      textTertiary = const Color(0xFF7C8595),
      textDisabled = const Color(0xFF3D4553),
      textOnBrand = const Color(0xFFFFFFFF),
      brand = violet500,
      brandOnSurface = const Color(0xFF876BF9),
      income = const Color(0xFF22D19A),
      incomeSubtle = const Color(0xFF072A22),
      expense = const Color(0xFFF4515C),
      expenseSubtle = const Color(0xFF2E0F13),
      warning = const Color(0xFFFFA92B),
      warningSubtle = const Color(0xFF2E1E05),
      info = const Color(0xFF2E9BFF),
      infoSubtle = const Color(0xFF06203A),
      chart = const MonetaChartPalette.figma();

  // ── Brand palette constants ────────────────────────────────────────────
  // Named separately because the brand gradient has to be built from these
  // rather than from fresh literals: Figma cannot bind a variable to a gradient
  // stop, so this is the one place a palette change would otherwise not
  // propagate.

  /// Darkest brand violet — gradient stop 0.
  static const Color violet600 = Color(0xFF6541EA);

  /// Mid brand violet — gradient stop 1, and the brand base colour.
  static const Color violet500 = Color(0xFF7A5AF8);

  /// Brand mint, one step lighter than [mint600]. The mark gradient's second
  /// stop, and numerically the same value the [income] semantic token carries —
  /// named separately because one is a palette entry and the other is a meaning.
  static const Color mint500 = Color(0xFF22D19A);

  /// Brand mint — gradient stop 2.
  static const Color mint600 = Color(0xFF12A87A);

  /// App background behind all surfaces.
  static const Color violet900Canvas = Color(0xFF06070A);

  /// Angle of the brand gradient, in degrees, as authored in Figma.
  static const double brandGradientAngleDegrees = 137.66142364584857;

  /// The single gradient in the design system.
  ///
  /// The Figma file states this is its only hard-coded paint, and that the fill
  /// must be updated by hand if the violet/mint tokens change. Building it from
  /// [violet600], [violet500] and [mint600] means a palette change does
  /// propagate here.
  ///
  /// The CSS angle is converted to Flutter alignments: a CSS angle of 0°
  /// points to the top and increases clockwise, so the gradient direction is
  /// `(sin θ, −cos θ)` in screen coordinates. Alignment space is normalised per
  /// axis, so on a non-square box the rendered angle differs slightly from the
  /// authored one — acceptable here because the card is a fixed 353×187.
  static LinearGradient get brandGradient {
    const radians = brandGradientAngleDegrees * math.pi / 180;
    final dx = math.sin(radians);
    final dy = -math.cos(radians);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: const [violet600, violet500, mint600],
      stops: const [0.073529, 0.47794, 0.80882],
    );
  }

  /// Angle of the brand mark's gradient, in degrees, as authored in Figma.
  static const double markGradientAngleDegrees = 128.4801994866932;

  /// The brand mark's gradient, from `70:206`.
  ///
  /// The second and last hardcoded gradient in this system — Figma's own note on
  /// `70:205` says so, and the tokens spec bounds it at two. Its stops read the
  /// palette constants rather than fresh literals, so a palette change
  /// propagates.
  static LinearGradient get markGradient {
    const radians = markGradientAngleDegrees * math.pi / 180;
    final dx = math.sin(radians);
    final dy = -math.cos(radians);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: const [violet500, mint500],
      stops: const [0.14286, 0.85714],
    );
  }

  /// App background, behind every surface.
  final Color canvas;

  /// Default surface colour — bars and sheets.
  final Color surface;

  /// Raised surface colour — cards.
  final Color surfaceRaised;

  /// Unfilled portion of a progress track.
  final Color track;

  /// Hairline border on surfaces.
  final Color borderSubtle;

  /// Stronger border — inactive pagination dots, dividers that must be seen.
  final Color borderStrong;

  /// The resting border of an input. From `27:5`.
  final Color borderDefault;

  /// The border of a focused input. From `27:18`.
  ///
  /// Focus is never signalled by this colour alone: the border width changes
  /// too, so the state survives greyscale.
  final Color borderFocus;

  /// Primary body and heading text.
  final Color textPrimary;

  /// Secondary body copy — one step down from primary, above tertiary.
  final Color textSecondary;

  /// De-emphasised text and inactive icons.
  final Color textTertiary;

  /// Text in a disabled control. From `27:38`.
  ///
  /// Its own opaque value, not [textPrimary] at reduced opacity: an
  /// opacity-derived colour composites differently against `surface` than
  /// against `surfaceRaised`, so the same disabled control would differ between
  /// two screens.
  final Color textDisabled;

  /// Text and icons drawn on the brand gradient.
  final Color textOnBrand;

  /// Brand fill — the FAB and primary actions.
  final Color brand;

  /// Brand colour when drawn on a dark surface, e.g. the active nav tab.
  final Color brandOnSurface;

  /// Money coming in.
  final Color income;

  /// Tinted background paired with [income].
  final Color incomeSubtle;

  /// Money going out, and the over-limit state.
  final Color expense;

  /// Tinted background paired with [expense].
  final Color expenseSubtle;

  /// Approaching a limit.
  final Color warning;

  /// Tinted background paired with [warning].
  final Color warningSubtle;

  /// Neutral informational tone.
  final Color info;

  /// Tinted background paired with [info].
  final Color infoSubtle;

  /// The eight-slot categorical palette.
  final MonetaChartPalette chart;

  /// Every top-level colour this set carries, for checks that must cover all of
  /// them rather than a remembered few.
  ///
  /// [chart] is excluded: it is a palette with its own accessors, and
  /// [MonetaChartPalette] exposes its own members.
  List<Color> get all => [
    canvas,
    surface,
    surfaceRaised,
    track,
    borderSubtle,
    borderStrong,
    borderDefault,
    borderFocus,
    textPrimary,
    textSecondary,
    textTertiary,
    textDisabled,
    textOnBrand,
    brand,
    brandOnSurface,
    income,
    incomeSubtle,
    expense,
    expenseSubtle,
    warning,
    warningSubtle,
    info,
    infoSubtle,
  ];

  /// Linearly interpolates between two colour sets.
  MonetaColors lerp(MonetaColors other, double t) {
    return MonetaColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      track: Color.lerp(track, other.track, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandOnSurface: Color.lerp(brandOnSurface, other.brandOnSurface, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSubtle: Color.lerp(incomeSubtle, other.incomeSubtle, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSubtle: Color.lerp(expenseSubtle, other.expenseSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t)!,
      chart: chart.lerp(other.chart, t),
    );
  }
}
