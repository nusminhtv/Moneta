import 'package:equatable/equatable.dart';
import 'package:moneta/core/money.dart';

/// How often a plan is billed, from `102:1071`'s three cards.
enum PremiumPeriod {
  /// `102:1072` — billed every month.
  monthly('MONTHLY', 'per month'),

  /// `102:1076` — billed once a year, and the card the badge sits on.
  yearly('YEARLY', 'per year'),

  /// `102:1083` — bought once.
  lifetime('LIFETIME', 'one payment');

  const PremiumPeriod(this.label, this.caption);

  /// The card's heading, as `102:1073` writes it.
  final String label;

  /// The line under the price.
  final String caption;
}

/// One plan on `08.10`.
class PremiumPlan extends Equatable {
  /// Creates a plan.
  const PremiumPlan({required this.period, required this.price});

  /// Which plan this is.
  final PremiumPeriod period;

  /// What it costs.
  final Money price;

  @override
  List<Object?> get props => [period, price];
}

/// The three plans `102:1071` prices.
const List<PremiumPlan> premiumPlans = [
  PremiumPlan(
    period: PremiumPeriod.monthly,
    price: Money(59000, Currency.vnd),
  ),
  PremiumPlan(
    period: PremiumPeriod.yearly,
    price: Money(490000, Currency.vnd),
  ),
  PremiumPlan(
    period: PremiumPeriod.lifetime,
    price: Money(1490000, Currency.vnd),
  ),
];

/// What the yearly plan saves against paying monthly, as whole percent.
///
/// **Derived, never written down.** Annotation `102:1185`: *"59,000 ₫ × 12 =
/// 708,000 ₫ against 490,000 ₫ yearly, which is the 31% the badge claims. The
/// claim is arithmetic, not marketing."* A hard-coded `SAVE 31%` is the one
/// number on the screen that can be wrong while looking right.
///
/// The exact value is **30.79%**, so the rounding mode is part of the rule:
/// `round` gives the 31 the badge claims and `floor` would give 30 and
/// contradict it.
///
/// Returns null rather than a number when the comparison is meaningless — a
/// zero monthly price would divide by zero, and a yearly price above twelve
/// monthly payments is not a saving.
int? yearlySavingPercent({
  required Money monthly,
  required Money yearly,
}) {
  if (monthly.currency != yearly.currency) {
    throw ArgumentError(
      'Cannot compare ${monthly.currency.code} with ${yearly.currency.code}',
    );
  }
  final twelveMonths = monthly.minorUnits * 12;
  if (twelveMonths <= 0) return null;
  if (yearly.minorUnits >= twelveMonths) return null;

  return ((1 - yearly.minorUnits / twelveMonths) * 100).round();
}

/// What a feature row says about a tier, from `102:1096`'s table.
enum PremiumFeature {
  /// `102:1101` — both tiers.
  unlimitedAccounts('Unlimited accounts', inFree: true),

  /// `102:1111` — both tiers.
  budgetsAndGoals('Budgets and goals', inFree: true),

  /// `102:1121` — premium only.
  moreThanThreeGoals('More than 3 goals', inFree: false),

  /// `102:1131` — premium only.
  export('CSV and JSON export', inFree: false),

  /// `102:1141` — premium only.
  widgets('Home-screen widgets', inFree: false),

  /// `102:1151` — premium only.
  customCategoryColours('Custom category colours', inFree: false);

  const PremiumFeature(this.label, {required this.inFree});

  /// What the row says.
  final String label;

  /// Whether the free tier has it. Premium has all six.
  final bool inFree;
}
