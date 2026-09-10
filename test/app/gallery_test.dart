import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/onboarding/domain/onboarding_slide.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

import 'gallery_describe_auth.dart';
import 'gallery_describe_budgets.dart';
import 'gallery_describe_home.dart';
import 'gallery_describe_insights.dart';

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

    // ONE check over EVERY section, rather than a hand-written check per
    // component. Four review rounds went the same way: I asserted the case I had
    // just seen break and recorded the requirement as covered. Button's variants
    // were checked and the other nine sections' were not — so BudgetCard's three
    // states, all 24 CategoryIcon variants and every Icons variant could build
    // the same widget with the suite green. Enumerating sections by hand is the
    // defect; this is exhaustive by construction, so a new section is covered the
    // moment it is added.
    test('no two variants of a component build the same widget', () {
      final offenders = <String>[];
      for (final section in galleryCatalog) {
        final byDescription = <String, List<String>>{};
        for (final variant in section.variants) {
          final built = variant.build(_dummyContext);
          (byDescription[_describe(built)] ??= []).add(variant.label);
        }
        for (final entry in byDescription.entries) {
          if (entry.value.length > 1) {
            offenders.add(
              '${section.component}: ${entry.value.join(" / ")} '
              'all build ${entry.key}',
            );
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'these variants are labelled differently and render identically, '
            'which is the one thing a gallery exists to expose:\n  '
            '${offenders.join("\n  ")}',
      );
    });

    test('every variant label parses into checkable claims', () {
      // Fail closed. The previous version did `if (parts.length != 2) continue`,
      // so a label with no `=` was silently unverified — which is every one of
      // the ~50 Icons variants, the largest section in the gallery. Permuting
      // all of them by one passed the whole gate: every icon rendered under the
      // wrong name.
      //
      // A label must therefore be in Figma's `Key=Value` variant syntax, or in
      // the `group/name` form the icon set uses. Anything else fails here rather
      // than passing unchecked.
      final unparseable = <String>[];
      for (final section in galleryCatalog) {
        for (final variant in section.variants) {
          if (_claimsIn(variant.label).isEmpty) {
            unparseable.add('${section.component}: "${variant.label}"');
          }
        }
      }
      expect(
        unparseable,
        isEmpty,
        reason:
            'these labels carry no checkable claim, so nothing verifies that '
            'they describe what they build:\n  ${unparseable.join("\n  ")}',
      );
    });

    test('a label that names a property matches the widget it builds', () {
      // Every claim in the label, not the first word of each value. Taking only
      // the first word meant `Slot=4 (accounts)` checked `4` and never
      // `accounts`, so the three illustration glyphs could be rotated among the
      // three variants with the suite green.
      final mismatches = <String>[];
      for (final section in galleryCatalog) {
        for (final variant in section.variants) {
          final described = _describe(
            variant.build(_dummyContext),
          ).toLowerCase();
          for (final claim in _claimsIn(variant.label)) {
            if (!described.contains(claim)) {
              mismatches.add(
                '${section.component} "${variant.label}" claims "$claim", '
                'builds $described',
              );
            }
          }
        }
      }
      expect(
        mismatches,
        isEmpty,
        reason: 'label and widget disagree:\n  ${mismatches.join("\n  ")}',
      );
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
      // The whole of lib/design_system, walked from the filesystem. Naming
      // atoms/molecules/organisms by hand meant a widget in a fourth directory
      // was invisible — `lib/design_system/cells/` passed the entire gate. Every
      // round of this check has been defeated by whatever it enumerated by hand,
      // so it enumerates nothing: `tokens` and `theme` are excluded by name
      // because they hold no widgets, and that exclusion is itself asserted
      // below.
      const nonWidgetDirs = {'tokens', 'theme'};
      final declared = <String, String>{};
      final root = Directory('lib/design_system');

      // Every .dart file under lib/design_system, including ones at its root.
      // The previous version iterated top-level *directories* only, so
      // `lib/design_system/rogue.dart` was invisible — the fifth hand-drawn
      // boundary in this one test to be walked past.
      final files = <File>[
        ...root.listSync().whereType<File>(),
        for (final entity in root.listSync().whereType<Directory>())
          if (!nonWidgetDirs.contains(
            entity.path.split(Platform.pathSeparator).last,
          ))
            ...entity.listSync(recursive: true).whereType<File>(),
      ];
      {
        for (final file in files) {
          if (!file.path.endsWith('.dart')) continue;
          // `[\s\S]*?` spans the newline `dart format` inserts before a long
          // `extends` clause, and the optional generic parameter list keeps a
          // `class Foo<T> extends StatelessWidget` from slipping past. Both
          // evaded the first version, verified by probe.
          // Matches EVERY class declaration, not classes whose superclass
          // looks like a widget. Four rounds of widening a superclass pattern
          // went the same way each time: `^class` missed modifiers, then
          // `\w*Widget|State` missed `extends MonetaPaginationDots`. A widget
          // can extend anything, so the pattern can always be walked past.
          //
          // Everything found must be either in the gallery or in `exempt` below
          // with a reason. That is exhaustive by construction: a new class in
          // these directories fails until someone decides which it is.
          for (final match in RegExp(
            r'^(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
            r'class (\w+)',
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
      // The excluded directories must be widget-FREE, not merely present.
      // Asserting existence proved nothing: a widget class in `tokens/` passed
      // the whole gate.
      final widgetsInExcluded = <String>[];
      for (final dir in nonWidgetDirs) {
        final directory = Directory('lib/design_system/$dir');
        expect(
          directory.existsSync(),
          isTrue,
          reason: 'excluded directory $dir is gone — re-check the list',
        );
        for (final file
            in directory.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          if (RegExp(
            r'extends\s+\w*(?:StatelessWidget|StatefulWidget|ConsumerWidget)',
          ).hasMatch(file.readAsStringSync())) {
            widgetsInExcluded.add(file.path);
          }
        }
      }
      expect(
        widgetsInExcluded,
        isEmpty,
        reason:
            'these files sit in a directory excluded as widget-free and declare '
            'widgets: ${widgetsInExcluded.join(', ')}',
      );
      // One exemption, and it must be live. The previous set had ten entries of
      // which nine matched nothing the scan can find — eight `enum`s, which a
      // class-only regex can never match, and one class that does not exist in
      // `lib/` at all. It read as a list of considered decisions and was one
      // decision plus noise, and a dead entry is exactly how a future exemption
      // could silently mask a real widget.
      //
      // AmountSlot is a layout constraint, not a Figma component: a bare
      // ConstrainedBox with no node, which is the spec's own "renders nothing of
      // its own". MonetaIcon is aliased, not exempted — the catalog's `Icons`
      // section renders the whole set.
      //
      // ChartSeries is a value type — a label, a `Money` and a chart slot — and
      // renders nothing at all. It sits beside the charts that consume it
      // because it references `ChartSlot`, which is a design-system concept;
      // `lib/core` may import nothing but `core`, so it cannot live there. The
      // slots it names ARE in the gallery, as ChartLegendItem's nine variants.
      //
      // MonetaRadioOption is the same: a value, a title and a supporting line,
      // with no render of its own. What renders it — RadioRow and RadioGroup —
      // is in the gallery, and RadioGroup's variants are built from options,
      // so an option that stopped working would fail there.
      //
      // LineSeries is the same shape as ChartSeries: a label and a list of
      // `Money`, rendering nothing. What renders it — LineChart — is in the
      // gallery at four point counts.
      const exempt = <String>{
        'AmountSlot',
        'ChartSeries',
        'MonetaRadioOption',
        'LineSeries',
      };
      final deadExemptions = exempt.difference(declared.keys.toSet());
      expect(
        deadExemptions,
        isEmpty,
        reason:
            'these exemptions match nothing the scan found, so they exempt '
            'nothing: ${deadExemptions.join(', ')}',
      );
      declared.removeWhere((name, _) => exempt.contains(name));

      const aliases = {'MonetaIcon': 'Icons'};

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
        // `bare` alone let a new `MonetaTransactionRow` in atoms/ collide with
        // the existing `TransactionRow` section and count itself covered. A
        // stripped name only counts when no other declared class claims it.
        final claimedByAnother = declared.keys
            .where((k) => k != entry.key)
            .any(
              (k) =>
                  k.replaceFirst(RegExp('^Moneta'), '').toLowerCase() == bare,
            );
        final present =
            covered.contains(entry.key.toLowerCase()) ||
            covered.contains(alias) ||
            (covered.contains(bare) && !claimedByAnother);
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

    testWidgets('a small component is not stretched to the content width', (
      tester,
    ) async {
      // Renders the gallery's OWN frame, not one this test builds. The first
      // version of this test hand-rolled an Align + ConstrainedBox and asserted
      // that — so reverting the gallery to its fixed-width SizedBox left it
      // green. It asserted its own fix, which is the self-referential trap this
      // repo keeps falling into.
      await tester.binding.setSurfaceSize(const Size(420, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const Scaffold(
            body: GalleryVariantFrame(
              child: MonetaIconButton(
                icon: MonetaIconName.search,
                semanticLabel: 'Search',
                style: MonetaIconButtonStyle.filled,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(MonetaIconButton)).width,
        MonetaIconButtonSize.md.box,
        reason: 'the gallery frame stretched a fixed-size component',
      );
    });

    testWidgets('a full-width component still fills the content width', (
      tester,
    ) async {
      // The other direction: the frame must not shrink-wrap something that is
      // meant to span. Without this, "stop stretching" could be satisfied by a
      // frame that starves every card of width.
      await tester.binding.setSurfaceSize(const Size(420, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const Scaffold(
            body: GalleryVariantFrame(
              child: SizedBox(width: double.infinity, height: 40),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(SizedBox).first).width,
        MonetaLayout.contentWidth,
      );
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

  group('StatTile and AmountInput are registered in full', () {
    test('all three directions of 35:137 and both states of 36:76', () {
      final tile = galleryCatalog.singleWhere((s) => s.component == 'StatTile');
      expect(tile.figmaNodeId, '35:137');
      expect(tile.variants, hasLength(3));

      final input = galleryCatalog.singleWhere(
        (s) => s.component == 'AmountInput',
      );
      expect(input.figmaNodeId, '36:76');
      expect(input.variants, hasLength(2));
    });
  });

  group('SegmentedItem is registered in full', () {
    test('both variants of 36:167 are present', () {
      final section = galleryCatalog.singleWhere(
        (s) => s.component == 'SegmentedItem',
      );
      expect(section.figmaNodeId, '36:167');
      expect(section.variants, hasLength(2));
    });
  });

  group('CircularProgress is registered in full', () {
    test('all nine variants of 25:272 are present', () {
      // 3 states x 3 sizes. The generic checks above catch a duplicate or a
      // missing component but never a shortfall, so this count is the only
      // thing standing between the gallery and a component registered with the
      // one variant the first screen happened to need.
      final section = galleryCatalog.singleWhere(
        (s) => s.component == 'CircularProgress',
      );
      expect(section.figmaNodeId, '25:272');
      expect(section.variants, hasLength(9));
      expect(
        section.variants.map((v) => v.label).toSet(),
        hasLength(9),
        reason: 'two variants share a label, so one of the nine is missing',
      );
    });
  });

  group('ChartLegendItem is registered in full', () {
    test('all nine slots of 47:47 are present, named as Figma names them', () {
      final section = galleryCatalog.singleWhere(
        (s) => s.component == 'ChartLegendItem',
      );
      expect(section.figmaNodeId, '47:47');
      // Nine: `Slot=1`-`Slot=8` plus `Slot=Other`. Asserted against the enum
      // rather than against the literal 9, so adding a palette slot fails here
      // instead of quietly shipping a legend that cannot name it.
      expect(section.variants, hasLength(ChartSlot.values.length));
      expect(
        section.variants.map((v) => v.label),
        ChartSlot.values.map((slot) => slot.figmaName),
        reason: 'the labels are Figma variant names, in Figma order',
      );
      expect(
        section.variants.map((v) => v.label),
        contains('Slot=Other'),
        reason: 'the neutral fold is an authored variant, not an absence',
      );
    });
  });

  group('DonutChart is registered in full', () {
    test('the cap, the fold and both degenerate cases are all rendered', () {
      final section = galleryCatalog.singleWhere(
        (s) => s.component == 'DonutChart',
      );
      expect(section.figmaNodeId, '47:48');
      // `47:48` is a single variant, so a count of one would satisfy Figma and
      // show a reviewer nothing. The four here are the cases that can differ
      // visually: the authored eight, nine folding into Other, one segment
      // filling the ring, and none at all.
      expect(
        section.variants.map((v) => v.label),
        [
          'Categories=8, Fold=None',
          'Categories=9, Fold=Other',
          'Categories=1, Fold=None',
          'Categories=0, Fold=None',
        ],
      );
      final folded = section.variants.where(
        (v) => v.label.contains('Fold=Other'),
      );
      expect(
        folded,
        hasLength(1),
        reason:
            'the eight-segment cap is only visible in the folded variant, '
            'so removing it would leave the cap unreviewable',
      );
    });
  });

  group('LineChart is registered in full', () {
    test('four point counts, so the zero baseline is reviewable', () {
      final section = sectionFor('LineChart');
      expect(section.figmaNodeId, '48:76');
      // `48:76` is one authored variant, and one fixture would show nothing
      // about the requirement that matters: the axis starts at zero even when
      // the data does not. `Max=35` is the narrow-band case.
      expect(section.variants.map((v) => v.label), [
        'Points=12',
        'Points=6, Max=35',
        'Points=1',
        'Points=0',
      ]);
    });
  });

  group('BottomSheet is registered in full', () {
    test('three content sizes, so the height requirement is reviewable', () {
      final section = sectionFor('BottomSheet');
      expect(section.figmaNodeId, '59:211');
      // `59:211` is a single authored variant, and one fixture would show a
      // reviewer nothing about the one thing `81:644` requires — that the
      // height follows the content. The labels claim option counts, which the
      // describer checks against the widget.
      expect(section.variants.map((v) => v.label), [
        'Content=3 options',
        'Content=8 options',
        'Content=30 options',
      ]);
    });
  });

  group('Radio is registered in full', () {
    test('all four variants of 25:238 are present', () {
      final section = sectionFor('Radio');
      expect(section.figmaNodeId, '25:238');
      // 2 x 2, and the labels are Figma's own axes. A count alone would pass
      // for four copies of one variant.
      expect(section.variants.map((v) => v.label), [
        'Selected=false, Disabled=false',
        'Selected=false, Disabled=true',
        'Selected=true, Disabled=false',
        'Selected=true, Disabled=true',
      ]);
    });

    test('the composition that carries the group rule is rendered too', () {
      // RadioRow and RadioGroup are not authored sets — they are D8's
      // composition — but a component nobody can look at is a component whose
      // derived layout nobody will correct.
      expect(sectionFor('RadioRow').variants, hasLength(4));
      expect(
        sectionFor('RadioRow').variants.map((v) => v.label),
        contains('Selected=false, Disabled=true'),
      );

      final group = sectionFor('RadioGroup');
      expect(
        group.variants,
        hasLength(3),
        reason:
            'one variant per selectable value: "exactly one is selected" can '
            'only be reviewed by seeing the selection move',
      );
      expect(
        group.variants.map((v) => v.label).toSet(),
        hasLength(3),
        reason: 'two variants share a label, so the selection does not move',
      );
    });
  });
}

/// The checkable claims a variant label makes, lowercased.
///
/// Figma's variant syntax is `Key=Value, Key=Value`; the icon set uses
/// `group/name`. Both are parsed. A label in neither form yields an empty set,
/// which the test above treats as a failure rather than as nothing to check.
Set<String> _claimsIn(String label) {
  final claims = <String>{};
  for (final pair in label.split(', ')) {
    final parts = pair.split('=');
    if (parts.length == 2) {
      // Every word of the value, not just the first: `Slot=4 (accounts)` claims
      // both the slot number and the slide it belongs to.
      for (final word in parts[1].split(RegExp(r'[\s()]+'))) {
        if (RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(word.toLowerCase())) {
          claims.add(word.toLowerCase());
        }
      }
    } else if (pair.contains('/')) {
      claims.add(pair.split('/').last.toLowerCase());
    }
  }
  return claims;
}

/// A canonical description of what a gallery variant actually built.
///
/// Unknown types throw rather than degrading to a generic description, so adding
/// a component to the catalog without teaching this function about it fails the
/// two generic checks above instead of silently narrowing their coverage.
///
/// It is **not** a compile error, and tasks.md 9.1 and commit `8f33e44` both said
/// it was. `Widget` is not a sealed type, so an exhaustive switch over it is not
/// expressible; the `_ =>` arm below is a runtime `UnsupportedError`. The gate
/// still fails, so the effect is what was claimed — but the mechanism was not,
/// and the mechanism was the load-bearing part of the argument.
/// What a gallery variant actually built, as a canonical string.
///
/// Delegates to one describer per owner so two agents can add components in
/// parallel without both editing one switch — a switch is a compile-level
/// collision, not a merge conflict. Each owner's file is theirs alone; only the
/// two `??` operators here are shared.
///
/// Unknown types throw rather than degrading to a generic description, so adding
/// a component without teaching a describer about it fails the two generic
/// checks above instead of silently narrowing their coverage. It is **not** a
/// compile error — `Widget` is not sealed, so an exhaustive switch over it is
/// not expressible.
String _describe(Widget widget) =>
    _describeCore(widget) ??
    describeAuth(widget) ??
    describeHome(widget) ??
    describeBudgets(widget) ??
    describeInsights(widget) ??
    (throw UnsupportedError(
      'No describer knows ${widget.runtimeType}. Add a case to the file you own '
      '(gallery_describe_auth.dart, _budgets.dart, _home.dart or '
      '_insights.dart), so the variant-distinctness check keeps covering every '
      'section.',
    ));

String? _describeCore(Widget widget) => switch (widget) {
  MonetaButton(:final style, :final size, :final state, :final label) =>
    'Button(${style.name},${size.name},${state.name},$label)',
  // Figma labels positions 1-based (`Active=1`) while `activeIndex` is 0-based.
  // The description speaks the label's vocabulary so the two are comparable —
  // otherwise the label check has to skip digits, and skipping digits is how a
  // pair of swapped `Slot=N` labels went unnoticed.
  MonetaPaginationDots(:final count, :final activeIndex) =>
    'Dots(count=$count,active=${activeIndex + 1})',
  // Names the slide too, because the gallery label does (`Slot=4 (accounts)`)
  // and a claim nothing can be compared against is a claim nothing checks.
  OnboardingIllustration(:final glyph, :final chartSlot) =>
    'Illustration(${glyph.figmaName},$chartSlot,'
        '${OnboardingSlide.values.where((s) => s.chartSlot == chartSlot).map((s) => s.name).join("|")})',
  TransactionRow(:final direction, :final category, :final title) =>
    'Row(${direction.name},${category.name},$title)',
  // `masked` false is labelled `State=Default` in Figma, so the description
  // names the state rather than the flag — a label that claims a property has to
  // be checkable against something.
  BalanceCard(:final masked, :final totalBalance) =>
    'BalanceCard(${masked ? "masked" : "default"},$totalBalance)',
  BudgetCard(:final category, :final spent, :final limit, :final status) =>
    'BudgetCard(${category.name},${status.name},$spent/$limit)',
  MonetaBottomNav(:final active) => 'BottomNav(${active.name})',
  // The bar derives its own state from the fraction, and Figma labels the
  // variants by that state (`Under`/`Near`/`Over`), not by the number. Naming
  // the derived state is what makes the label checkable.
  MonetaProgressBar(:final fraction, :final size) =>
    'ProgressBar(${switch (BudgetStatus.fromFraction(fraction)) {
      BudgetStatus.onTrack => 'under',
      BudgetStatus.nearLimit => 'near',
      BudgetStatus.over => 'over',
    }},$fraction,${size.name})',
  CategoryIcon(:final category, :final size) =>
    'CategoryIcon(${category.name},${size.name})',
  // `figmaName` (`alert-triangle`), not `name` (`alertTriangle`): the label is
  // the Figma name, and the description has to be comparable to it.
  MonetaIcon(:final icon, :final size) => 'Icon(${icon.figmaName},$size)',
  _ => null,
};

/// Minimal stand-in: every member throws, so any builder that actually reads the
/// context fails the test instead of quietly working.
class _NullContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('a gallery builder read its BuildContext');
}
