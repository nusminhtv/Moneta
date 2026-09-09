import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';

/// One row in Home's recent list.
///
/// A pure value type over `core` types only. Home renders these; it never sees a
/// `Transaction`, a repository or a database.
final class RecentEntry extends Equatable {
  /// Creates a recent entry.
  const RecentEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.direction,
    required this.category,
    required this.occurredAt,
  });

  /// Stable identity, so a list can key its rows.
  final String id;

  /// What to show as the row's title.
  final String title;

  /// The amount moved. Always positive; [direction] carries the sign.
  final Money amount;

  /// Which way the money went.
  ///
  /// `TransactionDirection` lives in `lib/core`, so `features/home` may use it
  /// directly — no duplicate enum, and no mapping to get wrong.
  final TransactionDirection direction;

  /// The category, which fixes the row's colour and glyph.
  final SpendCategory category;

  /// When it happened, in UTC.
  final DateTime occurredAt;

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    direction,
    category,
    occurredAt,
  ];
}

/// One budget, as Home sees it.
///
/// Home may not import `features/budgets` — `tool/check_architecture.dart`
/// forbids it — so this is the same reduction `RecentEntry` performs for
/// transactions: a value type over `core` types that the composition layer fills
/// in. `lib/app` maps a `BudgetProgress` onto one of these.
///
/// [limit] is the **effective** limit, meaning the budget's own limit plus any
/// rollover carried into this period. Passing the raw limit instead would make
/// this summary's status disagree with the Budgets screen's for the same budget.
final class BudgetSummary extends Equatable {
  /// Creates a budget summary.
  const BudgetSummary({
    required this.id,
    required this.category,
    required this.spent,
    required this.limit,
    required this.note,
    this.alertThreshold = BudgetStatus.defaultNearLimitThreshold,
  });

  /// The budget's identity, so a card can open its own detail screen.
  ///
  /// Without this every card on Home would have to navigate to the budgets
  /// list, which makes the card's identity irrelevant to where tapping it
  /// goes — a coarse destination reads as a bug the first time a user taps the
  /// second card and lands somewhere generic.
  final String id;

  /// Which category this budget governs.
  final SpendCategory category;

  /// Spent against it so far this period.
  final Money spent;

  /// The effective limit in force this period.
  final Money limit;

  /// The card's secondary line — "12 days left", and so on.
  final String note;

  /// The fraction at which this budget starts reading as near its limit.
  ///
  /// Per-budget, not a constant. Annotation `04.04`: *"the 80% threshold is
  /// configurable here, so the component's warning colour is data-driven, not
  /// hardcoded."*
  final double alertThreshold;

  /// Whatever is left of [limit], never below zero.
  ///
  /// Clamped, matching `BudgetProgress.remaining`. An unclamped value would make
  /// an overspent budget *add* to safe-to-spend, which is the opposite of what
  /// being over a budget means.
  Money get remaining {
    final left = limit.minorUnits - spent.minorUnits;
    return Money(left < 0 ? 0 : left, limit.currency);
  }

  /// How far past [limit] the spend has gone, never negative.
  ///
  /// Clamped like [remaining] and for the same reason: a budget that is under
  /// its limit is not "over by" a negative amount, it is simply not over.
  Money get overBy {
    final over = spent.minorUnits - limit.minorUnits;
    return Money(over > 0 ? over : 0, limit.currency);
  }

  /// The status, derived against this budget's own threshold.
  BudgetStatus get status =>
      BudgetStatus.fromSpend(spent, limit, nearLimitThreshold: alertThreshold);

  /// Whether spend has passed the effective limit.
  bool get isOver => status == BudgetStatus.over;

  @override
  List<Object?> get props => [
    id,
    category,
    spent,
    limit,
    note,
    alertThreshold,
  ];
}

/// Everything Home needs to render, assembled before it is built.
///
/// Home takes one of these and does no arithmetic of its own beyond grouping the
/// recent list by day. Totals are computed in `lib/app`, which keeps arithmetic
/// out of a widget's build method.
///
/// Note that `lib/app` is **not** in `tool/coverage_critical.txt` — only
/// `lib/core`, `*/domain/` and `*/data/` are. Earlier comments here claimed the
/// 85% gate reached these totals; it does not, and the money bug that a display
/// cap caused lived in exactly that unguarded gap.
final class HomeSnapshot extends Equatable {
  /// Creates a snapshot.
  const HomeSnapshot({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.recent,
    required this.safeToSpend,
    this.budgets = const [],
  });

  /// An empty wallet — a first run, before anything is recorded.
  factory HomeSnapshot.empty(Currency currency) => HomeSnapshot(
    totalBalance: Money.zero(currency),
    income: Money.zero(currency),
    expenses: Money.zero(currency),
    recent: const [],
    safeToSpend: Money.zero(currency),
  );

  /// Income minus expenses, across everything recorded up to now.
  final Money totalBalance;

  /// Money in over the period.
  final Money income;

  /// Money out over the period, as a positive amount.
  final Money expenses;

  /// The most recent entries, newest first.
  final List<RecentEntry> recent;

  /// What is left after every budget's unspent commitment is set aside.
  ///
  /// From annotation `52:362`: *"safe-to-spend = balance minus committed budgets
  /// minus scheduled bills to period end."* Computed in `lib/app`.
  ///
  /// **This figure is short by one term.** Scheduled bills do not exist anywhere
  /// in this codebase, and inventing them from one clause of one annotation is
  /// how the invented spacing scale happened. The omission is recorded in
  /// `docs/design-system/figma-map.md` rather than papered over.
  final Money safeToSpend;

  /// Budgets to show on Home, worst first.
  ///
  /// Already ranked and already capped by the composition layer: the screen
  /// renders what it is given rather than deciding which budgets matter.
  final List<BudgetSummary> budgets;

  /// Whether any budget has passed its limit.
  ///
  /// Drives the over-budget alert state at `57:414`. Annotation `57:612`:
  /// *"over-budget alert — triggered when any active budget exceeds 100%."*
  bool get hasOverBudget => budgets.any((budget) => budget.isOver);

  /// The worst budget, or null when there are none.
  ///
  /// [budgets] arrives worst-first, so this is the head of the list. The banner
  /// names **only** this one: annotation `57:612` says the text *"names the
  /// worst category only, even if several are over."*
  BudgetSummary? get worstBudget => budgets.isEmpty ? null : budgets.first;

  /// Whether there is nothing recent to list.
  bool get isEmpty => recent.isEmpty;

  /// Whether this wallet has never held anything.
  ///
  /// Distinct from [isEmpty] on purpose. An empty `recent` list is not first
  /// run: a wallet can hold a balance whose transactions have all scrolled past
  /// the recent limit, and swapping that for the setup checklist would hide
  /// real money behind "Link an account". First run means every figure is zero
  /// as well.
  bool get isFirstRun =>
      recent.isEmpty && totalBalance.isZero && income.isZero && expenses.isZero;

  @override
  List<Object?> get props => [
    totalBalance,
    income,
    expenses,
    recent,
    safeToSpend,
    budgets,
  ];
}
