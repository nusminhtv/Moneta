import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// The two font families the design uses.
abstract final class MonetaFontFamily {
  /// Body, labels and titles.
  static const String text = 'Inter';

  /// Amounts and headings.
  static const String display = 'Plus Jakarta Sans';
}

/// The named text styles transcribed from the Figma type scale.
///
/// Figma authors line height in pixels and letter spacing as a percentage of
/// font size; Flutter wants a height *multiplier* and an absolute letter
/// spacing. [_style] does that conversion in one place so the constants below
/// stay readable as the Figma values they came from.
@immutable
final class MonetaTypography {
  /// Creates a type set from explicit styles.
  const MonetaTypography({
    required this.amountXl,
    required this.amountMd,
    required this.headingH1,
    required this.headingH2,
    required this.headingH3,
    required this.titleMd,
    required this.bodyLg,
    required this.bodyMd,
    required this.labelMd,
    required this.labelSm,
    required this.captionMd,
  });

  /// The scale read from Figma. See docs/design-system/figma-tokens.md.
  MonetaTypography.figma()
    : amountXl = _style(
        family: MonetaFontFamily.display,
        weight: FontWeight.w700,
        size: 40,
        lineHeightPx: 44,
        trackingPercent: -1,
      ),
      amountMd = _style(
        family: MonetaFontFamily.display,
        weight: FontWeight.w600,
        size: 20,
        lineHeightPx: 26,
      ),
      headingH1 = _style(
        family: MonetaFontFamily.display,
        weight: FontWeight.w700,
        size: 28,
        lineHeightPx: 34,
        trackingPercent: -1,
      ),
      headingH2 = _style(
        family: MonetaFontFamily.display,
        weight: FontWeight.w600,
        size: 22,
        lineHeightPx: 28,
        trackingPercent: -0.5,
      ),
      headingH3 = _style(
        family: MonetaFontFamily.display,
        weight: FontWeight.w600,
        size: 18,
        lineHeightPx: 24,
      ),
      titleMd = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w600,
        size: 16,
        lineHeightPx: 22,
      ),
      bodyLg = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w400,
        size: 16,
        lineHeightPx: 24,
      ),
      bodyMd = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w400,
        size: 14,
        lineHeightPx: 20,
      ),
      labelMd = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w500,
        size: 14,
        lineHeightPx: 18,
      ),
      labelSm = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w500,
        size: 12,
        lineHeightPx: 16,
      ),
      captionMd = _style(
        family: MonetaFontFamily.text,
        weight: FontWeight.w400,
        size: 12,
        lineHeightPx: 16,
      );

  /// `display/amount-xl` — the hero balance figure.
  final TextStyle amountXl;

  /// `display/amount-md` — amounts inside cards and rows.
  final TextStyle amountMd;

  /// `heading/h1` — large screen titles.
  final TextStyle headingH1;

  /// `heading/h2` — the currency glyph beside a hero amount, from `36:76`.
  final TextStyle headingH2;

  /// Level-3 heading. The compact app-bar title, from `39:58`.
  final TextStyle headingH3;

  /// `title/md` — card and section titles.
  final TextStyle titleMd;

  /// `body/lg` — prominent running text, e.g. onboarding body copy.
  final TextStyle bodyLg;

  /// `body/md` — running text.
  final TextStyle bodyMd;

  /// `label/md` — emphasised inline labels.
  final TextStyle labelMd;

  /// `label/sm` — tab labels and small emphasis.
  final TextStyle labelSm;

  /// `caption/md` — secondary notes and supporting figures.
  final TextStyle captionMd;

  /// Every style, in scale order. Used by tests and the gallery.
  List<TextStyle> get all => [
    amountXl,
    amountMd,
    headingH1,
    headingH2,
    headingH3,
    titleMd,
    bodyLg,
    bodyMd,
    labelMd,
    labelSm,
    captionMd,
  ];

  static TextStyle _style({
    required String family,
    required FontWeight weight,
    required double size,
    required double lineHeightPx,
    double trackingPercent = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontWeight: weight,
      fontSize: size,
      height: lineHeightPx / size,
      letterSpacing: size * trackingPercent / 100,
      // Figma line boxes are centred; without this Flutter puts the whole
      // leading below the baseline and the text sits high in its box.
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Linearly interpolates between two type sets.
  MonetaTypography lerp(MonetaTypography other, double t) {
    return MonetaTypography(
      amountXl: TextStyle.lerp(amountXl, other.amountXl, t)!,
      amountMd: TextStyle.lerp(amountMd, other.amountMd, t)!,
      headingH1: TextStyle.lerp(headingH1, other.headingH1, t)!,
      headingH2: TextStyle.lerp(headingH2, other.headingH2, t)!,
      headingH3: TextStyle.lerp(headingH3, other.headingH3, t)!,
      titleMd: TextStyle.lerp(titleMd, other.titleMd, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      labelMd: TextStyle.lerp(labelMd, other.labelMd, t)!,
      labelSm: TextStyle.lerp(labelSm, other.labelSm, t)!,
      captionMd: TextStyle.lerp(captionMd, other.captionMd, t)!,
    );
  }
}
