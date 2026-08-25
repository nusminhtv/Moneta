import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/preferences/preference_key.dart';

/// Whether the first-run introduction still needs to be shown.
///
/// **A failed read resolves to `true`.** Showing the introduction twice is a
/// minor annoyance; hiding the app behind a broken read is not, and the user has
/// no way to recover from the second. The spec states this as a requirement
/// rather than leaving it to the implementation.
final shouldShowOnboardingProvider = FutureProvider<bool>((ref) async {
  try {
    final store = await ref.watch(preferencesStoreProvider.future);
    final result = await store.readBool(PreferenceKey.onboardingComplete);
    return result.when(
      ok: (complete) => complete != true,
      err: (_) => true,
    );
  } on Object {
    // The store itself could not be built — an unopenable database. Same
    // reasoning: show it.
    return true;
  }
});

/// Records that the introduction is finished.
///
/// Skipping counts as finishing. The design offers no "remind me later", so
/// treating a skip as a defer would mean the user could never dismiss it.
final completeOnboardingProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final store = await ref.read(preferencesStoreProvider.future);
    await store.writeBool(PreferenceKey.onboardingComplete, value: true);
    ref.invalidate(shouldShowOnboardingProvider);
  };
});
