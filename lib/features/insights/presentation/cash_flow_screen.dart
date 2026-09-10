import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';
import 'package:moneta/design_system/organisms/line_chart.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';
import 'package:moneta/features/insights/presentation/insights_card.dart';
import 'package:moneta/features/insights/presentation/insights_period_switcher.dart';

/// 07.02 — income against expenses over the period.
///
/// From Figma node `77:294`. One shared axis, always from zero: annotation
/// `77:430` — *"ONE y-axis only. Income and expenses share a scale on purpose
/// — a dual-axis chart would let the two lines cross wherever the scales were
/// chosen to make them cross."*
class CashFlowScreen extends StatelessWidget {
  /// Creates the screen.
  const CashFlowScreen({
    required this.summary,
    required this.onPeriodChanged,
    this.onBack,
    super.key,
  });

  /// The figures for the selected period.
  final InsightsSummary summary;

  /// Called with the period chosen.
  final ValueChanged<InsightsPeriod> onPeriodChanged;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// Content inset, from `77:326`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Gap between the two tiles, from `77:359`: 12.
  static const double tileGap = MonetaSpacing.spaceMd;

  /// Key on the empty state.
  static const Key emptyKey = Key('CashFlow.empty');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final months = summary.monthly;
    // Newest first, as `77:383`-`77:393` list them. Reversed rather than
    // re-sorted: the series must stay oldest-first for the chart, and one list
    // sorted two ways is one list that can disagree with itself.
    final newestFirst = months.reversed.toList();

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Cash flow',
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
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
                  InsightsPeriodSwitcher(
                    selected: summary.period,
                    onChanged: onPeriodChanged,
                  ),
                  const SizedBox(height: MonetaSpacing.spaceMd),
                  if (months.isEmpty)
                    const EmptyState(
                      key: emptyKey,
                      icon: MonetaIconName.trendingUp,
                      title: 'No cash flow yet',
                      message:
                          'Record income and spending and the trend shows up '
                          'here.',
                    )
                  else ...[
                    InsightsCard(
                      child: MonetaLineChart(
                        title: 'Cash flow',
                        subtitle:
                            'Income vs expenses · '
                            '${summary.period.longLabel.toLowerCase()}',
                        income: LineSeries(
                          label: 'Income',
                          points: [for (final m in months) m.income],
                        ),
                        expenses: LineSeries(
                          label: 'Expenses',
                          points: [for (final m in months) m.expenses],
                        ),
                      ),
                    ),
                    const SizedBox(height: MonetaSpacing.spaceMd),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Income',
                            value: summary.totalIncome,
                            delta: StatDelta.up,
                            deltaLabel: summary.period.longLabel,
                          ),
                        ),
                        const SizedBox(width: tileGap),
                        Expanded(
                          child: StatTile(
                            label: 'Expenses',
                            value: summary.totalExpenses,
                            // `down` for spending, per deviation 12's rule:
                            // delta colour follows MEANING, not sign.
                            delta: StatDelta.down,
                            deltaLabel: summary.period.longLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MonetaSpacing.spaceMd),
                    const SectionHeader(title: 'By month'),
                    InsightsCard(
                      child: Column(
                        children: [
                          for (final month in newestFirst)
                            _MonthRow(flow: month),
                        ],
                      ),
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

/// One month row from `77:383`: the month, its net, and its split.
class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.flow});

  final MonthlyFlow flow;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final isPositive = !flow.net.isNegative;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MonetaSpacing.spaceSm),
      // Flex 3:4, from `77:383`: the month is 136 of the 321 row and the
      // figures 177. Both flexible and both ellipsised, because the split line
      // ("32,000,000 ₫ in · 16,280,000 ₫ out") is wider than any phone at a
      // realistic salary — it overflowed by 79px before this.
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              DateFormat.yMMMM().format(flow.month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text.titleMd.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: MonetaSpacing.spaceSm),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  flow.net.format(showSign: true),
                  maxLines: 1,
                  style: theme.text.amountMd.copyWith(
                    color: isPositive
                        ? theme.colors.income
                        : theme.colors.expense,
                  ),
                ),
                Text(
                  '${flow.income.format()} in · ${flow.expenses.format()} out',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.captionMd.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
