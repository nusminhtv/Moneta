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

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;
    final base = colors.chart.base(chartSlot);
    final subtle = colors.chart.subtle(chartSlot);

    return SizedBox(
      height: bandHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Figma positions are absolute inside a 353-wide band. Scaling keeps
          // them proportional on a narrower device rather than clipping.
          final scale = constraints.maxWidth / designWidth;
          double x(double v) => v * scale;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x(45.5),
                top: 3,
                child: _Circle(
                  diameter: x(ringSize),
                  border: colors.borderSubtle,
                ),
              ),
              Positioned(
                left: x(70.5),
                top: 28,
                child: _Circle(diameter: x(haloSize), fill: subtle),
              ),
              Positioned(
                left: x(140.5),
                top: 98,
                child: MonetaIcon(glyph, size: x(glyphSize), color: base),
              ),
              for (final dot in accentDots)
                Positioned(
                  left: x(dot.left),
                  top: dot.top,
                  child: Opacity(
                    opacity: accentDotOpacity,
                    child: _Circle(diameter: x(dot.size), fill: base),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.diameter, this.fill, this.border});

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
