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
  /// card over zero, no quick actions to nowhere. Annotation `52:537`:
  /// *"An empty state with no action is a dead end, so this one carries both a
  /// primary CTA and a 3-step checklist."*
  ///
  /// **The primary action is "Log your first expense", not "Link an account".**
  /// Figma's CTA is the account one, and Accounts (page 05) is not built, so
  /// wiring the app's very first screen to it would have produced exactly the
  /// dead end the annotation exists to prevent — a CTA that does nothing, above
  /// a checklist whose first row also does nothing. Logging an expense is the
  /// step that actually works and the one that replaces this screen. The
  /// account row is kept, disabled, so the checklist still reads as three steps.
  ///
  /// This is a deliberate divergence from the authored copy, recorded in
  /// `docs/design-system/figma-map.md`. It should be revisited when Accounts
  /// lands, at which point Figma's CTA becomes the correct one.
  ///
  /// **The copy here is not verified against the nodes.** It was written while
  /// this change believed no Figma tool was callable, and `52:389`, `52:428`,
  /// `52:459` and `52:481` still have not been read — access was unavailable
  /// throughout this task. Treat every string below as unconfirmed.
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
              'Log one transaction to get started. Moneta needs about a week '
              'of data before budgets get useful.',
          actionLabel: 'Log your first expense',
          onAction: onLogFirstExpense,
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
                _ChecklistRow(
                  title: 'Link an account',
                  subtitle: 'Bank, cash or e-wallet',
                  icon: MonetaIconName.creditCard,
                  onTap: onLinkAccount,
                ),
                _ChecklistRow(
                  title: 'Log your first expense',
                  subtitle: 'Takes about five seconds',
                  icon: MonetaIconName.plus,
                  onTap: onLogFirstExpense,
                ),
                _ChecklistRow(
                  title: 'Set one budget',
                  subtitle: 'Start with your biggest category',
                  icon: MonetaIconName.target,
                  // Annotation `52:537`: "checklist items tick off
                  // independently". This is the only one that can tick while
                  // the screen is still showing — the screen is replaced by
                  // `52:2` as soon as any transaction exists, and the account
                  // step has no feature to complete.
                  done: snapshot.budgets.isNotEmpty,
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

/// One step of the first-run checklist, from the rows at `52:428`–`52:481`.
///
/// Two things it will not do, both for the same reason — an accessory must not
/// promise something the row cannot deliver:
///
/// - **A step with no destination gets no chevron.** Figma authors all three as
///   `Trailing=Chevron`, but "Link an account" has nowhere to go until Accounts
///   is built. A chevron on it would advertise navigation that does not happen.
///   Deviation recorded in `docs/design-system/figma-map.md`.
/// - **A completed step gets a badge, not a chevron.** `52:372` authors no
///   ticked state — nothing is complete on a first-run frame — so rather than
///   invent a visual, this composes `ListRow`'s authored `Badge` accessory. The
///   row also stops responding, because re-doing a finished step is not a step.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.done = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final MonetaIconName icon;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return ListRow(
        title: title,
        subtitle: subtitle,
        leadingIcon: icon,
        accessory: ListRowAccessory.badge,
        badgeLabel: 'Done',
      );
    }
    return ListRow(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      accessory: onTap == null
          ? ListRowAccessory.none
          : ListRowAccessory.chevron,
      onTap: onTap,
    );
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
