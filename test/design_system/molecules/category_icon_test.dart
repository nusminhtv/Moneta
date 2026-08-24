import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/theme/category_colors.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpDisc(
    WidgetTester tester,
    SpendCategory category, {
    CategoryIconSize size = CategoryIconSize.md,
  }) {
    return pumpMonetaWidget(
      tester,
      CategoryIcon(category: category, size: size),
    );
  }

  BoxDecoration disc(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(CategoryIcon),
        matching: find.byType(DecoratedBox),
      ),
    );
    return box.decoration as BoxDecoration;
  }

  MonetaIcon glyph(WidgetTester tester) =>
      tester.widget<MonetaIcon>(find.byType(MonetaIcon));

  group('category binding', () {
    testWidgets('every category renders its own tint and glyph', (
      tester,
    ) async {
      for (final category in SpendCategory.values) {
        await pumpDisc(tester, category);
        expect(
          disc(tester).color,
          colors.categorySubtle(category),
          reason: '${category.name} tint',
        );
        expect(
          glyph(tester).color,
          colors.categoryBase(category),
          reason: '${category.name} glyph colour',
        );
        expect(
          glyph(tester).icon.figmaName,
          category.iconName,
          reason: '${category.name} glyph',
        );
      }
    });

    testWidgets('no two categories look the same', (tester) async {
      final tints = <Color>{};
      final glyphs = <MonetaIconName>{};
      for (final category in SpendCategory.values) {
        await pumpDisc(tester, category);
        tints.add(disc(tester).color!);
        glyphs.add(glyph(tester).icon);
      }
      expect(tints, hasLength(SpendCategory.values.length));
      expect(glyphs, hasLength(SpendCategory.values.length));
    });

    testWidgets('the disc is a circle, not a rounded square', (tester) async {
      await pumpDisc(tester, SpendCategory.food);
      expect(disc(tester).shape, BoxShape.circle);
    });
  });

  group('sizes', () {
    testWidgets('match the Figma disc and glyph pairs', (tester) async {
      const expected = {
        CategoryIconSize.sm: (32.0, 16.0),
        CategoryIconSize.md: (40.0, 20.0),
        CategoryIconSize.lg: (48.0, 24.0),
      };
      for (final entry in expected.entries) {
        await pumpDisc(tester, SpendCategory.food, size: entry.key);
        expect(
          tester.getSize(find.byType(CategoryIcon)),
          Size.square(entry.value.$1),
          reason: '${entry.key.name} disc',
        );
        expect(
          glyph(tester).size,
          entry.value.$2,
          reason: '${entry.key.name} glyph',
        );
      }
    });

    testWidgets('md is the default', (tester) async {
      await pumpMonetaWidget(
        tester,
        const CategoryIcon(category: SpendCategory.bills),
      );
      expect(tester.getSize(find.byType(CategoryIcon)), const Size.square(40));
    });

    testWidgets('a category looks identical across sizes apart from geometry', (
      tester,
    ) async {
      final tints = <Color>{};
      final glyphs = <MonetaIconName>{};
      for (final size in CategoryIconSize.values) {
        await pumpDisc(tester, SpendCategory.transport, size: size);
        tints.add(disc(tester).color!);
        glyphs.add(glyph(tester).icon);
      }
      expect(tints, hasLength(1));
      expect(glyphs, hasLength(1));
    });
  });

  group('icon set integrity', () {
    test('every category names an icon that exists in the set', () {
      for (final category in SpendCategory.values) {
        expect(
          MonetaIconName.tryParse(category.iconName),
          isNotNull,
          reason: '${category.name} names a missing icon',
        );
      }
    });
  });

  group('accessibility', () {
    testWidgets('announces the category by default', (tester) async {
      await pumpDisc(tester, SpendCategory.entertainment);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Entertainment'), findsOneWidget);
    });

    testWidgets('stays silent when the name is already on screen', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const CategoryIcon(
          category: SpendCategory.entertainment,
          showLabelForAccessibility: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Entertainment'), findsNothing);
    });
  });
}
