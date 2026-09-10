import 'dart:io';
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

  group('the cap is eight and the rest folds', () {
    List<ChartSeries> spread(int count) => [
      for (var i = 0; i < count; i++)
        series('Category $i', (count - i) * 100000, ChartSlot.forRank(i)),
    ];

    DonutChart donut(List<ChartSeries> categories) => DonutChart(
      categories: categories,
      centreLabel: 'Total spent',
      periodLabel: 'August 2026',
    );

    test('nine categories give eight coloured segments plus one neutral', () {
      final chart = donut(spread(9));
      expect(chart.segments, hasLength(9));
      expect(
        chart.segments.take(8).map((s) => s.slot),
        everyElement(isNot(ChartSlot.other)),
      );
      expect(chart.segments.last.slot, ChartSlot.other);
      expect(chart.segments.last.label, 'Other');
    });

    test('exactly eight categories fold nothing', () {
      final chart = donut(spread(8));
      expect(chart.segments, hasLength(8));
      expect(
        chart.segments.map((s) => s.slot),
        everyElement(isNot(ChartSlot.other)),
        reason: 'an Other segment at the cap would invent a ninth category',
      );
    });

    test('the cap holds at every count, not only at nine', () {
      // The `home-overview` lesson: a regression test written for one cap
      // passed for a cap of three. This loops.
      for (var count = 1; count <= 20; count++) {
        final chart = donut(spread(count));
        final coloured = chart.segments
            .where((s) => s.slot != ChartSlot.other)
            .length;
        expect(
          coloured,
          lessThanOrEqualTo(DonutChart.maxColoredSegments),
          reason: '$count categories drew $coloured coloured segments',
        );
        expect(
          chart.segments,
          hasLength(count <= 8 ? count : 9),
          reason:
              '$count categories should give ${count <= 8 ? count : 9} '
              'segments',
        );
      }
    });

    test('segments are ranked largest first', () {
      final shuffled = [
        series('small', 100, ChartSlot.slot1),
        series('large', 900, ChartSlot.slot2),
        series('middle', 500, ChartSlot.slot3),
      ];
      expect(
        donut(shuffled).segments.map((s) => s.label),
        ['large', 'middle', 'small'],
      );
    });

    test('the folded total is not lost, at every count', () {
      for (var count = 0; count <= 20; count++) {
        final categories = spread(count);
        final chart = donut(categories);
        final supplied = categories.fold(
          const Money.zero(vnd),
          (sum, c) => sum + c.amount,
        );
        final drawn = chart.segments.fold(
          const Money.zero(vnd),
          (sum, s) => sum + s.amount,
        );
        expect(
          drawn,
          supplied,
          reason: 'the fold dropped money at $count categories',
        );
        expect(chart.total, supplied, reason: 'the centre disagrees at $count');
      }
    });

    testWidgets('the centre total equals the sum of the drawn segments', (
      tester,
    ) async {
      final categories = spread(11);
      await pumpDonut(tester, categories);
      final drawn = donut(categories).segments.fold(
        const Money.zero(vnd),
        (sum, s) => sum + s.amount,
      );
      expect(
        tester.widget<Text>(find.byKey(DonutChart.centreValueKey)).data,
        drawn.format(),
      );
    });

    test('the shares sum to one and match the amounts', () {
      final categories = spread(11);
      final chart = donut(categories);
      final shares = chart.fractions;

      expect(shares, hasLength(chart.segments.length));
      expect(
        shares.reduce((a, b) => a + b),
        closeTo(1, 1e-12),
        reason: 'a legend whose percentages do not add up is a wrong legend',
      );
      final total = chart.total.minorUnits;
      for (var i = 0; i < shares.length; i++) {
        expect(
          shares[i],
          closeTo(chart.segments[i].amount.minorUnits / total, 1e-12),
        );
      }
    });

    testWidgets('nine categories give nine legend rows, the last Other', (
      tester,
    ) async {
      await pumpDonut(tester, spread(9));
      final rows = tester
          .widgetList<ChartLegendItem>(find.byType(ChartLegendItem))
          .toList();
      expect(rows, hasLength(9));
      expect(rows.last.slot, ChartSlot.other);
      expect(rows.last.label, 'Other');
    });
  });

  group('the legend cannot be turned off', () {
    // A widget test cannot prove the ABSENCE of a parameter, and an
    // always-empty diagnostics list proves nothing either — that lesson is
    // recorded in `near_limit_threshold_test.dart`. So the constructor's
    // parameter list is read out of the source and compared exactly.
    const source = 'lib/design_system/organisms/donut_chart.dart';

    test('the constructor takes exactly the parameters it should', () {
      final file = File(source);
      expect(file.existsSync(), isTrue, reason: '$source moved');

      expect(
        _constructorParameters(file.readAsStringSync(), 'DonutChart'),
        {'categories', 'centreLabel', 'periodLabel', 'otherLabel', 'key'},
        reason:
            'annotation 77:284 makes the legend a contrast requirement for two '
            'of the eight slots, so there must be no parameter — no flag, no '
            'builder, no override — by which a caller can suppress, empty or '
            'replace it. Any new parameter has to be added here deliberately.',
      );
    });

    test('and the check itself can fail', () {
      // Guards the guard. If the extractor stopped finding parameters, the
      // test above would pass forever on an empty set.
      const counterfeit = '''
        class DonutChart extends StatelessWidget {
          const DonutChart({
            required this.categories,
            this.showLegend = true,
            super.key,
          });
        }
      ''';
      expect(_constructorParameters(counterfeit, 'DonutChart'), {
        'categories',
        'showLegend',
        'key',
      });
    });

    test('no legend-shaped identifier appears in the API at all', () {
      final lines = File(source).readAsLinesSync();
      final fields = lines
          .where((l) => RegExp(r'^\s+final .*;').hasMatch(l))
          .join('\n');
      expect(
        fields.toLowerCase(),
        isNot(contains('legend')),
        reason: 'a stored legend is a legend a caller can supply',
      );
    });

    testWidgets('a donut with two or more segments always shows its legend', (
      tester,
    ) async {
      for (var count = 2; count <= 12; count++) {
        await pumpDonut(tester, [
          for (var i = 0; i < count; i++)
            series('Category $i', (count - i) * 100000, ChartSlot.forRank(i)),
        ]);
        expect(
          find.byType(ChartLegendItem),
          findsNWidgets(count <= 8 ? count : 9),
          reason: 'no legend rows at $count categories',
        );
      }
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

    testWidgets('the arcs are painted in the colours the legend advertises', (
      tester,
    ) async {
      // Built FROM the rendered legend rather than from the fixture, so the
      // two halves are compared against each other. A donut that coloured its
      // arcs by rank while its legend used the supplied slots — or the other
      // way round — fails here; a fixture-driven assertion would pass for both
      // as long as each half was self-consistent.
      await pumpDonut(tester, authored);
      final rows = tester.widgetList<ChartLegendItem>(
        find.byType(ChartLegendItem),
      );

      var matcher = paints..arc(color: colors.track);
      for (final row in rows) {
        matcher = matcher..arc(color: row.slot.colorIn(colors));
      }
      expect(find.byKey(DonutChart.ringKey), matcher);
    });
  });

  group('boundary inputs', () {
    DonutChart donut(List<ChartSeries> categories) => DonutChart(
      categories: categories,
      centreLabel: 'Total spent',
      periodLabel: 'August 2026',
    );

    testWidgets('no categories: an empty ring, and not a full one', (
      tester,
    ) async {
      await pumpDonut(tester, const []);
      expect(tester.takeException(), isNull);

      expect(find.byType(ChartLegendItem), findsNothing);
      expect(
        find.byKey(DonutChart.ringKey),
        paints..arc(color: colors.track),
      );
      // Exactly one arc: the track. "No data" must not read as one category
      // holding everything, which is what a single full-turn arc would say.
      expect(
        find.byKey(DonutChart.ringKey),
        paintsExactlyCountTimes(#drawArc, 1),
      );
      expect(donut(const []).segments, isEmpty);
      expect(donut(const []).total, const Money.zero(vnd));
    });

    testWidgets('one category: the whole ring, and a 100% legend row', (
      tester,
    ) async {
      await pumpDonut(tester, [series('Rent', 9000000, ChartSlot.slot3)]);

      expect(
        find.byKey(DonutChart.ringKey),
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.chart.base(3), sweepAngle: 2 * math.pi),
      );
      expect(find.byType(ChartLegendItem), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('a zero-amount category draws no arc and divides by nothing', (
      tester,
    ) async {
      final categories = [
        series('Rent', 9000000, ChartSlot.slot3),
        series('Gifts', 0, ChartSlot.slot5),
      ];
      await pumpDonut(tester, categories);
      expect(tester.takeException(), isNull);

      // Track plus one arc: the zero category is listed but not drawn.
      expect(
        find.byKey(DonutChart.ringKey),
        paintsExactlyCountTimes(#drawArc, 2),
      );
      expect(find.byType(ChartLegendItem), findsNWidgets(2));
      expect(donut(categories).fractions.last, 0);
      expect(donut(categories).fractions.last.isFinite, isTrue);
    });

    testWidgets('every amount zero: no arc, every share zero, no throw', (
      tester,
    ) async {
      final categories = [
        series('Rent', 0, ChartSlot.slot1),
        series('Food', 0, ChartSlot.slot2),
      ];
      await pumpDonut(tester, categories);
      expect(tester.takeException(), isNull);

      expect(
        find.byKey(DonutChart.ringKey),
        paintsExactlyCountTimes(#drawArc, 1),
      );
      expect(donut(categories).fractions, everyElement(0));
      expect(find.text('0%'), findsNWidgets(2));
      expect(donut(categories).total, const Money.zero(vnd));
    });

    testWidgets('a negative amount contributes nothing, not a reverse sweep', (
      tester,
    ) async {
      final categories = [
        series('Rent', 9000000, ChartSlot.slot3),
        series('Refund', -2000000, ChartSlot.slot5),
      ];
      await pumpDonut(tester, categories);
      expect(tester.takeException(), isNull);

      expect(
        find.byKey(DonutChart.ringKey),
        paintsExactlyCountTimes(#drawArc, 2),
      );
      expect(
        donut(categories).fractions,
        everyElement(greaterThanOrEqualTo(0)),
        reason: 'a negative share would sweep backwards over its neighbour',
      );
      // The centre still reports the real arithmetic: the refund happened.
      expect(donut(categories).total, const Money(7000000, vnd));
    });

    test('near-maximum amounts stay finite and inside one turn', () {
      // 2^61-1 apiece. Arithmetic only, deliberately not rendered: see the
      // widget test below for why.
      const huge = (1 << 61) - 1;
      final categories = [
        series('A', huge, ChartSlot.slot1),
        series('B', huge ~/ 3, ChartSlot.slot2),
      ];

      final shares = donut(categories).fractions;
      expect(shares, everyElement(predicate<double>((v) => v.isFinite)));
      expect(shares.reduce((a, b) => a + b), closeTo(1, 1e-12));
      expect(
        shares,
        everyElement(lessThanOrEqualTo(1)),
        reason: 'a share above one is an arc past a full turn',
      );
      expect(donut(categories).total, const Money(huge + huge ~/ 3, vnd));
      expect(
        donut(categories).total.minorUnits,
        greaterThan(huge),
        reason: 'the sum must not have wrapped',
      );
    });

    testWidgets('a very large but real amount renders without overflowing', (
      tester,
    ) async {
      // ~1 quadrillion đồng — past any real ledger, and the largest magnitude
      // the authored row can hold.
      //
      // `ChartLegendItem` pins its figures and flexes only its label, exactly
      // as `47:2` authors it. Once the label is at zero width the row is
      // over-subscribed and `RenderFlex` reports an overflow, and NO
      // arrangement of a 353px row can show an unbounded amount — the only
      // choice is which part is lost, and the design says the label goes
      // first. So this asserts the real bound rather than pretending there
      // is none; the arithmetic above covers the magnitudes past it. Recorded
      // as a known limit in `docs/design-system/figma-map.md`.
      await pumpDonut(tester, [
        series('A', 999999999999999, ChartSlot.slot1),
        series('B', 111111111111111, ChartSlot.slot2),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.byType(ChartLegendItem), findsNWidgets(2));
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
    });

    test('mixed currencies are reported, not summed', () {
      final mixed = [
        series('Rent', 9000000, ChartSlot.slot1),
        const ChartSeries(
          label: 'Trip',
          amount: Money(12000, Currency.usd),
          slot: ChartSlot.slot2,
        ),
      ];
      expect(() => donut(mixed).total, throwsArgumentError);
      expect(() => donut(mixed).segments, throwsArgumentError);
      expect(() => donut(mixed).fractions, throwsArgumentError);
    });

    testWidgets('a mixed-currency donut fails loudly rather than drawing', (
      tester,
    ) async {
      await pumpDonut(tester, [
        series('Rent', 9000000, ChartSlot.slot1),
        const ChartSeries(
          label: 'Trip',
          amount: Money(12000, Currency.usd),
          slot: ChartSlot.slot2,
        ),
      ]);
      expect(tester.takeException(), isA<ArgumentError>());
    });
  });
}

/// The named parameters of [className]'s generative constructor, as declared.
///
/// Reads `this.x` and `super.x` out of the constructor's parameter block. A
/// text scan rather than reflection, because `dart:mirrors` is unavailable in
/// Flutter — and it is guarded by a counterfeit above, so it cannot rot into a
/// check that always passes.
Set<String> _constructorParameters(String source, String className) {
  final start = source.indexOf('const $className({');
  if (start < 0) return const {};
  final open = source.indexOf('{', start);
  final close = source.indexOf('});', open);
  if (close < 0) return const {};
  final block = source.substring(open, close);
  return RegExp(
    r'(?:this|super)\.(\w+)',
  ).allMatches(block).map((m) => m.group(1)!).toSet();
}
