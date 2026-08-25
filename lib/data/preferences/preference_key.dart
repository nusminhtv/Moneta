/// Every preference the application stores.
///
/// Declared in one place so a typo cannot silently create a second,
/// permanently-empty setting — the failure mode where a toggle appears to work
/// and never persists.
enum PreferenceKey {
  /// Whether the first-run introduction has been finished or skipped.
  onboardingComplete('onboarding_complete');

  const PreferenceKey(this.storedName);

  /// The name as written in the database. Kept separate from the Dart name so
  /// renaming the enum member does not orphan stored data.
  final String storedName;
}
