import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
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
    required this.now,
    this.onLinkAccount,
    this.onLogFirstExpense,
    this.onSetBudget,
    this.masked = false,
    this.onToggleMask,
    this.onSeeAllTransactions,
    this.onSeeAllBudgets,
    this.onOpenBudget,
    this.quickActions = const [],
    super.key,
  });

  /// What to render.
  final HomeSnapshot snapshot;

  /// The app bar title — `Hi, Minh` in the design.
  final String greeting;

  /// Now, in UTC, injected from the app's `Clock`.
  ///
  /// A screen calling `DateTime.now()` cannot be tested at a chosen date and
  /// quietly disagrees with the rest of the app, which reads the injected
  /// clock. This screen used to.
  final DateTime now;

  /// First-run checklist: link an account. Null while Accounts does not exist.
  final VoidCallback? onLinkAccount;

  /// First-run checklist: log the first expense.
  final VoidCallback? onLogFirstExpense;

  /// First-run checklist: set one budget. Null while Budgets does not exist.
  final VoidCallback? onSetBudget;

  /// Whether the balance figures are hidden.
  final bool masked;

  /// Called when the mask is toggled.
  final VoidCallback? onToggleMask;

  /// Called from the recent section's "See all".
  final VoidCallback? onSeeAllTransactions;

  /// Called from the budgets section's "See all".
  final VoidCallback? onSeeAllBudgets;

  /// Called with a budget's id when its card is tapped.
  final void Function(String id)? onOpenBudget;

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
            child: snapshot.isFirstRun
                ? _firstRun(context)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MonetaSpacing.spaceLg,
                      MonetaSpacing.spaceXs,
                      MonetaSpacing.spaceLg,
                      MonetaSpacing.spaceBase,
                    ),
                    children: [
                      BalanceCard(
                        totalBalance: snapshot.totalBalance,
                        safeToSpend: snapshot.safeToSpend,
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
                      // The budgets section, from `52:116` and the two cards at
                      // `52:125` and `52:143`. Omitted entirely when there are
                      // no budgets: a heading with nothing under it reads as a
                      // failed load rather than as an absence.
                      if (snapshot.budgets.isNotEmpty) ...[
                        const SizedBox(height: MonetaSpacing.spaceBase),
                        SectionHeader(
                          title: 'Budgets',
                          actionLabel: 'See all',
                          onAction: onSeeAllBudgets,
                        ),
                        for (final budget in snapshot.budgets) ...[
                          const SizedBox(height: MonetaSpacing.spaceSm),
                          BudgetCard(
                            key: ValueKey('budget-${budget.category.name}'),
                            category: budget.category,
                            spent: budget.spent,
                            limit: budget.limit,
                            note: budget.note,
                            nearLimitThreshold: budget.alertThreshold,
                            onTap: onOpenBudget == null
                                ? null
                                : () => onOpenBudget!(budget.id),
                          ),
                        ],
                      ],
                      const SizedBox(height: MonetaSpacing.spaceBase),
                      SectionHeader(
                        title: 'Recent transactions',
                        actionLabel: 'See all',
                        onAction: onSeeAllTransactions,
                      ),
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

  /// Home before there is anything to show, from Figma `52:372`.
  ///
  /// A different screen, not the normal one with a blank middle: no balance
  /// card over zero, no quick actions to nowhere. An empty state with one real
  /// action, then the three things that make the app useful — which is what
  /// `35:138` means by *"an empty state without a primary action is a dead
  /// end"*.
  Widget _firstRun(BuildContext context) {
    final theme = context.moneta;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MonetaSpacing.spaceLg,
        MonetaSpacing.spaceXs,
        MonetaSpacing.spaceLg,
        MonetaSpacing.spaceBase,
      ),
      children: [
        EmptyState(
          icon: MonetaIconName.shoppingBag,
          title: "Let's set up your money",
          message:
              'Add an account and log one transaction. Moneta needs about a '
              'week of data before budgets get useful.',
          actionLabel: 'Link an account',
          onAction: onLinkAccount,
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surfaceRaised,
            borderRadius: theme.radii.borderLg,
            border: Border.all(color: theme.colors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MonetaSpacing.spaceBase,
              vertical: MonetaSpacing.spaceXs,
            ),
            child: Column(
              children: [
                ListRow(
                  title: 'Link an account',
                  subtitle: 'Bank, cash or e-wallet',
                  leadingIcon: MonetaIconName.creditCard,
                  accessory: ListRowAccessory.chevron,
                  onTap: onLinkAccount,
                ),
                ListRow(
                  title: 'Log your first expense',
                  subtitle: 'Takes about five seconds',
                  leadingIcon: MonetaIconName.plus,
                  accessory: ListRowAccessory.chevron,
                  onTap: onLogFirstExpense,
                ),
                ListRow(
                  title: 'Set one budget',
                  subtitle: 'Start with your biggest category',
                  leadingIcon: MonetaIconName.target,
                  accessory: ListRowAccessory.chevron,
                  onTap: onSetBudget,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The label the balance card shows after "Safe to spend … until".
  ///
  /// Deliberately not a computed budget horizon: there is no budget feature yet,
  /// so claiming one would be inventing a number. It names the end of the
  /// current local month, which is true.
  String _monthEndLabel() {
    final local = now.toLocal();
    final end = DateTime(local.year, local.month + 1, 0);
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
