import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Renders one icon from the Figma set.
///
/// Size and colour come from tokens. Colour defaults to the primary text colour,
/// which is what the exported assets are already drawn in, so an untinted icon
/// and a default-tinted icon look identical — a caller cannot accidentally get a
/// stray colour by forgetting the parameter.
class MonetaIcon extends StatelessWidget {
  /// Creates an icon.
  const MonetaIcon(
    this.icon, {
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  /// Which icon to draw.
  final MonetaIconName icon;

  /// Edge length in logical pixels. Defaults to the design's 24.
  final double? size;

  /// Tint. Ignored for icons whose [MonetaIconName.preservesColour] is true.
  final Color? color;

  /// Accessibility label. Pass null for a purely decorative icon.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? MonetaLayout.iconSize;
    final tint = icon.preservesColour
        ? null
        : ColorFilter.mode(
            color ?? context.moneta.colors.textPrimary,
            BlendMode.srcIn,
          );

    return SvgPicture.asset(
      icon.assetPath,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: tint,
      semanticsLabel: semanticLabel,
      // A missing asset must be loud. The default placeholder is an empty box,
      // which reads as a spacing bug rather than a missing file.
      placeholderBuilder: (_) => SizedBox.square(dimension: resolvedSize),
    );
  }
}
