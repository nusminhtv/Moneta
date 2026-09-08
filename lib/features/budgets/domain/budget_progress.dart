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

  /// `04.05`'s number: `(limit - spent) / days remaining`.
  ///
  /// Rounded **down**. An allowance rounded up is one the user cannot actually
  /// spend every day without going over, which is worse than being slightly
  /// conservative. Zero when over budget — there is nothing to allow.
  Money get dailyAllowance =>
      Money(remaining.minorUnits ~/ daysRemaining, budget.limit.currency);

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

    final previous = window.previous(budget.period);
    // A window before the budget existed carries nothing.
    if (previous.start.isBefore(budget.startsOn)) return Money(0, currency);

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
