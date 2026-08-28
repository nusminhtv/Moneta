import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpBar(
    WidgetTester tester, {
    MonetaAppBarVariant variant = MonetaAppBarVariant.largeTitle,
    String title = 'Transactions',
    double topInset = 20,
    List<MonetaAppBarAction> actions = const [],
    VoidCallback? onBack,
  }) async {
    await pumpMonetaWidget(
      tester,
      MonetaAppBar(
        title: title,
        variant: variant,
        onBack: onBack,
        actions: actions,
      ),
      surfaceSize: const Size(393, 852),
      viewPadding: EdgeInsets.only(top: topInset),
    );
  }

  MonetaAppBarAction action(String label) => (
    icon: MonetaIconName.search,
    semanticLabel: label,
    onPressed: () {},
  );

  group('the top offset follows the device inset', () {
    // 20 and 47 on purpose. Neither is 59 (MonetaLayout.safeAreaTop) nor 34
    // (safeAreaBottom), so a bar that hardcodes either device constant — or
    // reads the token instead of the inset — fails both cases. The nearest
    // precedent in this repo sets its test inset *to the very constant a broken
    // widget would hardcode*, which cannot discriminate; this deliberately does
    // not.
    for (final inset in <double>[20, 47]) {
      testWidgets('content begins at the inset when it is $inset', (
        tester,
      ) async {
        await pumpBar(tester, topInset: inset);
        final bar = tester.getRect(find.byType(MonetaAppBar));
        final title = tester.getRect(find.text('Transactions'));

        expect(
          title.top,
          greaterThanOrEqualTo(bar.top + inset),
          reason: 'the title sits above the device inset',
        );
        expect(
          bar.height,
          moreOrLessEquals(inset + MonetaAppBarVariant.largeTitle.barHeight),
          reason: 'total height is the inset plus the authored bar height',
        );
      });
    }
  });

  group('variants', () {
    testWidgets('LargeTitle is 96 tall below the inset, the rest 56', (
      tester,
    ) async {
      const inset = 20.0;
      for (final variant in MonetaAppBarVariant.values) {
        await pumpBar(tester, variant: variant, topInset: inset);
        expect(
          tester.getSize(find.byType(MonetaAppBar)).height,
          moreOrLessEquals(inset + variant.barHeight),
          reason: variant.name,
        );
      }
      // The authored numbers, written out rather than read back off the enum.
      expect(MonetaAppBarVariant.largeTitle.barHeight, 96);
      expect(MonetaAppBarVariant.titleBack.barHeight, 56);
      expect(MonetaAppBarVariant.titleActions.barHeight, 56);
      expect(MonetaAppBarVariant.transparent.barHeight, 56);
    });

    testWidgets('only Transparent paints no background', (tester) async {
      for (final variant in MonetaAppBarVariant.values) {
        await pumpBar(tester, variant: variant);
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(MonetaAppBar),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final colour = (box.decoration as BoxDecoration).color;
        if (variant == MonetaAppBarVariant.transparent) {
          expect(
            colour,
            isNull,
            reason: 'Transparent must show what is behind',
          );
        } else {
          expect(colour, colors.canvas, reason: variant.name);
        }
      }
    });

    testWidgets('a back control exists only where Figma draws one', (
      tester,
    ) async {
      for (final variant in MonetaAppBarVariant.values) {
        await pumpBar(tester, variant: variant, onBack: () {});
        final back = find.byWidgetPredicate(
          (w) => w is MonetaIconButton && w.semanticLabel == 'Back',
        );
        if (variant.hasBack) {
          expect(back, findsOneWidget, reason: variant.name);
          expect(
            tester.getSize(back).height,
            greaterThanOrEqualTo(44),
            reason: '${variant.name} back control is below the touch target',
          );
        } else {
          expect(back, findsNothing, reason: variant.name);
        }
      }
      expect(
        MonetaAppBarVariant.values.where((v) => v.hasBack).map((v) => v.name),
        ['titleBack', 'transparent'],
      );
    });

    testWidgets('each variant uses its authored title style', (tester) async {
      final type = MonetaTheme.dark().text;
      final expected = {
        MonetaAppBarVariant.largeTitle: type.headingH1,
        MonetaAppBarVariant.titleActions: type.headingH3,
        MonetaAppBarVariant.titleBack: type.titleMd,
        MonetaAppBarVariant.transparent: type.titleMd,
      };
      expect(expected.keys, containsAll(MonetaAppBarVariant.values));
      for (final entry in expected.entries) {
        await pumpBar(tester, variant: entry.key);
        final style = tester.widget<Text>(find.text('Transactions')).style!;
        expect(style.fontSize, entry.value.fontSize, reason: entry.key.name);
        expect(
          style.fontWeight,
          entry.value.fontWeight,
          reason: entry.key.name,
        );
        expect(
          style.fontFamily,
          entry.value.fontFamily,
          reason: entry.key.name,
        );
      }
      // The compact bar and the large one are genuinely different type.
      expect(type.headingH3.fontSize, isNot(type.headingH1.fontSize));
    });
  });

  group('layout', () {
    testWidgets('a long title truncates and leaves the actions in place', (
      tester,
    ) async {
      await pumpBar(
        tester,
        variant: MonetaAppBarVariant.titleActions,
        actions: [action('Search'), action('Filter')],
      );
      final shortActions = tester
          .widgetList<MonetaIconButton>(find.byType(MonetaIconButton))
          .length;
      final shortRects = find
          .byType(MonetaIconButton)
          .evaluate()
          .map(
            (e) => tester.getRect(find.byWidget(e.widget)),
          )
          .toList();

      await pumpBar(
        tester,
        variant: MonetaAppBarVariant.titleActions,
        title:
            'A title far longer than this bar can possibly accommodate '
            'without truncating it somewhere',
        actions: [action('Search'), action('Filter')],
      );

      expect(tester.takeException(), isNull, reason: 'the row overflowed');
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);

      final longRects = find
          .byType(MonetaIconButton)
          .evaluate()
          .map(
            (e) => tester.getRect(find.byWidget(e.widget)),
          )
          .toList();
      expect(
        tester
            .widgetList<MonetaIconButton>(find.byType(MonetaIconButton))
            .length,
        shortActions,
      );
      expect(
        longRects,
        shortRects,
        reason: 'a long title displaced the actions',
      );
    });

    testWidgets('an empty title keeps the bar height and the actions', (
      tester,
    ) async {
      await pumpBar(
        tester,
        variant: MonetaAppBarVariant.titleActions,
        title: '',
        actions: [action('Search')],
      );
      expect(
        tester.getSize(find.byType(MonetaAppBar)).height,
        moreOrLessEquals(20 + MonetaAppBarVariant.titleActions.barHeight),
      );
      expect(find.byType(MonetaIconButton), findsOneWidget);
    });

    testWidgets('zero, one and two actions all lay out', (tester) async {
      for (final count in [0, 1, 2]) {
        await pumpBar(
          tester,
          variant: MonetaAppBarVariant.titleActions,
          actions: [for (var i = 0; i < count; i++) action('Action $i')],
        );
        expect(tester.takeException(), isNull, reason: '$count actions');
        expect(
          tester.getSize(find.byType(MonetaAppBar)).height,
          moreOrLessEquals(20 + MonetaAppBarVariant.titleActions.barHeight),
          reason: '$count actions changed the height',
        );
        expect(find.byType(MonetaIconButton), findsNWidgets(count));
      }
    });
  });

  group('interaction', () {
    testWidgets('the back control fires', (tester) async {
      var backs = 0;
      await pumpBar(
        tester,
        variant: MonetaAppBarVariant.titleBack,
        onBack: () => backs++,
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is MonetaIconButton && w.semanticLabel == 'Back',
        ),
      );
      expect(backs, 1);
    });

    testWidgets('an action fires its own callback', (tester) async {
      var searches = 0;
      await pumpBar(
        tester,
        variant: MonetaAppBarVariant.titleActions,
        actions: [
          (
            icon: MonetaIconName.search,
            semanticLabel: 'Search',
            onPressed: () => searches++,
          ),
        ],
      );
      await tester.tap(find.byType(MonetaIconButton));
      expect(searches, 1);
    });
  });
}
