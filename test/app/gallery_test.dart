import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

void main() {
  GallerySection sectionFor(String component) =>
      galleryCatalog.firstWhere((s) => s.component == component);

  group('coverage', () {
    // These are the assertions that make the gallery a contract rather than a
    // demo: each count is checked against the enum that defines the variants, so
    // adding a variant to a component without adding it here fails the gate.
    test('BalanceCard has both Figma states', () {
      expect(
        sectionFor('BalanceCard').variants.map((v) => v.label),
        ['State=Default', 'State=Masked'],
      );
    });

    test('BudgetCard has all three Figma states', () {
      expect(
        sectionFor('BudgetCard').variants.map((v) => v.label),
        ['State=OnTrack', 'State=NearLimit', 'State=Over'],
      );
    });

    test('BottomNav has one entry per destination', () {
      final section = sectionFor('BottomNav');
      expect(section.variants, hasLength(MonetaDestination.values.length));
      for (final destination in MonetaDestination.values) {
        expect(
          section.variants.map((v) => v.label),
          contains('Active=${destination.label}'),
        );
      }
    });

    test('ProgressBar covers every state and size', () {
      final section = sectionFor('ProgressBar');
      expect(
        section.variants,
        hasLength(3 * MonetaProgressBarSize.values.length),
      );
    });

    test('CategoryIcon covers every category and size', () {
      final section = sectionFor('CategoryIcon');
      expect(
        section.variants,
        hasLength(SpendCategory.values.length * CategoryIconSize.values.length),
      );
      for (final category in SpendCategory.values) {
        expect(
          section.variants.where((v) => v.label.contains(category.name)),
          hasLength(CategoryIconSize.values.length),
          reason: category.name,
        );
      }
    });

    test('Icons covers the whole set', () {
      expect(
        sectionFor('Icons').variants,
        hasLength(MonetaIconName.values.length),
      );
    });

    test('every section names its Figma node', () {
      for (final section in galleryCatalog) {
        expect(
          section.figmaNodeId,
          matches(RegExp(r'^\d+:\d+$')),
          reason: section.component,
        );
      }
    });

    test('every variant label is unique within its section', () {
      for (final section in galleryCatalog) {
        final labels = section.variants.map((v) => v.label).toSet();
        expect(
          labels,
          hasLength(section.variants.length),
          reason: '${section.component} has duplicate variant labels',
        );
      }
    });

    test('every implemented component appears exactly once', () {
      final components = galleryCatalog.map((s) => s.component).toList();
      expect(components.toSet(), hasLength(components.length));
      expect(components, [
        'BalanceCard',
        'BudgetCard',
        'BottomNav',
        'ProgressBar',
        'CategoryIcon',
        'Icons',
      ]);
    });
  });

  group('rendering', () {
    testWidgets('the screen builds and shows the first section', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const GalleryScreen(),
        ),
      );

      expect(find.text('Design system'), findsOneWidget);
      expect(find.text('BalanceCard'), findsOneWidget);
      expect(find.text('State=Default'), findsOneWidget);
      expect(find.text('Figma 40:161 · 2 variants'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every variant builds without throwing', (tester) async {
      // A lazy ListView never builds the offscreen sections, so each variant is
      // pumped on its own. This is the test that would catch a fixture that
      // violates an assert — e.g. a chart slot out of range.
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final section in galleryCatalog) {
        for (final variant in section.variants) {
          await tester.pumpWidget(
            MaterialApp(
              theme: MonetaTheme.dark().toThemeData(),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 353,
                    child: Builder(builder: variant.build),
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${section.component} / ${variant.label}',
          );
        }
      }
    });
  });
}
