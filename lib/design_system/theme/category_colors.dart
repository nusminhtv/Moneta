import 'package:flutter/painting.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// Resolves a [SpendCategory] to its chart-palette colours.
///
/// This is the seam that keeps `lib/core` Flutter-free: the category carries a
/// slot index, and only the design system knows what colour a slot is.
extension CategoryColors on MonetaColors {
  /// Glyph and mark colour for [category].
  Color categoryBase(SpendCategory category) => chart.base(category.chartSlot);

  /// Background tint for [category].
  Color categorySubtle(SpendCategory category) =>
      chart.subtle(category.chartSlot);
}
