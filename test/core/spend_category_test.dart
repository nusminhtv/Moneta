import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/spend_category.dart';

void main() {
  group('chart slots', () {
    test('every category maps to a distinct slot', () {
      final slots = SpendCategory.values.map((c) => c.chartSlot).toList();
      expect(slots.toSet(), hasLength(SpendCategory.values.length));
    });

    test('slots stay inside the eight-slot palette', () {
      for (final category in SpendCategory.values) {
        expect(
          category.chartSlot,
          inInclusiveRange(1, 8),
          reason: '${category.name} slot out of range',
        );
      }
    });

    test('the eight categories fill all eight slots exactly', () {
      expect(SpendCategory.values, hasLength(8));
      expect(
        SpendCategory.values.map((c) => c.chartSlot).toSet(),
        {1, 2, 3, 4, 5, 6, 7, 8},
      );
    });

    test('slots match the Figma CategoryIcon bindings', () {
      // From node 33:311 — changing one of these silently recolours a category
      // everywhere it appears.
      expect(SpendCategory.salary.chartSlot, 1);
      expect(SpendCategory.shopping.chartSlot, 2);
      expect(SpendCategory.health.chartSlot, 3);
      expect(SpendCategory.transport.chartSlot, 4);
      expect(SpendCategory.gift.chartSlot, 5);
      expect(SpendCategory.entertainment.chartSlot, 6);
      expect(SpendCategory.food.chartSlot, 7);
      expect(SpendCategory.bills.chartSlot, 8);
    });
  });

  group('icons and labels', () {
    test('every category names an icon and a label', () {
      for (final category in SpendCategory.values) {
        expect(category.iconName, isNotEmpty);
        expect(category.label, isNotEmpty);
      }
    });

    test('icon names carry no icon/ prefix', () {
      for (final category in SpendCategory.values) {
        expect(category.iconName, isNot(startsWith('icon/')));
      }
    });

    test('every category uses its own icon', () {
      final icons = SpendCategory.values.map((c) => c.iconName).toSet();
      expect(icons, hasLength(SpendCategory.values.length));
    });
  });

  group('income classification', () {
    test('salary is income', () {
      expect(SpendCategory.salary.isIncome, isTrue);
    });

    test('spending categories are not income', () {
      for (final category in [
        SpendCategory.food,
        SpendCategory.transport,
        SpendCategory.shopping,
        SpendCategory.bills,
        SpendCategory.health,
        SpendCategory.entertainment,
      ]) {
        expect(category.isIncome, isFalse, reason: category.name);
      }
    });

    test('gift is not classified as income', () {
      // A gift can go either way; direction belongs to the transaction.
      expect(SpendCategory.gift.isIncome, isFalse);
    });
  });

  group('tryParse', () {
    test('round-trips every category name', () {
      for (final category in SpendCategory.values) {
        expect(SpendCategory.tryParse(category.name), category);
      }
    });

    test('returns null for an unknown name instead of guessing', () {
      expect(SpendCategory.tryParse('crypto'), isNull);
      expect(SpendCategory.tryParse(''), isNull);
      expect(SpendCategory.tryParse('Food'), isNull, reason: 'case-sensitive');
    });
  });
}
