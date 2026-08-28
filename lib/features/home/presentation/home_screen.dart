import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';

/// One shortcut in Home's quick-actions row.
typedef HomeQuickAction = ({
  MonetaIconName icon,
  String label,
  VoidCallback? onPressed,
});

/// The Home screen, from Figma node `52:2`.
///
/// Takes a [HomeSnapshot] and renders it. It performs no arithmetic beyond
/// grouping the recent list by local day: totals are computed in `lib/app`,
/// where `tool/coverage_critical.txt` reaches them, per ADR 0004.
///
/// The bottom navigation is **not** here — the shell owns it, so the active tab
/// cannot disagree with the route. Figma draws it inside the screen frame
/// because Figma has no router.
class HomeScreen extends StatelessWidget {
  /// Creates the Home screen.
  const HomeScreen({
    required this.snapshot,
    required this.greeting,
    this.masked = false,
    this.onToggleMask,
    this.onSeeAllTransactions,
    this.quickActions = const [],
    super.key,
  });

  /// What to render.
  final HomeSnapshot snapshot;

  /// The app bar title — `Hi, Minh` in the design.
  final String greeting;

  /// Whether the balance figures are hidden.
  final bool masked;

  /// Called when the mask is toggled.
  final VoidCallback? onToggleMask;

  /// Called from the recent section's "See all".
  final VoidCallback? onSeeAllTransactions;

  /// The shortcut row under the balance card.
  final List<HomeQuickAction> quickActions;

  /// The recent entries grouped by their **local** day, newest day first.
  ///
  /// Local, not UTC: a transaction at 23:30 Hanoi is stored as 16:30 UTC the
  /// same day, and grouping in UTC would file it under the wrong heading. The
  /// gate pins `TZ=Asia/Ho_Chi_Minh` so a test of this can actually fail.
  static List<({DateTime day, List<RecentEntry> entries})> groupByDay(
    List<RecentEntry> entries,
  ) {
    final byDay = <DateTime, List<RecentEntry>>{};
    for (final entry in entries) {
      final local = entry.occurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      (byDay[day] ??= []).add(entry);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final day in days) (day: day, entries: byDay[day]!)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final groups = groupByDay(snapshot.recent);

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(title: greeting),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: [
                BalanceCard(
                  totalBalance: snapshot.totalBalance,
                  safeToSpend: snapshot.totalBalance,
                  income: snapshot.income,
                  expenses: snapshot.expenses,
                  safeToSpendUntil: _monthEndLabel(),
                  masked: masked,
                  onToggleMask: onToggleMask,
                ),
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: MonetaSpacing.spaceBase),
                  _QuickActions(actions: quickActions),
                ],
                const SizedBox(height: MonetaSpacing.spaceBase),
                SectionHeader(
                  title: 'Recent transactions',
                  actionLabel: snapshot.isEmpty ? null : 'See all',
                  onAction: snapshot.isEmpty ? null : onSeeAllTransactions,
                ),
                if (snapshot.isEmpty)
                  _NothingYet()
                else
                  for (final group in groups) ...[
                    DateGroupHeader(date: group.day),
                    for (final entry in group.entries)
                      TransactionRow(
                        key: ValueKey(entry.id),
                        title: entry.title,
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

  /// The label the balance card shows after "Safe to spend … until".
  ///
  /// Deliberately not a computed budget horizon: there is no budget feature yet,
  /// so claiming one would be inventing a number. It names the end of the
  /// current local month, which is true.
  String _monthEndLabel() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 1, 0);
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
    return '${end.day} ${months[end.month - 1]}';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: Column(
              children: [
                MonetaIconButton(
                  icon: action.icon,
                  semanticLabel: action.label,
                  style: MonetaIconButtonStyle.tonal,
                  onPressed: action.onPressed,
                ),
                const SizedBox(height: MonetaSpacing.spaceXs),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.labelSm.copyWith(
                    color: theme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NothingYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MonetaSpacing.space2xl),
      child: Text(
        'Nothing recorded yet. Tap + to add your first transaction.',
        textAlign: TextAlign.center,
        style: theme.text.bodyMd.copyWith(color: theme.colors.textTertiary),
      ),
    );
  }
}
