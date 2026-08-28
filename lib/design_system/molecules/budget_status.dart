import 'package:flutter/painting.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// How a budget is doing, derived from spend rather than chosen.
///
/// Figma states the rule this encodes: *"The bar colour is derived from spend,
/// never chosen: under=income, >=80%=warning, over=expense."* Keeping the
/// thresholds here — one place, next to the widgets that render them — is what
/// makes it impossible for a caller to display a colour that contradicts the
/// numbers.
enum BudgetStatus {
  /// Below 80% of the limit.
  onTrack,

  /// At or above 80% of the limit, and not over it.
  nearLimit,

  /// Above the limit.
  over;

  /// The fraction at which a budget starts reading as near its limit.
  static const double nearLimitThreshold = 0.8;

  /// Classifies a raw spend fraction.
  ///
  /// [fraction] is deliberately **unclamped**: a clamped value cannot tell
  /// "exactly at the limit" from "double the limit", and those are different
  /// states. Exactly `1.0` is [nearLimit], not [over] — the limit has been
  /// reached, not exceeded.
  static BudgetStatus fromFraction(double fraction) {
    if (fraction.isNaN) return BudgetStatus.onTrack;
    if (fraction > 1) return BudgetStatus.over;
    if (fraction >= nearLimitThreshold) return BudgetStatus.nearLimit;
    return BudgetStatus.onTrack;
  }

  /// Classifies spend against a limit.
  ///
  /// A zero limit is treated as over budget the moment anything is spent: any
  /// spend against no allowance has exceeded it. A clamped ratio would report
  /// `0` here and render as on-track, which is the opposite of the truth.
  static BudgetStatus fromSpend(Money spent, Money limit) {
    if (spent.currency != limit.currency) {
      throw ArgumentError(
        'Currency mismatch: spent ${spent.currency.code} '
        'vs limit ${limit.currency.code}',
      );
    }
    if (spent.minorUnits <= 0) return BudgetStatus.onTrack;
    if (limit.minorUnits <= 0) return BudgetStatus.over;
    return fromFraction(spent.minorUnits / limit.minorUnits);
  }

  /// The unclamped spend fraction, for callers that need the raw number.
  ///
  /// Returns `0` when [limit] is zero so no caller has to guard against
  /// division by zero; use [fromSpend] to classify, which handles that case
  /// correctly.
  static double fractionOf(Money spent, Money limit) {
    if (limit.minorUnits == 0) return 0;
    return spent.minorUnits / limit.minorUnits;
  }

  /// The colour this status paints in.
  ///
  /// Lives on the status, not on each widget, so the bar and the ring cannot
  /// end up with two thresholds tables that drift apart.
  Color colorIn(MonetaColors colors) => switch (this) {
    BudgetStatus.onTrack => colors.income,
    BudgetStatus.nearLimit => colors.warning,
    BudgetStatus.over => colors.expense,
  };
}
