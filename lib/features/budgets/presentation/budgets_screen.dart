import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';

/// All budgets for one period, worst first — Figma `66:91`, empty `66:277`.
///
/// Annotation `04.01`: *"The ring answers 'am I okay overall' before the list
/// answers 'where exactly'."*
class BudgetsScreen extends StatelessWidget {
  /// Creates the overview.
  const BudgetsScreen({
    required this.progress,
    required this.period,
    required this.currency,
    this.onPeriodChanged,
    this.onAdd,
    this.onOpen,
    super.key,
  });

  /// Every budget with its computed progress, already ranked.
  final List<BudgetProgress> progress;

  /// Which period the switcher is showing.
  final BudgetPeriod period;

  /// The wallet's currency, for the totals when there is nothing to add up.
  final Currency currency;

  /// Called with the newly selected period.
  final ValueChanged<BudgetPeriod>? onPeriodChanged;

  /// Called from the section header's "Add" and from the empty state.
  final VoidCallback? onAdd;

  /// Called with a budget's id when its card is activated.
  final ValueChanged<String>? onOpen;

  /// Total spend over total limit across [entries].
  ///
  /// Not the average of their fractions. Averaging treats a 50,000 ₫ budget at
  /// 100% and a 5,000,000 ₫ budget at 10% as equally weighted, which answers a
  /// question nobody asked.
  static double overallFraction(List<BudgetProgress> entries) {
    var spent = 0;
    var limit = 0;
    for (final entry in entries) {
      spent += entry.spent.minorUnits;
      limit += entry.effectiveLimit.minorUnits;
    }
    if (limit == 0) return 0;
    return spent / limit;
  }

  /// Total spend across [entries], in [fallback]'s currency when empty.
  static Money totalSpent(List<BudgetProgress> entries, Currency fallback) =>
      Money(
        entries.fold(0, (sum, e) => sum + e.spent.minorUnits),
        entries.isEmpty ? fallback : entries.first.spent.currency,
      );

  /// Total effective limit across [entries].
  static Money totalLimit(List<BudgetProgress> entries, Currency fallback) =>
      Money(
        entries.fold(0, (sum, e) => sum + e.effectiveLimit.minorUnits),
        entries.isEmpty ? fallback : entries.first.effectiveLimit.currency,
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MonetaAppBar(title: 'Budgets'),
          Expanded(
            child: progress.isEmpty ? _empty(context) : _list(context),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      MonetaSpacing.spaceLg,
      MonetaSpacing.spaceXs,
      MonetaSpacing.spaceLg,
      MonetaSpacing.spaceBase,
    ),
    children: [
      EmptyState(
        icon: MonetaIconName.target,
        title: 'No budgets yet',
        message:
            'A budget turns "am I spending too much" into a number. Start with '
            'the category you spend most on.',
        actionLabel: 'Create a budget',
        onAction: onAdd,
      ),
    ],
  );

  Widget _list(BuildContext context) {
    final spent = totalSpent(progress, currency);
    final limit = totalLimit(progress, currency);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MonetaSpacing.spaceLg,
        MonetaSpacing.spaceXs,
        MonetaSpacing.spaceLg,
        MonetaSpacing.spaceBase,
      ),
      children: [
        MonetaSegmentedControl(
          labels: [for (final p in BudgetPeriod.values) p.label],
          selectedIndex: BudgetPeriod.values.indexOf(period),
          onChanged: onPeriodChanged == null
              ? null
              : (i) => onPeriodChanged!(BudgetPeriod.values[i]),
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        _TotalCard(
          fraction: overallFraction(progress),
          spent: spent,
          limit: limit,
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        SectionHeader(
          title: 'By category',
          actionLabel: 'Add',
          onAction: onAdd,
        ),
        for (final entry in progress) ...[
          BudgetCard(
            key: ValueKey(entry.budget.id),
            category: entry.budget.category,
            spent: entry.spent,
            limit: entry.effectiveLimit,
            note: noteFor(entry),
            nearLimitThreshold: entry.budget.alertThreshold,
            onTap: onOpen == null ? null : () => onOpen!(entry.budget.id),
          ),
          const SizedBox(height: MonetaSpacing.spaceMd),
        ],
      ],
    );
  }

  /// The card's supporting line: how much used, and how long is left.
  static String noteFor(BudgetProgress entry) {
    final percent = (entry.fraction * 100).round();
    final days = entry.daysRemaining;
    final dayWord = days == 1 ? 'day' : 'days';
    return '$percent% used · $days $dayWord left';
  }
}

/// The ring and the totals above the list, a local frame on `66:124`.
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.fraction,
    required this.spent,
    required this.limit,
  });

  final double fraction;
  final Money spent;
  final Money limit;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surfaceRaised,
        borderRadius: theme.radii.borderLg,
        border: Border.all(color: theme.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MonetaSpacing.spaceBase),
        child: Row(
          children: [
            MonetaCircularProgress(
              fraction: fraction,
              semanticLabel: 'Total spent against all budgets',
            ),
            const SizedBox(width: MonetaSpacing.spaceBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spent this period',
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceXs),
                  Text(
                    spent.format(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.headingH1.copyWith(
                      color: theme.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.space2xs),
                  Text(
                    'of ${limit.format()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
