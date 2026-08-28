import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The brand logo.
///
/// From Figma node `70:205` — two forms, both implemented: the mark alone, and
/// the mark with the wordmark.
///
/// Drawn natively, with no asset. `70:206` is a 48px rounded container carrying
/// the mark gradient and the brand glow, with `icon/zap` at 26px centred; the
/// wordmark is "Moneta" in `heading/h1`. Every piece already existed, so
/// `pubspec.yaml` is untouched — and a native drawing stays inside
/// `check_design_tokens.dart`, which cannot see into an SVG.
class MonetaLogo extends StatelessWidget {
  /// Creates a logo.
  const MonetaLogo({
    this.showWordmark = true,
    this.markSize = defaultMarkSize,
    super.key,
  });

  /// Whether the "Moneta" wordmark is drawn beside the mark.
  final bool showWordmark;

  /// Edge length of the square mark.
  final double markSize;

  /// The size Figma authors, from `70:206`.
  static const double defaultMarkSize = 48;

  /// The glyph's share of the mark's edge, from `70:207` — 26 of 48.
  static const double glyphRatio = 26 / defaultMarkSize;

  /// The product name, as the wordmark and as the accessible label.
  static const String wordmark = 'Moneta';

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Semantics(
      container: true,
      label: wordmark,
      // The wordmark Text and the glyph would each contribute their own node,
      // announcing "Moneta" twice and the glyph besides. One label for the
      // whole logo.
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: markSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: MonetaColors.markGradient,
                borderRadius: theme.radii.borderMd,
                boxShadow: theme.elevation.brandGlow,
              ),
              child: Center(
                child: MonetaIcon(
                  MonetaIconName.zap,
                  size: markSize * glyphRatio,
                  color: theme.colors.textOnBrand,
                ),
              ),
            ),
          ),
          if (showWordmark) ...[
            const SizedBox(width: MonetaSpacing.spaceMd),
            Text(
              wordmark,
              style: theme.text.headingH1.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
