import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpNav(
    WidgetTester tester, {
    required MonetaDestination active,
    ValueChanged<MonetaDestination>? onSelect,
    VoidCallback? onAdd,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: MonetaLayout.frameWidth,
        child: MonetaBottomNav(
          active: active,
          onSelect: onSelect,
          onAdd: onAdd,
        ),
      ),
      surfaceSize: const Size(MonetaLayout.frameWidth, 300),
      viewPadding: viewPadding,
    );
  }

  Color tabColour(WidgetTester tester, MonetaDestination destination) {
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(MonetaBottomNav.tabKey(destination)),
        matching: find.text(destination.label),
      ),
    );
    return label.style!.color!;
  }

  Color tabIconColour(WidgetTester tester, MonetaDestination destination) {
    final icon = tester.widget<MonetaIcon>(
      find.descendant(
        of: find.byKey(MonetaBottomNav.tabKey(destination)),
        matching: find.byType(MonetaIcon),
      ),
    );
    return icon.color!;
  }

  group('active destination', () {
    for (final active in MonetaDestination.values) {
      testWidgets('with ${active.name} active, exactly one tab is brand', (
        tester,
      ) async {
        await pumpNav(tester, active: active);

        for (final destination in MonetaDestination.values) {
          final expected = destination == active
              ? colors.brandOnSurface
              : colors.textTertiary;
          expect(
            tabColour(tester, destination),
            expected,
            reason: '${destination.name} label with ${active.name} active',
          );
          expect(
            tabIconColour(tester, destination),
            expected,
            reason: '${destination.name} icon with ${active.name} active',
          );
        }

        final brandCount = MonetaDestination.values
            .where((d) => tabColour(tester, d) == colors.brandOnSurface)
            .length;
        expect(brandCount, 1);
      });
    }

    testWidgets('all four destinations are present, in Figma order', (
      tester,
    ) async {
      await pumpNav(tester, active: MonetaDestination.home);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      final lefts = MonetaDestination.values
          .map(
            (d) => tester.getRect(find.byKey(MonetaBottomNav.tabKey(d))).left,
          )
          .toList();
      for (var i = 1; i < lefts.length; i++) {
        expect(lefts[i], greaterThan(lefts[i - 1]));
      }
    });

    testWidgets('reports a destination and does not navigate itself', (
      tester,
    ) async {
      final picked = <MonetaDestination>[];
      await pumpNav(
        tester,
        active: MonetaDestination.home,
        onSelect: picked.add,
      );
      await tester.tap(
        find.byKey(MonetaBottomNav.tabKey(MonetaDestination.insights)),
      );
      await tester.pump();

      expect(picked, [MonetaDestination.insights]);
      // The bar reports; the caller decides. Its own active tab is unchanged.
      expect(
        tabColour(tester, MonetaDestination.home),
        colors.brandOnSurface,
      );
    });

    testWidgets('marks the active tab as selected for assistive tech', (
      tester,
    ) async {
      await pumpNav(tester, active: MonetaDestination.profile);
      await tester.pumpAndSettle();
      // flagsCollection.isSelected is a Tristate, not a bool.
      expect(
        tester
            .getSemantics(
              find.byKey(MonetaBottomNav.tabKey(MonetaDestination.profile)),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      // And the inactive tabs must not also claim to be selected.
      for (final other in MonetaDestination.values) {
        if (other == MonetaDestination.profile) continue;
        expect(
          tester
              .getSemantics(find.byKey(MonetaBottomNav.tabKey(other)))
              .flagsCollection
              .isSelected,
          isNot(Tristate.isTrue),
          reason: '${other.name} should not be selected',
        );
      }
    });
  });

  group('floating add action', () {
    testWidgets('is not a fifth destination', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      // Four tab keys, and the FAB is not one of them.
      for (final d in MonetaDestination.values) {
        expect(find.byKey(MonetaBottomNav.tabKey(d)), findsOneWidget);
      }
      expect(find.byKey(MonetaBottomNav.fabKey), findsOneWidget);
    });

    testWidgets('reports add, distinctly from selection', (tester) async {
      var adds = 0;
      final picked = <MonetaDestination>[];
      await pumpNav(
        tester,
        active: MonetaDestination.home,
        onSelect: picked.add,
        onAdd: () => adds++,
      );
      await tester.tap(find.byKey(MonetaBottomNav.fabKey));
      await tester.pump();

      expect(adds, 1);
      expect(picked, isEmpty, reason: 'add must not read as a destination');
    });

    testWidgets('does not change the active destination', (tester) async {
      await pumpNav(
        tester,
        active: MonetaDestination.transactions,
        onAdd: () {},
      );
      await tester.tap(find.byKey(MonetaBottomNav.fabKey));
      await tester.pump();
      expect(
        tabColour(tester, MonetaDestination.transactions),
        colors.brandOnSurface,
      );
    });

    testWidgets('is the Figma size, brand-filled, and glowing', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      expect(
        tester.getSize(find.byKey(MonetaBottomNav.fabKey)),
        const Size.square(MonetaLayout.fabSize),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(MonetaBottomNav.fabKey),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, colors.brand);
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('floats above the bar rather than sitting in it', (
      tester,
    ) async {
      await pumpNav(tester, active: MonetaDestination.home);
      final nav = tester.getRect(find.byType(MonetaBottomNav));
      final fab = tester.getRect(find.byKey(MonetaBottomNav.fabKey));
      expect(
        fab.top,
        closeTo(nav.top - MonetaLayout.fabOverlap, 0.01),
        reason: 'the FAB should overhang the top edge',
      );
    });

    testWidgets('is horizontally centred in the bar', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      final nav = tester.getRect(find.byType(MonetaBottomNav));
      final fab = tester.getRect(find.byKey(MonetaBottomNav.fabKey));
      expect(fab.center.dx, closeTo(nav.center.dx, 0.01));
      // Figma places it at x=168.5 in a 393pt frame, which is exactly centred.
      expect(fab.left, closeTo(168.5, 0.01));
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      await tester.tap(find.byKey(MonetaBottomNav.fabKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('safe area', () {
    testWidgets('reserves the bottom inset below the tab row', (tester) async {
      const inset = MonetaLayout.safeAreaBottom;
      await pumpNav(
        tester,
        active: MonetaDestination.home,
        viewPadding: const EdgeInsets.only(bottom: inset),
      );
      final nav = tester.getRect(find.byType(MonetaBottomNav));
      final tab = tester.getRect(
        find.byKey(MonetaBottomNav.tabKey(MonetaDestination.home)),
      );
      expect(
        nav.bottom - tab.bottom,
        greaterThanOrEqualTo(inset),
        reason: 'the tab row must sit above the device inset',
      );
    });

    testWidgets('the bar grows by exactly the inset', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      final withoutInset = tester.getSize(find.byType(MonetaBottomNav)).height;

      await pumpNav(
        tester,
        active: MonetaDestination.home,
        viewPadding: const EdgeInsets.only(
          bottom: MonetaLayout.safeAreaBottom,
        ),
      );
      final withInset = tester.getSize(find.byType(MonetaBottomNav)).height;

      expect(
        withInset - withoutInset,
        closeTo(MonetaLayout.safeAreaBottom, 0.01),
      );
    });

    testWidgets('the background extends through the inset', (tester) async {
      await pumpNav(
        tester,
        active: MonetaDestination.home,
        viewPadding: const EdgeInsets.only(
          bottom: MonetaLayout.safeAreaBottom,
        ),
      );
      final nav = tester.getRect(find.byType(MonetaBottomNav));
      final surface = tester.getRect(
        find
            .descendant(
              of: find.byType(MonetaBottomNav),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(surface.bottom, closeTo(nav.bottom, 0.01));
    });
  });

  group('surface', () {
    testWidgets('uses the surface colour and a subtle top border', (
      tester,
    ) async {
      await pumpNav(tester, active: MonetaDestination.home);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MonetaBottomNav),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, colors.surface);
      expect(
        decoration.border,
        Border(top: BorderSide(color: colors.borderSubtle)),
      );
    });

    testWidgets('tab icons are the authored 23px, not 24', (tester) async {
      await pumpNav(tester, active: MonetaDestination.home);
      for (final destination in MonetaDestination.values) {
        final icon = tester.widget<MonetaIcon>(
          find.descendant(
            of: find.byKey(MonetaBottomNav.tabKey(destination)),
            matching: find.byType(MonetaIcon),
          ),
        );
        expect(icon.size, MonetaBottomNav.tabIconSize);
        expect(icon.size, 23);
      }
    });
  });
}
