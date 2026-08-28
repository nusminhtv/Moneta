import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Which way a [MonetaDivider] runs, from Figma node `21:126`.
enum MonetaDividerOrientation {
  /// A hairline across the available width.
  horizontal,

  /// A hairline down the available height.
  vertical,
}

/// How visible a [MonetaDivider] is, from Figma node `21:126`.
enum MonetaDividerTone {
  /// The quieter rule, between rows of the same group.
  subtle,

  /// The stronger rule, between groups.
  standard,
}

/// A one-pixel rule.
///
/// From Figma node `21:126` — 2 orientations × 2 tones, all four implemented.
class MonetaDivider extends StatelessWidget {
  /// Creates a divider.
  const MonetaDivider({
    this.orientation = MonetaDividerOrientation.horizontal,
    this.tone = MonetaDividerTone.subtle,
    super.key,
  });

  /// Which way it runs.
  final MonetaDividerOrientation orientation;

  /// How visible it is.
  final MonetaDividerTone tone;

  /// The length a divider takes when its parent gives it no bound.
  ///
  /// Without this, a horizontal divider inside an unbounded `Row` throws a
  /// layout error rather than rendering.
  static const double intrinsicLength = 240;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;
    final color = switch (tone) {
      MonetaDividerTone.subtle => colors.borderSubtle,
      MonetaDividerTone.standard => colors.borderDefault,
    };
    final horizontal = orientation == MonetaDividerOrientation.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        // A hairline is one logical pixel on the cross axis and fills the main
        // axis — unless the parent leaves that axis unbounded, in which case it
        // falls back to its authored length instead of throwing.
        final width = horizontal
            ? (constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : intrinsicLength)
            : MonetaLayout.borderWidthHairline;
        final height = horizontal
            ? MonetaLayout.borderWidthHairline
            : (constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : intrinsicLength);

        return ColoredBox(
          color: color,
          child: SizedBox(width: width, height: height),
        );
      },
    );
  }
}
