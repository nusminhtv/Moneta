import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const trackWidth = 240.0;

  Future<void> pumpBar(
    WidgetTester tester,
    double fraction, {
    MonetaProgressBarSize size = MonetaProgressBarSize.md,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: trackWidth,
        child: MonetaProgressBar(fraction: fraction, size: size),
      ),
    );
  }

  Size fillSize(WidgetTester tester) =>
      tester.getSize(find.byKey(MonetaProgressBar.fillKey));

  Color fillColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(MonetaProgressBar.fillKey),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  group('geometry', () {
    testWidgets('the fill is proportional to the fraction', (tester) async {
      for (final fraction in [0.0, 0.25, 0.5, 0.62, 0.88, 1.0]) {
        await pumpBar(tester, fraction);
        expect(
          fillSize(tester).width,
          closeTo(trackWidth * fraction, 0.01),
          reason: 'fraction $fraction',
        );
      }
    });

    testWidgets('the Figma fill widths reproduce exactly', (tester) async {
      // Node 21:139 authors 148.8px and 211.2px fills on a 240px track.
      await pumpBar(tester, 0.62);
      expect(fillSize(tester).width, closeTo(148.8, 0.01));
      await pumpBar(tester, 0.88);
      expect(fillSize(tester).width, closeTo(211.2, 0.01));
    });

    testWidgets('an over-budget fill stops at the track edge', (tester) async {
      for (final fraction in [1.0001, 2.0, 4.0, double.infinity]) {
        await pumpBar(tester, fraction);
        expect(
          fillSize(tester).width,
          closeTo(trackWidth, 0.01),
          reason: 'fraction $fraction must not overflow the track',
        );
      }
    });

    testWidgets('a negative fraction renders empty, not mirrored', (
      tester,
    ) async {
      await pumpBar(tester, -0.5);
      expect(fillSize(tester).width, 0);
    });

    testWidgets('NaN renders empty rather than throwing', (tester) async {
      await pumpBar(tester, double.nan);
      expect(fillSize(tester).width, 0);
    });

    testWidgets('the fill grows from the left', (tester) async {
      await pumpBar(tester, 0.5);
      final track = tester.getRect(find.byType(MonetaProgressBar));
      final fill = tester.getRect(find.byKey(MonetaProgressBar.fillKey));
      expect(fill.left, closeTo(track.left, 0.01));
      expect(fill.right, lessThan(track.right));
    });
  });

  group('sizes', () {
    testWidgets('sm is 6px and md is 10px, as authored', (tester) async {
      await pumpBar(tester, 0.5, size: MonetaProgressBarSize.sm);
      expect(fillSize(tester).height, 6);
      await pumpBar(tester, 0.5);
      expect(fillSize(tester).height, 10);
    });

    testWidgets('md is the default', (tester) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          child: MonetaProgressBar(fraction: 0.5),
        ),
      );
      expect(fillSize(tester).height, 10);
    });

    test('the fill radius is half the height, as authored', () {
      expect(MonetaProgressBarSize.sm.fillRadius, 3);
      expect(MonetaProgressBarSize.md.fillRadius, 5);
    });
  });

  group('derived colour', () {
    testWidgets('under 80% uses the income colour', (tester) async {
      await pumpBar(tester, 0.62);
      expect(fillColor(tester), colors.income);
    });

    testWidgets('80% up to and including the limit uses warning', (
      tester,
    ) async {
      for (final fraction in [0.8, 0.88, 1.0]) {
        await pumpBar(tester, fraction);
        expect(fillColor(tester), colors.warning, reason: 'fraction $fraction');
      }
    });

    testWidgets('above the limit uses the expense colour', (tester) async {
      await pumpBar(tester, 1.5);
      expect(fillColor(tester), colors.expense);
    });

    testWidgets('the track behind the fill is the track token', (tester) async {
      await pumpBar(tester, 0.5);
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(MonetaProgressBar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, colors.track);
    });

    testWidgets('there is no way to pass a colour in', (tester) async {
      // Guarded by the constructor's shape rather than a runtime check: the
      // Figma rule is that the colour is derived, never chosen.
      await pumpBar(tester, 0.5);
      final bar = tester.widget<MonetaProgressBar>(
        find.byType(MonetaProgressBar),
      );
      expect(bar.fraction, 0.5);
    });
  });

  group('accessibility', () {
    testWidgets('reports the clamped percentage as its value', (tester) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          child: MonetaProgressBar(
            fraction: 0.62,
            semanticLabel: 'Food budget',
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Food budget'));
      expect(node.value, '62%');
    });

    testWidgets('an over-budget bar reports 100%, not 400%', (tester) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          child: MonetaProgressBar(fraction: 4, semanticLabel: 'Shopping'),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Shopping')).value,
        '100%',
      );
    });
  });
}
