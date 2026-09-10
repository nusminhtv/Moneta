import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/organisms/line_chart.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;

  LineSeries series(String label, List<int> millions) => LineSeries(
    label: label,
    points: [for (final m in millions) Money(m * 1000000, vnd)],
  );

  Future<void> pumpChart(
    WidgetTester tester, {
    LineSeries? income,
    LineSeries? expenses,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 353,
      child: MonetaLineChart(
        title: 'Cash flow',
        subtitle: 'Income vs expenses · VND millions',
        income: income ?? series('Income', [30, 32, 31, 34, 33, 32]),
        expenses: expenses ?? series('Expenses', [24, 26, 22, 27, 25, 26]),
      ),
    ),
    surfaceSize: const Size(393, 500),
  );

  group('one axis, always from zero', () {
    test('the API exposes no second axis, scale or minimum', () {
      // A widget test cannot prove a parameter's absence, so the constructor's
      // parameter list is read out of the source and compared exactly.
      // Annotation 77:430: "ONE y-axis only. Income and expenses share a scale
      // on purpose — a dual-axis chart would let the two lines cross wherever
      // the scales were chosen to make them cross."
      final source = File(
        'lib/design_system/organisms/line_chart.dart',
      ).readAsStringSync();
      final start = source.indexOf('const MonetaLineChart({');
      expect(start, greaterThan(-1), reason: 'the constructor was renamed');
      final block = source.substring(start, source.indexOf('});', start));
      final parameters = RegExp(
        r'(?:this|super)\.(\w+)',
      ).allMatches(block).map((m) => m.group(1)!).toSet();

      expect(parameters, {'title', 'subtitle', 'income', 'expenses', 'key'});
    });

    test('and the check itself can fail', () {
      const counterfeit = '''
        const MonetaLineChart({
          required this.income,
          this.rightAxisMax,
          super.key,
        });
      ''';
      final start = counterfeit.indexOf('const MonetaLineChart({');
      final block = counterfeit.substring(
        start,
        counterfeit.indexOf('});', start),
      );
      expect(
        RegExp(
          r'(?:this|super)\.(\w+)',
        ).allMatches(block).map((m) => m.group(1)!).toSet(),
        {'income', 'rightAxisMax', 'key'},
      );
    });

    test('the maximum comes from both series together', () {
      final chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: series('Income', [10, 20]),
        expenses: series('Expenses', [5, 40]),
      );
      expect(
        chart.axisMaxMinor,
        40 * 1000000,
        reason: 'a per-series maximum is a dual axis by another name',
      );
    });

    testWidgets('a narrow band well above zero still starts at zero', (
      tester,
    ) async {
      // Both series between 30 and 34: the lines sit in the upper part of the
      // plot and the axis labels state the range, which is what makes the gap
      // below them read as information.
      await pumpChart(
        tester,
        income: series('Income', [33, 34, 33]),
        expenses: series('Expenses', [30, 31, 30]),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
    });
  });

  group('what the plot paints', () {
    testWidgets('gridlines first, then the two series', (tester) async {
      await pumpChart(tester);
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paints
          ..line(color: colors.borderSubtle)
          ..line(color: colors.borderSubtle)
          ..line(color: colors.borderSubtle)
          ..path(color: colors.chart.base(1))
          ..circle(color: colors.canvas)
          ..circle(color: colors.chart.base(1))
          ..path(color: colors.chart.base(3))
          ..circle(color: colors.canvas)
          ..circle(color: colors.chart.base(3)),
      );
    });

    testWidgets('three gridlines, at the quarters', (tester) async {
      await pumpChart(tester);
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawLine, MonetaLineChart.gridlineCount),
      );
    });

    testWidgets('the series are drawn at the authored 2px', (tester) async {
      await pumpChart(tester);
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paints
          ..line()
          ..line()
          ..line()
          ..path(strokeWidth: MonetaLineChart.strokeWidth),
      );
    });

    testWidgets('each series ends in a marker over a larger surface ring', (
      tester,
    ) async {
      await pumpChart(tester);
      // Outer 9px ring, 7px coloured disc inside it — the values `48:84`'s
      // exported SVG carries, after a fidelity pass corrected a 9px disc with
      // an 11px backing.
      const ring = MonetaLineChart.markerSize / 2;
      const mark = MonetaLineChart.markerDiscSize / 2;
      // Radii asserted, not just the count: a ring drawn at radius zero is no
      // ring at all, and counting four circles passes for it. The ring is what
      // keeps two marks separable where they overlap.
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paints
          ..circle(color: colors.canvas, radius: ring)
          ..circle(color: colors.chart.base(1), radius: mark)
          ..circle(color: colors.canvas, radius: ring)
          ..circle(color: colors.chart.base(3), radius: mark),
      );
      expect(ring, greaterThan(mark));
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawCircle, 4),
      );
    });
  });

  group('the legend is mandatory and names both series', () {
    testWidgets('one entry per series, each with a line swatch', (
      tester,
    ) async {
      await pumpChart(tester);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
    });

    testWidgets('the swatch is a 14x3 line, not a dot', (tester) async {
      await pumpChart(tester);
      final swatches = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where(
            (box) =>
                box.width == MonetaLineChart.legendSwatchWidth &&
                box.height == MonetaLineChart.legendSwatchHeight,
          );
      expect(
        swatches,
        hasLength(2),
        reason: 'these series are lines, so their swatches are lines',
      );
    });

    testWidgets('identity does not rest on hue alone', (tester) async {
      // The two colours differ AND both entries are named. A chart that
      // dropped the names would still pass a colour assertion.
      await pumpChart(tester);
      expect(
        colors.chart.base(1),
        isNot(colors.chart.base(3)),
      );
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
    });
  });

  group('boundary inputs', () {
    testWidgets('both series empty: gridlines and labels, no line', (
      tester,
    ) async {
      await pumpChart(
        tester,
        income: series('Income', []),
        expenses: series('Expenses', []),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawLine, MonetaLineChart.gridlineCount),
      );
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawPath, 0),
      );
      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('a single point draws a marker and no segment', (tester) async {
      await pumpChart(
        tester,
        income: series('Income', [12]),
        expenses: series('Expenses', [8]),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawPath, 0),
      );
      expect(
        find.byKey(MonetaLineChart.plotKey),
        paintsExactlyCountTimes(#drawCircle, 4),
      );
    });

    testWidgets('all zeros: no division by zero, both on the baseline', (
      tester,
    ) async {
      await pumpChart(
        tester,
        income: series('Income', [0, 0, 0]),
        expenses: series('Expenses', [0, 0, 0]),
      );
      expect(tester.takeException(), isNull);
      final chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: series('Income', [0, 0, 0]),
        expenses: series('Expenses', [0, 0, 0]),
      );
      expect(
        chart.axisMaxMinor,
        1,
        reason: 'an axis maximum of zero is a division by zero',
      );
    });

    testWidgets('very large values stay inside the plot', (tester) async {
      const huge = 1 << 50;
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: MonetaLineChart(
            title: 'Cash flow',
            subtitle: 'big',
            income: LineSeries(
              label: 'Income',
              points: [Money(huge, vnd), Money(huge ~/ 2, vnd)],
            ),
            expenses: LineSeries(
              label: 'Expenses',
              points: [Money(huge ~/ 3, vnd), Money(huge ~/ 4, vnd)],
            ),
          ),
        ),
        surfaceSize: const Size(393, 500),
      );
      expect(tester.takeException(), isNull);
      final plot = tester.getRect(find.byKey(MonetaLineChart.plotKey));
      expect(plot.height, MonetaLineChart.plotHeight);
    });

    test('series of unequal length are reported, not plotted', () {
      expect(
        () => MonetaLineChart(
          title: 't',
          subtitle: 's',
          income: series('Income', [1, 2, 3]),
          expenses: series('Expenses', [1, 2]),
        ).hasEqualLengths,
        returnsNormally,
      );

      final chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: series('Income', [1, 2, 3]),
        expenses: series('Expenses', [1, 2]),
      );
      expect(chart.hasEqualLengths, isFalse);
    });

    testWidgets('and unequal lengths throw rather than misalign', (
      tester,
    ) async {
      await pumpChart(
        tester,
        income: series('Income', [1, 2, 3]),
        expenses: series('Expenses', [1, 2]),
      );
      expect(
        tester.takeException(),
        isA<ArgumentError>(),
        reason: 'plotting them anyway would put January under February',
      );
    });

    test('mixed currencies are reported', () {
      const chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: LineSeries(label: 'Income', points: [Money(1000, vnd)]),
        expenses: LineSeries(
          label: 'Expenses',
          points: [Money(1000, Currency.usd)],
        ),
      );
      expect(() => chart.currency, throwsArgumentError);
    });

    test('a negative value is clamped to the baseline, not below it', () {
      // Asserted on `fractionsOf`, which is the only place a value becomes a
      // position. The previous version of this test compared the plot's height
      // to itself and asserted `math.min(0, -5) == -5` — a tautology that let
      // a mutation removing the clamp survive.
      final chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: series('Income', [10, -5, 10]),
        expenses: series('Expenses', [4, 4, 4]),
      );

      final fractions = chart.fractionsOf(chart.income.points);
      expect(fractions[1], 0, reason: 'the negative month must sit at zero');
      expect(fractions, everyElement(greaterThanOrEqualTo(0)));
      expect(
        fractions,
        everyElement(lessThanOrEqualTo(1)),
        reason: 'a fraction above one is a point above the plot',
      );
      expect(fractions[0], fractions[2]);
    });

    test('fractions are measured from zero, not from the minimum', () {
      final chart = MonetaLineChart(
        title: 't',
        subtitle: 's',
        income: series('Income', [20, 40]),
        expenses: series('Expenses', [10, 10]),
      );
      // 40 is the maximum, so 20 lands at exactly half height. If the axis
      // started at the data's minimum, 20 would be at zero.
      expect(chart.fractionsOf(chart.income.points), [0.5, 1.0]);
      expect(chart.fractionsOf(chart.expenses.points), [0.25, 0.25]);
    });
  });
}
