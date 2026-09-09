import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/banner.dart';
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
/// grouping the recent list by local day: totals are computed in `lib/app`, per
/// ADR 0004, which keeps them out of a build method.
///
/// `lib/app` is **not** in `tool/coverage_critical.txt` — only `lib/core`,
/// `*/domain/` and `*/data/` are. This comment used to claim the 85% gate
/// reached those totals. It does not, and the unguarded gap is where a display
/// cap silently reached safe-to-spend.
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
    this.onOpenNotifications,
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

  /// Called from the app bar's bell.
  ///
  /// Annotation `57:830` says the notification centre is *"reached from the
  /// Home app bar"*, and this is that entry point.
  ///
  /// **`52:3` authors a `search` glyph here, not a bell.** Almost certainly a
  /// component default left unoverridden: `AppBar/LargeTitle`'s own sample is
  /// titled "Transactions" with a search action, and the instance overrides the
  /// title to "Hi, Minh" without swapping the icon. Reproducing it would leave
  /// the notification centre with no way in, and Home has nothing to search —
  /// `SearchField` (`35:38`) is unbuilt and search belongs to Transactions.
  /// Deviation recorded in `docs/design-system/figma-map.md`.
  final VoidCallback? onOpenNotifications;

  /// How many budget cards Home shows.
  ///
  /// **Frame-derived, not stated as a rule.** Annotation `52:362` lists
  /// `BudgetCard x2` in its component inventory and its Data line says nothing
  /// about a cap — unlike the recent list, where the cap is stated outright. So
  /// two is what `52:2` instances (`52:125`, `52:143`), labelled here as an
  /// instance count rather than dressed up as a specification.
  ///
  /// **It lives in the screen deliberately.** This began life in `lib/app`
  /// beside the snapshot, and from there it reached `safeToSpend` and dropped
  /// every budget past the second out of the arithmetic. Ranking is worst-first,
  /// so the ones dropped were the least spent — the largest unspent
  /// commitments — and the figure came out optimistic by exactly the amount the
  /// user most needed to know about. A cap on what a screen draws must not be
  /// able to change what a number means.
  static const int budgetCardLimit = 2;

  /// The app bar actions shared by the loaded and loading states.
  ///
  /// One function so the two states cannot drift: annotation `52:630` requires
  /// the bar to render identically while loading.
  static List<MonetaAppBarAction> appBarActions({
    VoidCallback? onOpenNotifications,
  }) => [
    (
      icon: MonetaIconName.bell,
      semanticLabel: 'Notifications',
      onPressed: onOpenNotifications,
    ),
  ];

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
          MonetaAppBar(
            title: greeting,
            actions: appBarActions(
              onOpenNotifications: onOpenNotifications,
            ),
          ),
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
                      // The over-budget alert, from `57:414`. Above the hero,
                      // per annotation `57:612`.
                      if (snapshot.worstBudget case final worst?
                          when snapshot.hasOverBudget) ...[
                        _OverBudgetBanner(
                          budget: worst,
                          onTap: onSeeAllBudgets,
                        ),
                        const SizedBox(height: MonetaSpacing.spaceBase),
                      ],
                      BalanceCard(
                        totalBalance: snapshot.totalBalance,
                        safeToSpend: snapshot.safeToSpend,
                        income: snapshot.income,
                        expenses: snapshot.expenses,
                        safeToSpendUntil: _monthEndLabel(),
                        masked: masked,
                        onToggleMask: onToggleMask,
                      ),
                      // `57:414` authors no quick-actions row, while `52:2`
                      // does. The annotation's "same layout as 02.01" is loose
                      // prose; the frame is specific, and `52:2` proves frames
                      // here do draw content past their own fold, so the
                      // omission is a decision rather than a crop.
                      if (quickActions.isNotEmpty &&
                          !snapshot.hasOverBudget) ...[
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
                        for (final budget in snapshot.budgets.take(
                          budgetCardLimit,
                        )) ...[
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
  /// **The copy is verified against the nodes** (read once Figma access
  /// returned). The three rows match `52:428`, `52:459` and `52:481` word for
  /// word — titles, subtitles and leading glyphs (`icon/credit-card` `10:25`,
  /// `icon/plus` `10:29`, `icon/target` `10:20`) — as does the empty state's
  /// title and its `icon/shopping-bag` (`11:54`). That copy was written while
  /// this change believed no Figma tool was callable, and it was right anyway.
  ///
  /// Exactly two strings diverge from `52:389`, both consequences of the CTA
  /// decision above:
  ///
  /// - the action reads "Log your first expense" where Figma authors
  ///   "Link an account";
  /// - the message drops Figma's opening clause. It authors *"Add an account and
  ///   log one transaction. Moneta needs about a week of data before budgets get
  ///   useful."* The second sentence is kept verbatim; the first instructed the
  ///   user to add an account, which is the thing they cannot do.
  ///
  /// `35:138`'s own description states the rule this screen is built around:
  /// *"An empty state without a primary action is a dead end — only use
  /// HasAction=False when there is genuinely nothing the user can do here."*
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
  /// The end of the current **local** month.
  ///
  /// The justification here used to read "there is no budget feature yet, so
  /// claiming one would be inventing a number". That stopped being true when
  /// `budgets-feature` landed — it is the fourth stale claim found in this file
  /// by review, all of the same shape: a comment that was accurate when written
  /// and became false without anyone noticing.
  ///
  /// **Known gap, deliberately not closed here.** Safe-to-spend now subtracts
  /// remainders from budgets that may be weekly or yearly, while this label
  /// always names the month end. So the figure and its horizon can disagree
  /// about the period they describe. Making the horizon follow the budgets
  /// means deciding what to show for a mixed set, which is a design decision
  /// rather than a fix; recorded in `docs/design-system/figma-map.md`.
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

/// Home's over-budget alert, from the `Banner` instance at `57:431`.
///
/// **It names one category, never a list.** Annotation `57:612`: *"banner text
/// names the worst category only, even if several are over."* The worst budget
/// is the head of an already-ranked list, so this cannot disagree with the card
/// order below it.
///
/// The tone is `Warning`, as authored — amber — even though the card for the
/// same budget renders its `Over` state in coral. That is the annotation's
/// choice and is reproduced rather than harmonised: the banner rates how urgent
/// the situation is, the card reports which state a budget is in.
///
/// The alert does not rest on colour: it carries a heading, a sentence and an
/// amount. `MonetaBanner` also supplies a tone icon.
///
/// **The sentence wording is not verified against `57:431`.** Figma access was
/// unavailable throughout this task, so the copy is composed from the data the
/// annotation says it must name. Recorded in
/// `docs/design-system/figma-map.md`.
class _OverBudgetBanner extends StatelessWidget {
  const _OverBudgetBanner({required this.budget, this.onTap});

  final BudgetSummary budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MonetaBanner(
      tone: BannerTone.warning,
      title: '${budget.category.label} is over budget',
      message:
          "You've spent ${budget.overBy.format()} more than this period's "
          'limit of ${budget.limit.format()}.',
      onTap: onTap,
    );
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
