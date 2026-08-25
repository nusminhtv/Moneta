import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpDots(WidgetTester tester, int active, {int count = 3}) {
    return pumpMonetaWidget(
      tester,
      MonetaPaginationDots(count: count, activeIndex: active),
      surfaceSize: const Size(300, 200),
    );
  }

  List<Size> dotSizes(WidgetTester tester) {
    final finder = find.descendant(
      of: find.byType(MonetaPaginationDots),
      matching: find.byType(DecoratedBox),
    );
    return [
      for (var i = 0; i < finder.evaluate().length; i++)
        tester.getSize(finder.at(i)),
    ];
  }

  List<Color> dotColors(WidgetTester tester) {
    final finder = find.descendant(
      of: find.byType(MonetaPaginationDots),
      matching: find.byType(DecoratedBox),
    );
    return [
      for (final w in tester.widgetList<DecoratedBox>(finder))
        (w.decoration as BoxDecoration).color!,
    ];
  }

  group('never colour alone', () {
    testWidgets('the active dot is wider, not just brighter', (tester) async {
      // This is the whole reason the component exists. Figma: "Active dot
      // differs in WIDTH and colour — never colour alone."
      await pumpDots(tester, 0);
      final widths = dotSizes(tester).map((s) => s.width).toList();

      expect(widths[0], MonetaPaginationDots.activeDotWidth);
      expect(widths[1], MonetaPaginationDots.dotSize);
      expect(widths[2], MonetaPaginationDots.dotSize);
      expect(widths[0], greaterThan(widths[1]));
    });

    testWidgets('width alone identifies the position, in every slot', (
      tester,
    ) async {
      for (var active = 0; active < 3; active++) {
        await pumpDots(tester, active);
        final widths = dotSizes(tester).map((s) => s.width).toList();
        final widest = widths.indexOf(
          widths.reduce((a, b) => a > b ? a : b),
        );
        expect(
          widest,
          active,
          reason: 'with slot $active active, the widest dot must be $active',
        );
      }
    });

    testWidgets('colour agrees with width', (tester) async {
      await pumpDots(tester, 1);
      final fills = dotColors(tester);
      expect(fills[1], colors.brand);
      expect(fills[0], colors.borderStrong);
      expect(fills[2], colors.borderStrong);
    });

    testWidgets('exactly one dot is active', (tester) async {
      await pumpDots(tester, 2);
      expect(dotColors(tester).where((c) => c == colors.brand), hasLength(1));
    });
  });

  group('geometry', () {
    testWidgets('all dots share a height', (tester) async {
      await pumpDots(tester, 0);
      for (final size in dotSizes(tester)) {
        expect(size.height, MonetaPaginationDots.dotSize);
      }
    });

    test('the authored values', () {
      expect(MonetaPaginationDots.dotSize, 7);
      expect(MonetaPaginationDots.activeDotWidth, 22);
      expect(MonetaPaginationDots.gap, 7);
    });

    testWidgets('total width accounts for the wide dot and the gaps', (
      tester,
    ) async {
      await pumpDots(tester, 0);
      expect(
        tester.getSize(find.byType(MonetaPaginationDots)).width,
        MonetaPaginationDots.activeDotWidth +
            MonetaPaginationDots.dotSize * 2 +
            MonetaPaginationDots.gap * 2,
      );
    });

    testWidgets('works for counts other than three', (tester) async {
      await pumpDots(tester, 3, count: 5);
      expect(dotSizes(tester), hasLength(5));
    });
  });

  group('guards and accessibility', () {
    testWidgets('rejects an out-of-range active index', (tester) async {
      await pumpMonetaWidget(
        tester,
        const MonetaPaginationDots(count: 3, activeIndex: 3),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('announces the position', (tester) async {
      await pumpMonetaWidget(
        tester,
        const MonetaPaginationDots(
          count: 3,
          activeIndex: 1,
          semanticLabel: 'Onboarding progress',
        ),
        surfaceSize: const Size(300, 200),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel('Onboarding progress'),
      );
      expect(node.value, '2 of 3');
    });
  });
}
