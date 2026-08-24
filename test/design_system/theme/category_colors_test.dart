import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/theme/category_colors.dart';
import 'package:moneta/design_system/tokens/colors.dart';

void main() {
  const colors = MonetaColors.dark();

  test('every category resolves to its Figma slot colours', () {
    for (final category in SpendCategory.values) {
      expect(
        colors.categoryBase(category),
        colors.chart.base(category.chartSlot),
        reason: category.name,
      );
      expect(
        colors.categorySubtle(category),
        colors.chart.subtle(category.chartSlot),
        reason: category.name,
      );
    }
  });

  test('no two categories share a base colour', () {
    final used = SpendCategory.values.map(colors.categoryBase).toSet();
    expect(used, hasLength(SpendCategory.values.length));
  });

  test('the observed Figma pairings hold end to end', () {
    // Spot-checks read directly off node 33:311.
    expect(colors.categoryBase(SpendCategory.food).toARGB32(), 0xFFAA7705);
    expect(colors.categorySubtle(SpendCategory.food).toARGB32(), 0xFF201909);
    expect(colors.categoryBase(SpendCategory.transport).toARGB32(), 0xFF027ED8);
    expect(colors.categorySubtle(SpendCategory.bills).toARGB32(), 0xFF071F21);
  });
}
