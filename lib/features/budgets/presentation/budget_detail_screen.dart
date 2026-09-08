import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/banner.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';

/// One budget in depth — Figma `67:359` on track, `67:524` over limit.
///
/// Annotation `04.05`: *"The number the user actually needs is the daily
/// allowance — the limit alone does not tell them what they can spend today."*
class BudgetDetailScreen extends StatelessWidget {
  /// Creates the detail screen.
  const BudgetDetailScreen({
    required this.progress,
    required this.contributing,
    this.onBack,
    this.onEdit,
    super.key,
  });

  /// The budget and its computed figures.
  final BudgetProgress progress;

  /// Exactly the entries that make up [BudgetProgress.spent], newest first.
  ///
  /// Passed in rather than recomputed, so the list and the total cannot come
  /// from two different filters.
  final List<SpendEntry> contributing;

  /// Called from the app bar's back affordance.
  final VoidCallback? onBack;

  /// Called from the app bar's edit action.
  final VoidCallback? onEdit;

  /// Groups [contributing] by local day, newest day first.
  static List<({DateTime day, List<SpendEntry> entries})> groupByDay(
    List<SpendEntry> entries,
  ) {
    final byDay = <DateTime, List<SpendEntry>>{};
    for (final entry in entries) {
      final local = entry.occurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(entry);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final day in days) (day: day, entries: byDay[day]!)];
  }

  /// The banner's supporting line on `67:524`.
  ///
  /// Names the date. Annotation `04.06`: *"'you are over' without a date gives
  /// the user nothing to act on."*
  static String overBannerMessage(BudgetProgress progress) {
    final on = progress.passedLimitOn;
    final over = progress.overBy.format();
    if (on == null) return 'You are $over over this budget.';
    return 'You went $over over on ${_dayLabel(on)}.';
  }

  /// The note under the ring: how many transactions were left out, if any.
  static String? skippedNote(BudgetProgress progress) {
    final count = progress.skippedForeignCurrency;
    if (count == 0) return null;
    final plural = count == 1 ? 'transaction' : 'transactions';
    return '$count $plural in another currency are not counted here.';
  }

  static String _dayLabel(DateTime instant) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = instant.toLocal();
    return '${local.day} ${months[local.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final over = progress.overBy.minorUnits > 0;
    final groups = groupByDay(contributing);
    final note = skippedNote(progress);

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(
            title: progress.budget.category.label,
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: [
                if (over) ...[
                  MonetaBanner(
                    tone: BannerTone.danger,
                    title: 'Over budget',
                    message: overBannerMessage(progress),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceBase),
                ],
                Center(
                  child: MonetaCircularProgress(
                    fraction: progress.fraction,
                    size: MonetaCircularProgressSize.lg,
                    nearLimitThreshold: progress.budget.alertThreshold,
                    semanticLabel:
                        '${progress.budget.category.label} budget used',
                  ),
                ),
                const SizedBox(height: MonetaSpacing.spaceBase),
                Center(
                  child: Text(
                    '${progress.spent.format()} spent',
                    style: theme.text.headingH1.copyWith(
                      color: theme.colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: MonetaSpacing.space2xs),
                Center(
                  child: Text(
                    'of ${progress.effectiveLimit.format()}',
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: MonetaSpacing.spaceSm),
                  Center(
                    child: Text(
                      note,
                      textAlign: TextAlign.center,
                      style: theme.text.captionMd.copyWith(
                        color: theme.colors.warning,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: MonetaSpacing.spaceBase),
                Row(
                  children: [
                    Expanded(child: _leadTile(over)),
                    const SizedBox(width: MonetaSpacing.spaceMd),
                    Expanded(child: _remainingTile()),
                  ],
                ),
                const SizedBox(height: MonetaSpacing.spaceBase),
                const SectionHeader(title: 'What made this up'),
                for (final group in groups) ...[
                  DateGroupHeader(date: group.day),
                  for (final entry in group.entries)
                    TransactionRow(
                      key: ValueKey(entry.id),
                      title: entry.category.label,
                      amount: entry.amount,
                      direction: entry.direction,
                      category: entry.category,
                      occurredAt: entry.occurredAt,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The first tile: the daily allowance, or "Over by" when there is none.
  ///
  /// Annotation `04.06`: *"there is no daily-allowance tile here — it would be
  /// negative and meaningless, so it is replaced by 'Over by'. Swapping a tile
  /// rather than showing a negative number is a deliberate choice."*
  Widget _leadTile(bool over) => over
      ? StatTile(
          label: 'Over by',
          value: progress.overBy,
          delta: StatDelta.down,
          deltaLabel: 'Past the limit',
        )
      : StatTile(
          label: 'Daily allowance',
          value: progress.dailyAllowance,
          delta: StatDelta.flat,
          deltaLabel: '${progress.daysRemaining} days left',
        );

  Widget _remainingTile() => StatTile(
    label: 'Left to spend',
    value: progress.remaining,
    delta: progress.remaining.minorUnits > 0 ? StatDelta.flat : StatDelta.down,
    deltaLabel: progress.remaining.minorUnits > 0
        ? 'This period'
        : 'Nothing left',
  );
}
