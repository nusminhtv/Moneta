import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// The circular illustration on an onboarding slide.
///
/// Transcribed from Figma `71:59`. Every value here was read from the exported
/// SVGs rather than guessed, and every one turned out to be a token: the halo is
/// the slot's subtle tint, the ring is `border-subtle` (white at 0.0588), and the
/// accent dots are the slot's base colour at 50%.
///
/// So it is drawn natively rather than shipped as six SVG assets. That is not
/// only fewer files: `tool/check_design_tokens.dart` can see native paint and
/// cannot see inside an SVG, so drawing it keeps the illustration under the same
/// gate as everything else.
class OnboardingIllustration extends StatelessWidget {
  /// Creates an illustration for a chart-palette slot.
  const OnboardingIllustration({
    required this.glyph,
    required this.chartSlot,
    super.key,
  });

  /// The 72px glyph at the centre.
  final MonetaIconName glyph;

  /// 1-based chart-palette slot that themes the illustration.
  final int chartSlot;

  /// Height of the illustration band, from the Figma frame.
  static const double bandHeight = 268;

  /// Width the Figma positions are measured against.
  static const double designWidth = 353;

  /// Diameter of the filled halo.
  static const double haloSize = 212;

  /// Diameter of the hairline ring.
  static const double ringSize = 262;

  /// Edge length of the centre glyph.
  static const double glyphSize = 72;

  /// The four accent dots, exactly as Figma places them.
  static const List<({double left, double top, double size})> accentDots = [
    (left: 64, top: 66, size: 12),
    (left: 274, top: 104, size: 8),
    (left: 96, top: 224, size: 9),
    (left: 258, top: 218, size: 14),
  ];

  /// Opacity Figma applies to every accent dot.
  static const double accentDotOpacity = 0.5;

  /// The hairline ring, for tests that assert the geometry.
  static const Key ringKey = ValueKey('onboardingIllustration.ring');

  /// The filled halo.
  static const Key haloKey = ValueKey('onboardingIllustration.halo');

  /// The centre glyph.
  static const Key glyphKey = ValueKey('onboardingIllustration.glyph');

  /// One accent dot, by its index in [accentDots].
  static Key dotKey(int index) => ValueKey('onboardingIllustration.dot.$index');

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;
    final base = colors.chart.base(chartSlot);
    final subtle = colors.chart.subtle(chartSlot);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Figma positions are absolute inside a 353-wide band. Both axes scale
        // by the same factor, so the ring, halo and glyph stay concentric on a
        // narrower device. Scaling only `left` — which is what this did — left
        // them concentric at exactly 353px and nowhere else: at 280 wide the
        // glyph sat about 20px above the ring's centre.
        //
        // Never scaled up. Figma draws this at 353 inside a 393 screen; on a
        // tablet a proportionally enormous halo is not what the design means, so
        // it holds its authored size and centres instead.
        final scale = math.min(1, constraints.maxWidth / designWidth);
        double s(double v) => v * scale;

        return SizedBox(
          height: s(bandHeight),
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: s(designWidth),
              height: s(bandHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: s(45.5),
                    top: s(3),
                    child: _Circle(
                      key: ringKey,
                      diameter: s(ringSize),
                      border: colors.borderSubtle,
                    ),
                  ),
                  Positioned(
                    left: s(70.5),
                    top: s(28),
                    child: _Circle(
                      key: haloKey,
                      diameter: s(haloSize),
                      fill: subtle,
                    ),
                  ),
                  Positioned(
                    left: s(140.5),
                    top: s(98),
                    child: MonetaIcon(
                      glyph,
                      key: glyphKey,
                      size: s(glyphSize),
                      color: base,
                    ),
                  ),
                  for (final (index, dot) in accentDots.indexed)
                    Positioned(
                      left: s(dot.left),
                      top: s(dot.top),
                      child: Opacity(
                        opacity: accentDotOpacity,
                        child: _Circle(
                          key: dotKey(index),
                          diameter: s(dot.size),
                          fill: base,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.diameter, this.fill, this.border, super.key});

  final double diameter;
  final Color? fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: border == null ? null : Border.all(color: border!),
        ),
      ),
    );
  }
}
