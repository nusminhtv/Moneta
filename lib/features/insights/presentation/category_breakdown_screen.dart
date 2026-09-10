import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/domain/insights_summary.dart';
import 'package:moneta/features/insights/presentation/insights_card.dart';
import 'package:moneta/features/insights/presentation/insights_period_switcher.dart';

/// 07.03 — spend by category as ranked bars.
///
/// From Figma node `77:440`. Annotation `77:587` forbids the component this
/// screen looks like it wants:
///
/// > *"ProgressBar is reused as the bar mark rather than adding a
/// > HorizontalBarChart component; one series means one hue, so every bar is
/// > the same colour and rank is carried by length and order."*
///
/// So there is no painter here, every bar is `chart/1` — [barSlot], which is
/// also `MonetaProgressBar.series`' default — and the bars are drawn
/// from each category's share of the **largest** — not of the total — so the
/// first bar is full and rank reads as length. `80:407` confirms the hue:
/// every fill on the frame is `chart/1`.
class CategoryBreakdownScreen extends StatelessWidget {
  /// Creates the screen.
  const CategoryBreakdownScreen({
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

  /// The one hue every bar is drawn in, from `80:407`: `chart/1`.
  static const ChartSlot barSlot = ChartSlot.slot1;

  /// Content inset, from `77:460`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Key on the empty state.
  static const Key emptyKey = Key('CategoryBreakdown.empty');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'By category',
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
                  if (summary.hasNoSpending)
                    const EmptyState(
                      key: emptyKey,
                      icon: MonetaIconName.pieChart,
                      title: 'Nothing to rank yet',
                      message:
                          'Spend something in this period and the categories '
                          'line up here, largest first.',
                    )
                  else
                    InsightsCard(
                      child: Column(
                        children: [
                          for (final spend in summary.byCategory)
                            _CategoryBar(
                              spend: spend,
                              share: summary.shareOf(spend),
                              barFraction: summary.barFractionOf(spend),
                            ),
                        ],
                      ),
                    ),
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

/// One row from `77:471`: icon, name, share, amount, then the bar.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.spend,
    required this.share,
    required this.barFraction,
  });

  final CategorySpend spend;

  /// Share of the period's **total**, which is what the percentage label reads.
  final double share;

  /// Share of the **largest** category, which is what the bar's length reads.
  final double barFraction;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MonetaSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryIcon(
                category: spend.category,
                size: CategoryIconSize.sm,
              ),
              const SizedBox(width: MonetaSpacing.spaceSm),
              Expanded(
                child: Text(
                  spend.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.bodyMd.copyWith(
                    color: theme.colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: MonetaSpacing.spaceSm),
              // The percentage is share of TOTAL — the number a reader wants —
              // while the bar below is share of the largest. They differ, and
              // the screen shows both on purpose.
              Text(
                '${(share * 100).round()}%',
                maxLines: 1,
                style: theme.text.labelSm.copyWith(
                  color: theme.colors.textTertiary,
                ),
              ),
              const SizedBox(width: MonetaSpacing.spaceSm),
              Text(
                spend.amount.format(),
                maxLines: 1,
                style: theme.text.labelMd.copyWith(
                  color: theme.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MonetaSpacing.spaceSm),
          MonetaProgressBar.series(
            fraction: barFraction,
            size: MonetaProgressBarSize.sm,
            semanticLabel:
                '${spend.category.label}, '
                '${(share * 100).round()}% of spending',
          ),
        ],
      ),
    );
  }
}
