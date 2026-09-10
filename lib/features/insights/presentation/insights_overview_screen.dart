import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/donut_chart.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';
import 'package:moneta/features/insights/presentation/insights_slot.dart';

/// 07.01 — where the money went this period.
///
/// From Figma node `77:2`. Annotation `77:287`: *"Where the money went this
/// period. The donut answers the shape of spending; top merchants answer who
/// took it."*
///
/// Presentational: figures in, callbacks out, no provider read. `lib/app` wires
/// it, which is the pattern `HomeScreen` already follows and the only one
/// `tool/check_architecture.dart` allows for a screen that needs the router.
class InsightsOverviewScreen extends StatelessWidget {
  /// Creates the screen.
  const InsightsOverviewScreen({
    required this.summary,
    required this.onPeriodChanged,
    this.onOpenPeriodPicker,
    this.onOpenTransaction,
    super.key,
  });

  /// The figures for the selected period.
  final InsightsSummary summary;

  /// Called with the period the user picked.
  final ValueChanged<InsightsPeriod> onPeriodChanged;

  /// Opens `07.05`'s sheet, from the section header's action.
  final VoidCallback? onOpenPeriodPicker;

  /// Opens one of the top expenses.
  final ValueChanged<String>? onOpenTransaction;

  /// Content column width, from `77:31`: 353 inside a 393 frame.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Key on the empty state, so a test can tell it from the chart.
  static const Key emptyKey = Key('InsightsOverview.empty');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Insights',
            actions: [
              (
                icon: MonetaIconName.pieChart,
                semanticLabel: 'Choose a period',
                onPressed: onOpenPeriodPicker,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: MonetaSpacing.spaceXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PeriodSwitcher(
                    selected: summary.period,
                    onChanged: onPeriodChanged,
                  ),
                  const SizedBox(height: MonetaSpacing.spaceMd),
                  // `77:291`: an empty period shows an EmptyState instead of a
                  // 0% donut. A ring with no segments and a legend with no rows
                  // is a chart claiming to describe data that is not there.
                  if (summary.hasNoSpending)
                    const EmptyState(
                      key: emptyKey,
                      icon: MonetaIconName.pieChart,
                      title: 'Nothing spent yet',
                      message:
                          'Once this period has spending in it, the breakdown '
                          'shows up here.',
                    )
                  else ...[
                    _Card(
                      child: DonutChart(
                        categories: [
                          for (final spend in summary.byCategory)
                            ChartSeries(
                              label: spend.category.label,
                              amount: spend.amount,
                              slot: slotFor(spend.category),
                            ),
                        ],
                        centreLabel: 'Total spent',
                        periodLabel: summary.period.longLabel,
                      ),
                    ),
                    const SizedBox(height: MonetaSpacing.spaceMd),
                    SectionHeader(
                      title: 'Top spending',
                      actionLabel: onOpenPeriodPicker == null ? null : 'Period',
                      onAction: onOpenPeriodPicker,
                    ),
                    for (final expense in summary.topExpenses)
                      TransactionRow(
                        title: expense.title,
                        amount: expense.amount,
                        direction: expense.direction,
                        category: expense.category,
                        occurredAt: expense.occurredAt,
                        onTap: onOpenTransaction == null
                            ? null
                            : () => onOpenTransaction!(expense.id),
                      ),
                  ],
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four-way switcher from `77:32`.
///
/// Its own widget so all four Insights screens use one implementation —
/// `77:291` says the period changes the data and not the layout, and three
/// copies of a switcher is three chances for one of them to drift.
class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.selected, required this.onChanged});

  final InsightsPeriod selected;
  final ValueChanged<InsightsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return MonetaSegmentedControl(
      labels: [for (final period in InsightsPeriod.values) period.label],
      selectedIndex: InsightsPeriod.values.indexOf(selected),
      onChanged: (index) => onChanged(InsightsPeriod.values[index]),
    );
  }
}

/// The card `77:41` wraps the chart in.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  /// Inset inside the card, from `77:41`: 12.
  static const double inset = MonetaSpacing.spaceMd;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: theme.radii.borderLg,
        border: Border.all(color: theme.colors.borderSubtle),
      ),
      child: Padding(padding: const EdgeInsets.all(inset), child: child),
    );
  }
}
