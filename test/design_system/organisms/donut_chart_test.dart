import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/organisms/donut_chart.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;

  ChartSeries series(String label, int minor, ChartSlot slot) =>
      ChartSeries(label: label, amount: Money(minor, vnd), slot: slot);

  /// `47:62`'s own sample, in its own scrambled slot order — Food & drink is
  /// `Slot=7`, not `Slot=1`. Kept exactly as authored, because "the ring and
  /// the legend agree" is only a real check if the slots are not the trivial
  /// 1..8.
  final authored = [
    series('Food & drink', 6760000, ChartSlot.slot7),
    series('Transport', 4420000, ChartSlot.slot4),
    series('Shopping', 3900000, ChartSlot.slot2),
    series('Bills & utilities', 3380000, ChartSlot.slot8),
    series('Entertainment', 2600000, ChartSlot.slot6),
    series('Health', 2340000, ChartSlot.slot3),
    series('Gifts', 1560000, ChartSlot.slot5),
    series('Other', 1040000, ChartSlot.other),
  ];

  Future<void> pumpDonut(
    WidgetTester tester,
    List<ChartSeries> categories, {
    String centreLabel = 'Total spent',
    String periodLabel = 'August 2026',
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 353,
      child: DonutChart(
        categories: categories,
        centreLabel: centreLabel,
        periodLabel: periodLabel,
      ),
    ),
    surfaceSize: const Size(393, 900),
  );

  group('the ring paints a track and then one arc per segment', () {
    testWidgets('arcs appear in rank order, each in its own slot colour', (
      tester,
    ) async {
      await pumpDonut(tester, authored);

      // Ordered on purpose. Order IS the requirement here — the track has to
      // be under the segments — and `budget-components` shipped a test named
      // for order that did not assert it.
      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(7))
          ..arc(color: colors.chart.base(4))
          ..arc(color: colors.chart.base(2))
          ..arc(color: colors.chart.base(8))
          ..arc(color: colors.chart.base(6))
          ..arc(color: colors.chart.base(3))
          ..arc(color: colors.chart.base(5))
          ..arc(color: colors.textTertiary),
      );
    });

    testWidgets('a caller-supplied slot is honoured, not overwritten by rank', (
      tester,
    ) async {
      // `47:62` proves the file does not colour by rank: its largest category
      // is `Slot=7`. A category must keep one colour on every screen that
      // charts it, so the donut ranks the ORDER and leaves the colour alone.
      await pumpDonut(tester, [
        series('Rent', 9000000, ChartSlot.slot6),
        series('Food', 3000000, ChartSlot.slot1),
      ]);

      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(6))
          ..arc(color: colors.chart.base(1)),
      );
    });

    testWidgets('every arc is the observed 39.5 thickness', (tester) async {
      await pumpDonut(tester, authored);
      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(strokeWidth: DonutChart.ringThickness)
          ..arc(strokeWidth: DonutChart.ringThickness),
      );
    });

    testWidgets('the ring is the authored 208 box', (tester) async {
      await pumpDonut(tester, authored);
      expect(
        tester.getSize(find.byKey(DonutChart.ringKey)),
        const Size(DonutChart.ringDiameter, DonutChart.ringDiameter),
      );
    });

    testWidgets('the first arc starts at twelve o clock', (tester) async {
      await pumpDonut(tester, [series('All of it', 1000, ChartSlot.slot1)]);
      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(1), startAngle: -math.pi / 2),
      );
    });

    testWidgets('segments are separated, and a lone segment is not', (
      tester,
    ) async {
      // Two segments of exactly half each: with the observed 1° gap the sweep
      // is half of (360° - 2°), so a sweep of exactly π would mean the gap was
      // dropped.
      await pumpDonut(tester, [
        series('A', 500, ChartSlot.slot1),
        series('B', 500, ChartSlot.slot2),
      ]);
      const gap = DonutChart.segmentGapDegrees * math.pi / 180;
      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(1), sweepAngle: math.pi - gap)
          ..arc(color: colors.chart.base(2), sweepAngle: math.pi - gap),
      );

      await pumpDonut(tester, [series('All of it', 500, ChartSlot.slot1)]);
      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(1), sweepAngle: 2 * math.pi),
        reason: 'a notch in an otherwise complete circle reads as missing data',
      );
    });
  });

  group('the centre reports the total', () {
    testWidgets('label, total and period, in the authored text roles', (
      tester,
    ) async {
      await pumpDonut(tester, authored);
      final expected = authored
          .map((c) => c.amount)
          .reduce((a, b) => a + b)
          .format();

      expect(find.text('Total spent'), findsOneWidget);
      expect(find.text(expected), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);

      // `47:59`, `47:60`, `47:61`: caption tertiary, amount primary, caption
      // tertiary.
      expect(
        tester.widget<Text>(find.text('Total spent')).style!.color,
        colors.textTertiary,
      );
      expect(
        tester.widget<Text>(find.text(expected)).style!.color,
        colors.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('August 2026')).style!.color,
        colors.textTertiary,
      );
    });

    testWidgets('the total stays inside the ring', (tester) async {
      // A huge total must truncate in the 140-wide centre rather than run out
      // over the arcs. Font-independent: containment, not width.
      await pumpDonut(tester, [
        series('Everything', 999999999999, ChartSlot.slot1),
      ]);
      expect(tester.takeException(), isNull);

      final ring = tester.getRect(find.byKey(DonutChart.ringKey));
      final value = tester.getRect(find.byKey(DonutChart.centreValueKey));
      expect(value.left, greaterThanOrEqualTo(ring.left));
      expect(value.right, lessThanOrEqualTo(ring.right));
    });
  });

  group('the legend is part of the component', () {
    testWidgets('one row per segment, each agreeing with its arc', (
      tester,
    ) async {
      await pumpDonut(tester, authored);

      final rows = tester
          .widgetList<ChartLegendItem>(find.byType(ChartLegendItem))
          .toList();
      expect(rows, hasLength(authored.length));

      final ranked = [...authored]
        ..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));
      for (var i = 0; i < ranked.length; i++) {
        expect(rows[i].label, ranked[i].label);
        expect(rows[i].amount, ranked[i].amount);
        expect(
          rows[i].slot,
          ranked[i].slot,
          reason:
              'a legend row whose colour disagrees with its arc is harder to '
              'notice than no legend at all',
        );
      }
    });
  });
}
