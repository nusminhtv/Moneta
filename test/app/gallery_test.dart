import 'dart:io';

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
    });

    test('every design-system widget is in the catalog', () {
      // This used to assert a hardcoded list of six names, which meant the
      // requirement "the gallery renders every component in every variant"
      // could not be violated in a way the gate could see: Button (45
      // variants), PaginationDots and OnboardingIllustration were all missing
      // and this test passed. It now reads the source tree, so a new
      // design-system widget fails here until it is added.
      //
      // A plain test(), not testWidgets: file I/O inside a FakeAsync zone never
      // completes and would hang instead of failing. See CLAUDE.md.
      final declared = <String, String>{};
      for (final dir in ['atoms', 'molecules', 'organisms']) {
        final directory = Directory('lib/design_system/$dir');
        for (final file in directory.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          for (final match in RegExp(
            r'^class (\w+) extends (?:StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)',
            multiLine: true,
          ).allMatches(file.readAsStringSync())) {
            final name = match.group(1)!;
            if (name.startsWith('_')) continue;
            declared[name] = file.path;
          }
        }
      }

      expect(
        declared,
        isNotEmpty,
        reason: 'found no design-system widgets — the scan itself is broken',
      );

      // Two documented exceptions, each with a reason rather than a shrug:
      //
      // AmountSlot is a layout constraint, not a Figma component — it renders
      // nothing of its own and has no node. Putting it in the gallery would show
      // an empty box.
      //
      // MonetaIcon is covered by the catalog's `Icons` section, which renders
      // the whole set rather than one glyph at a time.
      const exempt = {'AmountSlot'};
      const aliases = {'MonetaIcon': 'Icons'};
      declared.removeWhere((name, _) => exempt.contains(name));

      // The catalog names components as Figma does, which drops the Moneta
      // prefix the Dart classes carry.
      final covered = galleryCatalog
          .map((s) => s.component.toLowerCase())
          .toSet();
      final missing = <String>[];
      for (final entry in declared.entries) {
        final bare = entry.key
            .replaceFirst(RegExp('^Moneta'), '')
            .toLowerCase();
        final alias = aliases[entry.key]?.toLowerCase();
        final present = covered.any(
          (c) => c == bare || c == entry.key.toLowerCase() || c == alias,
        );
        if (!present) missing.add('${entry.key} (${entry.value})');
      }

      expect(
        missing,
        isEmpty,
        reason:
            'these design-system widgets are not in the gallery, which a '
            'requirement says renders every component:\n  ${missing.join('\n  ')}',
      );
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

      // Asserted against the catalog's own first section rather than a
      // hardcoded 'BalanceCard' — that pin broke as soon as a component was
      // added ahead of it, which is a reordering, not a regression.
      final first = galleryCatalog.first;
      expect(find.text('Design system'), findsOneWidget);
      expect(find.text(first.component), findsOneWidget);
      expect(find.text(first.variants.first.label), findsOneWidget);
      expect(
        find.text(
          'Figma ${first.figmaNodeId} · ${first.variants.length} variants',
        ),
        findsOneWidget,
      );
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
