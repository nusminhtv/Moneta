import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';

/// What a budget looks like right now.
///
/// Computed from the transactions in the database, never stored. Everything
/// here is derived from [budget] plus a list of transactions plus the clock.
class BudgetProgress extends Equatable {
  /// Creates a progress view. Prefer [BudgetProgress.compute].
  const BudgetProgress({
    required this.budget,
    required this.window,
    required this.spent,
    required this.carriedIn,
    required this.daysRemaining,
    required this.skippedForeignCurrency,
    this.passedLimitOn,
  });

  /// Computes a budget's progress from [entries].
  ///
  /// [entries] may be the whole ledger; this filters. Filtering here rather
  /// than in the query keeps the rule — expense only, this category, this
  /// window, this currency — in one readable place with the tests that pin it.
  factory BudgetProgress.compute({
    required Budget budget,
    required List<SpendEntry> entries,
    required DateTime now,
  }) {
    final window = budget.windowAt(now);
    final currency = budget.limit.currency;

    var spentMinor = 0;
    var skipped = 0;
    for (final t in entries) {
      if (t.category != budget.category) continue;
      if (t.direction != TransactionDirection.expense) continue;
      if (!window.contains(t.occurredAt)) continue;
      if (t.amount.currency != currency) {
        // Not converted. There is no rate in a local-first app, and inventing
        // one would put a made-up number in a total the user trusts.
        skipped++;
        continue;
      }
      spentMinor += t.amount.minorUnits;
    }

    return BudgetProgress(
      budget: budget,
      window: window,
      spent: Money(spentMinor, currency),
      carriedIn: _carryInto(window: window, budget: budget, entries: entries),
      daysRemaining: window.daysRemainingFrom(now),
      skippedForeignCurrency: skipped,
      passedLimitOn: _crossingInstant(
        budget: budget,
        window: window,
        entries: entries,
        limitMinor:
            budget.limit.minorUnits +
            _carryInto(
              window: window,
              budget: budget,
              entries: entries,
            ).minorUnits,
      ),
    );
  }

  /// The budget this describes.
  final Budget budget;

  /// The window the figures cover.
  final BudgetWindow window;

  /// Spend inside [window], in the budget's currency.
  final Money spent;

  /// Unspent amount carried from the immediately preceding window.
  ///
  /// Reported separately rather than folded into the limit: a user who set
  /// 4,000,000 and is shown 5,000,000 with no explanation would reasonably
  /// think the app is broken.
  final Money carriedIn;

  /// Whole days left in [window], never below 1.
  final int daysRemaining;

  /// How many transactions in this window were skipped for being in another
  /// currency, so a screen can say so instead of under-reporting silently.
  final int skippedForeignCurrency;

  /// When spend first passed the effective limit, or null if it has not.
  ///
  /// Annotation `04.06`: *"It says WHEN the budget was passed, because 'you are
  /// over' without a date gives the user nothing to act on."*
  final DateTime? passedLimitOn;

  /// The limit actually in force: the budget's limit plus any carry.
  Money get effectiveLimit => Money(
    budget.limit.minorUnits + carriedIn.minorUnits,
    budget.limit.currency,
  );

  /// Spend as an unclamped fraction of [effectiveLimit].
  double get fraction => BudgetStatus.fractionOf(spent, effectiveLimit);

  /// The status, derived against the budget's own alert threshold.
  BudgetStatus get status => BudgetStatus.fromSpend(
    spent,
    effectiveLimit,
    nearLimitThreshold: budget.alertThreshold,
  );

  /// Whatever is left of [effectiveLimit], never below zero.
  Money get remaining {
    final left = effectiveLimit.minorUnits - spent.minorUnits;
    return Money(left < 0 ? 0 : left, budget.limit.currency);
  }

  /// Whether [entry] is one of the entries counted in [spent].
  ///
  /// The four rules in one place, so a screen listing "what made this up"
  /// cannot filter differently from the total it sits under.
  bool counts(SpendEntry entry) =>
      entry.category == budget.category &&
      entry.direction == TransactionDirection.expense &&
      window.contains(entry.occurredAt) &&
      entry.amount.currency == budget.limit.currency;

  /// How far past the effective limit, never negative.
  Money get overBy {
    final over = spent.minorUnits - effectiveLimit.minorUnits;
    return Money(over > 0 ? over : 0, budget.limit.currency);
  }

  /// `04.05`'s number: `(limit - spent) / days remaining`.
  ///
  /// Rounded **down**. An allowance rounded up is one the user cannot actually
  /// spend every day without going over, which is worse than being slightly
  /// conservative. Zero when over budget — there is nothing to allow.
  Money get dailyAllowance =>
      Money(remaining.minorUnits ~/ daysRemaining, budget.limit.currency);

  /// When cumulative spend first passed [limitMinor], or null.
  ///
  /// Entries are sorted by occurrence, not taken in the order they arrive: the
  /// answer is a fact about when the money was spent, and a caller handing them
  /// over in insertion order would otherwise get a different date.
  static DateTime? _crossingInstant({
    required Budget budget,
    required BudgetWindow window,
    required List<SpendEntry> entries,
    required int limitMinor,
  }) {
    final currency = budget.limit.currency;
    final counted = <SpendEntry>[
      for (final t in entries)
        if (t.category == budget.category &&
            t.direction == TransactionDirection.expense &&
            window.contains(t.occurredAt) &&
            t.amount.currency == currency)
          t,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    var running = 0;
    for (final entry in counted) {
      running += entry.amount.minorUnits;
      // Strictly greater: exactly at the limit is the limit reached, not
      // exceeded, which is the same rule BudgetStatus applies at 1.0.
      if (running > limitMinor) return entry.occurredAt;
    }
    return null;
  }

  /// The carry into [window] from the one before it.
  ///
  /// One window deep, not recursive: a recursive carry walks every window since
  /// the budget was created on every read, which is unbounded work on a screen
  /// that renders on every app open. See docs/adr/0004-rollover-depth.md.
  static Money _carryInto({
    required BudgetWindow window,
    required Budget budget,
    required List<SpendEntry> entries,
  }) {
    final currency = budget.limit.currency;
    if (!budget.rollsOver) return Money(0, currency);

    // Null when this is the budget's first window, which carries nothing.
    // `previous` is anchor-derived, so it can no longer return a window that
    // starts before `startsOn`; the old guard against that is gone with it.
    final previous = window.previous(
      budget.period,
      anchor: budget.startsOn,
    );
    if (previous == null) return Money(0, currency);

    var spentMinor = 0;
    for (final t in entries) {
      if (t.category != budget.category) continue;
      if (t.direction != TransactionDirection.expense) continue;
      if (!previous.contains(t.occurredAt)) continue;
      if (t.amount.currency != currency) continue;
      spentMinor += t.amount.minorUnits;
    }

    final unspent = budget.limit.minorUnits - spentMinor;
    // Overspending does not carry a debt forward. `04.04` says rollover changes
    // the next period's limit; it does not say it punishes.
    return Money(unspent > 0 ? unspent : 0, currency);
  }

  @override
  List<Object?> get props => [
    budget,
    window,
    spent,
    carriedIn,
    daysRemaining,
    skippedForeignCurrency,
    passedLimitOn,
  ];
}

/// Orders budgets worst first.
///
/// Annotation `04.01`: *"cards sort by percentage used descending, so an
/// over-limit budget can never be below the fold."*
///
/// Ties break on the budget's id so repeated reads give the same order — a list
/// that reshuffles between frames looks like a bug even when every card is
/// correct.
int compareWorstFirst(BudgetProgress a, BudgetProgress b) {
  final byFraction = b.fraction.compareTo(a.fraction);
  if (byFraction != 0) return byFraction;
  return a.budget.id.compareTo(b.budget.id);
}
