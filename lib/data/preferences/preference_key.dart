/// Every preference the application stores.
///
/// Declared in one place so a typo cannot silently create a second,
/// permanently-empty setting — the failure mode where a toggle appears to work
/// and never persists.
///
/// Every preference is **control-scoped**: read from and written to the control
/// database, which the demo toggle never swaps. So no preference changes value
/// when the active ledger does.
///
/// That is not a detail. If [demoMode] lived in the database it selects,
/// turning demo mode on would write `true` to the real database and then read
/// `false` back from the demo one, and the toggle would undo itself. And if
/// [onboardingComplete] were ledger-scoped, enabling demo mode would re-show
/// the introduction, because the demo database has never seen it.
enum PreferenceKey {
  /// Whether the first-run introduction has been finished or skipped.
  onboardingComplete('onboarding_complete'),

  /// Whether the demo ledger is the active one.
  demoMode('demo_mode'),

  /// `08.06`: warn at 80% of a budget.
  notifyBudgetNearLimit('notify_budget_near_limit'),

  /// `08.06`: tell me when a budget is exceeded.
  notifyBudgetExceeded('notify_budget_exceeded'),

  /// `08.06`: tell me a budget period is ending.
  notifyPeriodEnding('notify_period_ending'),

  /// `08.06`: tell me when money comes in.
  notifyIncome('notify_income');

  const PreferenceKey(this.storedName);

  /// The name as written in the database. Kept separate from the Dart name so
  /// renaming the enum member does not orphan stored data.
  final String storedName;
}
