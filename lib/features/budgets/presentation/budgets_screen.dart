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
import 'package:moneta/features/budgets/domain/budget_progress.dart';

/// All budgets for one period, worst first — Figma `66:91`, empty `66:277`.
///
/// Annotation `04.01`: *"The ring answers 'am I okay overall' before the list
/// answers 'where exactly'."*
class BudgetsScreen extends StatelessWidget {
  /// Creates the overview.
  const BudgetsScreen({
    required this.progress,
    required this.periodLabels,
    required this.selectedPeriod,
    required this.currency,
    required this.now,
    this.hasAnyBudget = true,
    this.onPeriodChanged,
    this.onAdd,
    this.onOpen,
    super.key,
  });

  /// Every budget with its computed progress, already ranked.
  final List<BudgetProgress> progress;

  /// The three segment labels, newest last — `66:118`, `66:120`, `66:122`.
  final List<String> periodLabels;

  /// Which segment is selected, as an index into [periodLabels].
  final int selectedPeriod;

  /// Whether the user has any budget at all, in any period.
  ///
  /// Distinct from `progress.isEmpty` on purpose. Looking at a period before a
  /// budget existed yields no cards, and showing "No budgets yet" there tells
  /// someone with three budgets that they have none.
  final bool hasAnyBudget;

  /// The wallet's currency, for the totals when there is nothing to add up.
  final Currency currency;

  /// The real current instant, so a finished period is not told it has days
  /// left. Injected rather than read, per the project's clock rule.
  final DateTime now;

  /// Called with the newly selected segment index.
  final ValueChanged<int>? onPeriodChanged;

  /// Called from the section header's "Add" and from the empty state.
  final VoidCallback? onAdd;

  /// Called with a budget's id when its card is activated.
  final ValueChanged<String>? onOpen;

  /// Total spend over total limit across [entries].
  ///
  /// Not the average of their fractions. Averaging treats a 50,000 ₫ budget at
  /// 100% and a 5,000,000 ₫ budget at 10% as equally weighted, which answers a
  /// question nobody asked.
  static double overallFraction(
    List<BudgetProgress> entries, [
    Currency? only,
  ]) {
    var spent = 0;
    var limit = 0;
    for (final entry in entries) {
      if (only != null && entry.spent.currency != only) continue;
      spent += entry.spent.minorUnits;
      limit += entry.effectiveLimit.minorUnits;
    }
    if (limit == 0) return 0;
    return spent / limit;
  }

  /// Total spend across [entries], in [fallback]'s currency when empty.
  /// Skips anything outside [fallback]'s currency, as Home does.
  ///
  /// This used to sum `minorUnits` across every entry and label the result with
  /// `entries.first`'s currency, so a USD budget beside a VND one produced a
  /// total in neither. `Money.+` would have caught it; adding the raw integers
  /// bypassed the guard.
  static Money totalSpent(List<BudgetProgress> entries, Currency fallback) =>
      Money(
        entries
            .where((e) => e.spent.currency == fallback)
            .fold(0, (sum, e) => sum + e.spent.minorUnits),
        fallback,
      );

  /// Total effective limit across [entries].
  /// Skips anything outside [fallback]'s currency, as [totalSpent] does.
  static Money totalLimit(List<BudgetProgress> entries, Currency fallback) =>
      Money(
        entries
            .where((e) => e.effectiveLimit.currency == fallback)
            .fold(0, (sum, e) => sum + e.effectiveLimit.minorUnits),
        fallback,
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
            child: switch ((progress.isEmpty, hasAnyBudget)) {
              (false, _) => _list(context),
              (true, false) => _empty(context),
              (true, true) => _nothingThisPeriod(context),
            },
          ),
        ],
      ),
    );
  }

  /// Budgets exist, but none of them existed in the period being looked at.
  ///
  /// Not `66:277`. That frame is the first-run empty state and its action
  /// creates a budget, which is the wrong offer to someone who already has
  /// three and has simply scrolled back before they existed. No node authors
  /// this state; it is composed from `EmptyState` with no action, the form
  /// `57:935` establishes as legitimate when there is nothing to do.
  Widget _nothingThisPeriod(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      MonetaSpacing.spaceLg,
      MonetaSpacing.spaceXs,
      MonetaSpacing.spaceLg,
      MonetaSpacing.spaceBase,
    ),
    children: [
      MonetaSegmentedControl(
        labels: periodLabels,
        selectedIndex: selectedPeriod,
        onChanged: onPeriodChanged,
      ),
      const SizedBox(height: MonetaSpacing.spaceMd),
      const EmptyState(
        icon: MonetaIconName.calendar,
        title: 'Nothing to show for this period',
        message:
            'Your budgets started later than this. Pick a more recent '
            'period to see them.',
      ),
    ],
  );

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
          labels: periodLabels,
          selectedIndex: selectedPeriod,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        _TotalCard(
          fraction: overallFraction(progress, currency),
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
            note: noteFor(entry, asOf: now),
            nearLimitThreshold: entry.budget.alertThreshold,
            onTap: onOpen == null ? null : () => onOpen!(entry.budget.id),
          ),
          const SizedBox(height: MonetaSpacing.spaceMd),
        ],
      ],
    );
  }

  /// The card's supporting line: how much used, and how long is left.
  ///
  /// [asOf] is the real current instant, and is **required**. When the window
  /// has already ended — which the period switcher makes reachable — the
  /// "days left" clause is dropped rather than reported.
  ///
  /// Required rather than optional because the optional default *was* the bug:
  /// omit it and a finished month reports "31 days left" again. A caller that
  /// only ever shows the current period still has to say so.
  ///
  /// `BudgetProgress` for a past period is computed at that window's start, so
  /// `daysRemaining` is the window's whole length. Without [asOf] this rendered
  /// **"0% used · 31 days left"** on a month that finished weeks ago. Omitted
  /// rather than replaced with "0 days left", which reads as a deadline today.
  static String noteFor(BudgetProgress entry, {required DateTime asOf}) {
    final percent = (entry.fraction * 100).round();
    if (!entry.window.end.isAfter(asOf)) return '$percent% used';

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
