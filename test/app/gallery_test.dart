import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/onboarding/domain/onboarding_slide.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

/// The gallery's builders take a `BuildContext` and none of them reads it, so a
/// throwaway element is enough to invoke them outside a pump. If a builder ever
/// starts reading the context this cast fails loudly rather than silently
/// returning something else.
late BuildContext _dummyContext;

void main() {
  setUpAll(() {
    _dummyContext = _NullContext();
  });

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

    test('Button covers the full 5 x 3 x 3 matrix', () {
      // Derived from the enums, like the six pre-existing sections. Trimming the
      // Button section from 45 variants to 2 passed the whole gallery suite —
      // the completeness scan checks presence, not variants, so the requirement
      // "every component in every variant" needed this per-section check that
      // gallery_catalog.dart's own comment already claimed existed.
      final button = galleryCatalog.firstWhere((s) => s.component == 'Button');
      expect(
        button.variants,
        hasLength(
          MonetaButtonStyle.values.length *
              MonetaButtonSize.values.length *
              MonetaButtonState.values.length,
        ),
      );
      expect(button.variants, hasLength(45));
    });

    test('PaginationDots covers every active position', () {
      final dots = galleryCatalog.firstWhere(
        (s) => s.component == 'PaginationDots',
      );
      expect(dots.variants, hasLength(3));
    });

    test('OnboardingIllustration covers one variant per slide', () {
      final illustration = galleryCatalog.firstWhere(
        (s) => s.component == 'OnboardingIllustration',
      );
      expect(illustration.variants, hasLength(OnboardingSlide.values.length));
    });

    test('TransactionRow covers both implemented directions', () {
      // Two, not the four Figma 29:70 authors. Transfer and Pending have no
      // domain concept yet; recorded in figma-map.md rather than faked here.
      final row = galleryCatalog.firstWhere(
        (s) => s.component == 'TransactionRow',
      );
      expect(row.variants, hasLength(TransactionDirection.values.length));
      expect(row.variants, hasLength(2));
    });

    test('each Button variant builds the button its label describes', () {
      // Counting 45 is not the same as rendering 45 different things. Pointing
      // every variant at the same primary/md/normal button, labels untouched,
      // passed the whole gallery suite — which is precisely the defect the
      // gallery exists to make visible.
      final button = galleryCatalog.firstWhere((s) => s.component == 'Button');
      final seen = <(MonetaButtonStyle, MonetaButtonSize, MonetaButtonState)>{};

      for (final variant in button.variants) {
        final built = variant.build(_dummyContext) as MonetaButton;
        expect(
          variant.label,
          'Style=${built.style.name}, Size=${built.size.name}, '
          'State=${built.state.name}',
          reason: 'label and widget disagree',
        );
        seen.add((built.style, built.size, built.state));
      }
      expect(seen, hasLength(45), reason: 'variants are not all distinct');
    });

    test('each PaginationDots variant builds its own position', () {
      final dots = galleryCatalog.firstWhere(
        (s) => s.component == 'PaginationDots',
      );
      final positions = dots.variants
          .map(
            (v) => (v.build(_dummyContext) as MonetaPaginationDots).activeIndex,
          )
          .toList();
      expect(positions, [0, 1, 2]);
    });

    test('each OnboardingIllustration variant builds its own slide', () {
      final section = galleryCatalog.firstWhere(
        (s) => s.component == 'OnboardingIllustration',
      );
      final built = section.variants
          .map((v) => v.build(_dummyContext) as OnboardingIllustration)
          .toList();
      expect(
        built.map((i) => i.chartSlot),
        OnboardingSlide.values.map((s) => s.chartSlot),
      );
      expect(
        built.map((i) => i.glyph),
        OnboardingSlide.values.map((s) => s.glyph),
      );
    });

    test('each TransactionRow variant builds its own direction', () {
      final section = galleryCatalog.firstWhere(
        (s) => s.component == 'TransactionRow',
      );
      final directions = section.variants
          .map((v) => (v.build(_dummyContext) as TransactionRow).direction)
          .toSet();
      expect(directions, TransactionDirection.values.toSet());
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
        // Recursive: the first version of this used a non-recursive listSync,
        // so a widget in a subdirectory was invisible to it.
        final directory = Directory('lib/design_system/$dir');
        for (final file
            in directory.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          // `[\s\S]*?` spans the newline `dart format` inserts before a long
          // `extends` clause, and the optional generic parameter list keeps a
          // `class Foo<T> extends StatelessWidget` from slipping past. Both
          // evaded the first version, verified by probe.
          // The class modifiers matter: `final class` is this repo's house
          // style (MonetaColors, PreferencesStore, MonetaRadii…), and a
          // `^class`-anchored regex misses every one of them. `final` and
          // `base` both slipped past the previous version.
          for (final match in RegExp(
            r'^(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
            r'class (\w+)(?:<[^>]*>)?[\s\S]{0,80}?extends\s+\w*(?:Widget|State)\b',
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

/// Minimal stand-in: every member throws, so any builder that actually reads the
/// context fails the test instead of quietly working.
class _NullContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('a gallery builder read its BuildContext');
}
