import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';

/// A spending limit for one category over a repeating period.
///
/// Carries exactly what `04.04` collects — category, limit, period, start date,
/// rollover, alert threshold — and **nothing about spend**. Spend is computed
/// from the transactions already stored, so a budget and the transactions under
/// it cannot disagree. A stored total drifts the first time a transaction is
/// edited or deleted by anything but the one path that maintains it.
class Budget extends Equatable {
  const Budget._({
    required this.id,
    required this.category,
    required this.limit,
    required this.period,
    required this.startsOn,
    required this.rollsOver,
    required this.alertThreshold,
    required this.createdAt,
  });

  /// Rebuilds a budget from a stored row.
  ///
  /// Skips validation on purpose: a row that is already in the database is a
  /// fact, and refusing to read it back would strand the user's data behind a
  /// rule that changed after it was written. Validation belongs at the door.
  const Budget.fromStorage({
    required this.id,
    required this.category,
    required this.limit,
    required this.period,
    required this.startsOn,
    required this.rollsOver,
    required this.alertThreshold,
    required this.createdAt,
  });

  /// Creates a budget, validating what `04.04` can get wrong.
  ///
  /// Returns a [Result] rather than throwing: an invalid limit is an expected
  /// failure of a form, not a programming error.
  static Result<Budget> create({
    required String id,
    required SpendCategory category,
    required Money limit,
    required BudgetPeriod period,
    required DateTime startsOn,
    required DateTime createdAt,
    bool rollsOver = false,
    double alertThreshold = BudgetStatus.defaultNearLimitThreshold,
  }) {
    if (limit.minorUnits == 0) {
      return const Err(
        AppFailure.validation(
          'A budget needs a limit. With no limit there is nothing to be over '
          'or under.',
        ),
      );
    }
    if (limit.minorUnits < 0) {
      return const Err(
        AppFailure.validation('A budget limit cannot be negative.'),
      );
    }
    if (alertThreshold <= 0 || alertThreshold > 1) {
      return const Err(
        AppFailure.validation(
          'Alert me at must be above 0% and at most 100%.',
        ),
      );
    }
    if (!startsOn.isUtc || !createdAt.isUtc) {
      return const Err(
        AppFailure.validation('Budget dates must be in UTC.'),
      );
    }
    return Ok(
      Budget._(
        id: id,
        category: category,
        limit: limit,
        period: period,
        startsOn: startsOn,
        rollsOver: rollsOver,
        alertThreshold: alertThreshold,
        createdAt: createdAt,
      ),
    );
  }

  /// Stable identifier.
  final String id;

  /// The category this limits.
  final SpendCategory category;

  /// The limit, in integer minor units.
  final Money limit;

  /// How often it resets.
  final BudgetPeriod period;

  /// The anchor date, UTC — `04.04`'s "Starts" row.
  final DateTime startsOn;

  /// Whether an unspent remainder raises the next period's limit.
  final bool rollsOver;

  /// `04.04`'s "Alert me at" — where the warning state begins, as a ratio.
  final double alertThreshold;

  /// When the budget was created, UTC.
  final DateTime createdAt;

  /// The window containing [now].
  BudgetWindow windowAt(DateTime now) => BudgetWindow.currentFor(
    anchor: startsOn,
    period: period,
    now: now,
  );

  /// A copy with the given fields replaced.
  Budget copyWith({
    Money? limit,
    BudgetPeriod? period,
    DateTime? startsOn,
    bool? rollsOver,
    double? alertThreshold,
  }) => Budget.fromStorage(
    id: id,
    category: category,
    limit: limit ?? this.limit,
    period: period ?? this.period,
    startsOn: startsOn ?? this.startsOn,
    rollsOver: rollsOver ?? this.rollsOver,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    category,
    limit,
    period,
    startsOn,
    rollsOver,
    alertThreshold,
    createdAt,
  ];
}
