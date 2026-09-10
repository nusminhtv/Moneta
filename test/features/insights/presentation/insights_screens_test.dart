import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/donut_chart.dart';
import 'package:moneta/design_system/organisms/line_chart.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/insights/domain/insights_entry.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';
import 'package:moneta/features/insights/presentation/cash_flow_screen.dart';
import 'package:moneta/features/insights/presentation/category_breakdown_screen.dart';
import 'package:moneta/features/insights/presentation/insights_overview_screen.dart';
import 'package:moneta/features/insights/presentation/period_picker_sheet.dart';

import '../../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;
  const colors = MonetaColors.dark();
  final now = DateTime.utc(2026, 9, 17, 14, 30);

  InsightsEntry expense(
    String id,
    int minor,
    SpendCategory category,
    DateTime at, {
    String? title,
  }) => InsightsEntry(
    id: id,
    title: title ?? category.label,
    category: category,
    direction: TransactionDirection.expense,
    amount: Money(minor, vnd),
    occurredAt: at,
  );

  InsightsSummary summarise(
    List<InsightsEntry> entries, {
    InsightsPeriod period = InsightsPeriod.thisMonth,
  }) => InsightsSummary.of(
    entries: entries,
    period: period,
    now: now,
    currency: vnd,
  );

  final populated = summarise([
    expense(
      'a',
      6760000,
      SpendCategory.food,
      DateTime.utc(2026, 9, 2),
      title: 'Highlands Coffee',
    ),
    expense(
      'b',
      4420000,
      SpendCategory.transport,
      DateTime.utc(2026, 9, 3),
      title: 'Grab',
    ),
    expense(
      'c',
      3900000,
      SpendCategory.shopping,
      DateTime.utc(2026, 9, 4),
      title: 'Uniqlo',
    ),
    expense('d', 1200000, SpendCategory.bills, DateTime.utc(2026, 9, 5)),
    InsightsEntry(
      id: 'i',
      title: 'Salary',
      category: SpendCategory.salary,
      direction: TransactionDirection.income,
      amount: const Money(32000000, vnd),
      occurredAt: DateTime.utc(2026, 9, 6),
    ),
  ]);

  final empty = summarise([]);

  group('07.01 overview', () {
    testWidgets('shows the donut and the three largest expenses', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      expect(find.byType(DonutChart), findsOneWidget);
      expect(find.byKey(InsightsOverviewScreen.emptyKey), findsNothing);

      final rows = tester
          .widgetList<TransactionRow>(find.byType(TransactionRow))
          .toList();
      expect(rows, hasLength(3));
      expect(
        rows.map((r) => r.title),
        ['Highlands Coffee', 'Grab', 'Uniqlo'],
        reason: 'the three largest, largest first',
      );
    });

    testWidgets("the donut's centre reports the period total", (tester) async {
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      final donut = tester.widget<DonutChart>(find.byType(DonutChart));
      expect(donut.total, populated.totalExpenses);
      expect(
        donut.total,
        const Money(16280000, vnd),
        reason: 'income must not be counted as spending',
      );
      expect(donut.periodLabel, InsightsPeriod.thisMonth.longLabel);
    });

    testWidgets('each category keeps its own chart slot', (tester) async {
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      final donut = tester.widget<DonutChart>(find.byType(DonutChart));
      // Food is `chart/7` in `SpendCategory`, which is exactly what `47:62`'s
      // legend uses. The slot comes from the category, not from the rank.
      final food = donut.categories.firstWhere(
        (c) => c.label == 'Food & drink',
      );
      expect(food.slot.paletteSlot, SpendCategory.food.chartSlot);
      expect(food.slot.colorIn(colors), colors.chart.base(7));
    });

    testWidgets('an empty period shows an EmptyState and NO chart', (
      tester,
    ) async {
      // 77:291: "empty period shows an EmptyState instead of a 0% donut".
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: empty, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 900),
      );

      expect(find.byKey(InsightsOverviewScreen.emptyKey), findsOneWidget);
      expect(find.byType(DonutChart), findsNothing);
      expect(find.byType(TransactionRow), findsNothing);
    });

    testWidgets('income with no spending still reads as empty', (tester) async {
      final incomeOnly = summarise([
        InsightsEntry(
          id: 'i',
          title: 'Salary',
          category: SpendCategory.salary,
          direction: TransactionDirection.income,
          amount: const Money(32000000, vnd),
          occurredAt: DateTime.utc(2026, 9, 6),
        ),
      ]);
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: incomeOnly, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 900),
      );
      expect(find.byType(DonutChart), findsNothing);
      expect(find.byKey(InsightsOverviewScreen.emptyKey), findsOneWidget);
    });

    testWidgets('all four periods are offered and one is selected', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        InsightsOverviewScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      final control = tester.widget<MonetaSegmentedControl>(
        find.byType(MonetaSegmentedControl),
      );
      expect(control.labels, ['Month', '3M', '6M', 'Year']);
      expect(control.selectedIndex, 0);
    });

    testWidgets('the period changes the data, not the layout', (tester) async {
      // 77:291. The same sections in the same order for every period.
      final seen = <String>[];
      for (final period in InsightsPeriod.values) {
        await pumpMonetaWidget(
          tester,
          InsightsOverviewScreen(
            summary: summarise([
              expense(
                'a',
                6760000,
                SpendCategory.food,
                DateTime.utc(2026, 9, 2),
              ),
            ], period: period),
            onPeriodChanged: (_) {},
          ),
          surfaceSize: const Size(393, 1600),
        );
        // Joined, not a List: `List` compares by identity, so `toSet()` on
        // four equal lists gives four entries and this assertion could not
        // fail. It did not, until this line.
        seen.add(
          [
            if (find.byType(MonetaSegmentedControl).evaluate().isNotEmpty)
              'switcher',
            if (find.byType(DonutChart).evaluate().isNotEmpty) 'donut',
            if (find.byType(TransactionRow).evaluate().isNotEmpty) 'rows',
          ].join(','),
        );
      }
      expect(seen, hasLength(InsightsPeriod.values.length));
      expect(seen.toSet(), hasLength(1), reason: 'the layout moved: $seen');
      expect(seen.first, 'switcher,donut,rows');
    });
  });

  group('07.02 cash flow', () {
    testWidgets('both series have one point per month and equal length', (
      tester,
    ) async {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 7, 4)),
        expense('c', 300000, SpendCategory.food, DateTime.utc(2026, 9, 4)),
      ], period: InsightsPeriod.threeMonths);

      await pumpMonetaWidget(
        tester,
        CashFlowScreen(summary: summary, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      final chart = tester.widget<MonetaLineChart>(
        find.byType(MonetaLineChart),
      );
      expect(chart.income.points, hasLength(3));
      expect(chart.expenses.points, hasLength(3));
      expect(
        chart.hasEqualLengths,
        isTrue,
        reason: 'unequal series would put July under August',
      );
      expect(
        chart.expenses.points[1],
        const Money.zero(vnd),
        reason: 'August was silent and must still be a point',
      );
    });

    testWidgets('the months are listed newest first', (tester) async {
      final summary = summarise([
        expense('a', 100000, SpendCategory.food, DateTime.utc(2026, 7, 4)),
        expense('c', 300000, SpendCategory.food, DateTime.utc(2026, 9, 4)),
      ], period: InsightsPeriod.threeMonths);

      await pumpMonetaWidget(
        tester,
        CashFlowScreen(summary: summary, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );

      final september = tester.getRect(find.textContaining('September'));
      final july = tester.getRect(find.textContaining('July'));
      expect(september.top, lessThan(july.top));
    });

    testWidgets('the tiles report the period totals', (tester) async {
      await pumpMonetaWidget(
        tester,
        CashFlowScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1600),
      );
      expect(tester.takeException(), isNull, reason: 'nothing overflowed');
      expect(find.text(populated.totalIncome.format()), findsWidgets);
      expect(find.text(populated.totalExpenses.format()), findsWidgets);
    });
  });

  group('07.03 category breakdown', () {
    testWidgets('largest first, first bar full, one hue', (tester) async {
      await pumpMonetaWidget(
        tester,
        CategoryBreakdownScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1400),
      );

      final bars = tester
          .widgetList<MonetaProgressBar>(find.byType(MonetaProgressBar))
          .toList();
      expect(bars, hasLength(populated.byCategory.length));

      // Rank by length: the first is full and the rest descend.
      expect(bars.first.fraction, 1.0);
      for (var i = 1; i < bars.length; i++) {
        expect(bars[i].fraction, lessThan(bars[i - 1].fraction));
      }

      // One series, one hue — `77:587`. Every bar the same slot, which the
      // fraction-derived constructor could not give: a full bar would be the
      // near-limit warning colour.
      expect(
        bars.map((b) => b.slot).toSet(),
        {CategoryBreakdownScreen.barSlot},
      );
    });

    testWidgets('the percentage is share of total, not of the largest', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        CategoryBreakdownScreen(summary: populated, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 1400),
      );
      // Food is 6,760,000 of 16,280,000 = 42% of the total, and 100% of the
      // largest. The label must read the former.
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
    });

    test('declares no painter of its own', () {
      // `77:587` forbids the component this screen looks like it wants.
      final source = File(
        'lib/features/insights/presentation/category_breakdown_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('CustomPainter')));
      expect(source, isNot(contains('CustomPaint')));
      expect(source, contains('MonetaProgressBar.series'));
    });

    testWidgets('an empty period shows an EmptyState', (tester) async {
      await pumpMonetaWidget(
        tester,
        CategoryBreakdownScreen(summary: empty, onPeriodChanged: (_) {}),
        surfaceSize: const Size(393, 900),
      );
      expect(find.byKey(CategoryBreakdownScreen.emptyKey), findsOneWidget);
      expect(find.byType(MonetaProgressBar), findsNothing);
    });
  });

  group('07.05 period picker', () {
    testWidgets('the active period is the selected option', (tester) async {
      await pumpMonetaWidget(
        tester,
        PeriodPickerSheet(
          selected: InsightsPeriod.sixMonths,
          onSelected: (_) {},
        ),
        surfaceSize: const Size(393, 900),
      );

      expect(find.text('Last 6 months'), findsOneWidget);
      for (final period in InsightsPeriod.values) {
        expect(find.text(period.longLabel), findsOneWidget);
      }
    });

    testWidgets('choosing an option reports it', (tester) async {
      final chosen = <InsightsPeriod>[];
      await pumpMonetaWidget(
        tester,
        PeriodPickerSheet(
          selected: InsightsPeriod.thisMonth,
          onSelected: chosen.add,
        ),
        surfaceSize: const Size(393, 900),
      );

      await tester.tap(find.text('This year'));
      await tester.pump();
      expect(chosen, [InsightsPeriod.year]);
    });
  });
}
