import 'package:flutter/widgets.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/category_colors.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Size variants from Figma node `33:311`.
enum CategoryIconSize {
  /// 32px disc, 16px glyph — list rows.
  sm(32, 16),

  /// 40px disc, 20px glyph — cards.
  md(40, 20),

  /// 48px disc, 24px glyph — detail headers.
  lg(48, 24);

  const CategoryIconSize(this.diameter, this.glyphSize);

  /// Outer disc diameter.
  final double diameter;

  /// Inner glyph edge length.
  final double glyphSize;
}

/// A category's disc: its tint and its glyph, bound together.
///
/// The API takes a [SpendCategory] and nothing else about appearance. Figma:
/// *"Colour and glyph are baked in together — pick a category, never a colour.
/// This is what keeps a category identical across lists, charts and detail
/// screens."*
class CategoryIcon extends StatelessWidget {
  /// Creates a category disc.
  const CategoryIcon({
    required this.category,
    this.size = CategoryIconSize.md,
    this.showLabelForAccessibility = true,
    super.key,
  });

  /// Which category to draw.
  final SpendCategory category;

  /// Disc size.
  final CategoryIconSize size;

  /// Whether to expose the category name to assistive technology.
  ///
  /// Set false when the category name is already rendered as adjacent text, so
  /// a screen reader does not announce it twice.
  final bool showLabelForAccessibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;
    final iconName = MonetaIconName.tryParse(category.iconName);
    assert(
      iconName != null,
      'SpendCategory.${category.name} names icon "${category.iconName}", '
      'which is not in the Figma icon set',
    );

    return SizedBox.square(
      dimension: size.diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.categorySubtle(category),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: iconName == null
              ? const SizedBox.shrink()
              : MonetaIcon(
                  iconName,
                  size: size.glyphSize,
                  color: colors.categoryBase(category),
                  semanticLabel: showLabelForAccessibility
                      ? category.label
                      : null,
                ),
        ),
      ),
    );
  }
}
