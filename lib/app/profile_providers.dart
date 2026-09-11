import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/settings/data/profile_store.dart';
import 'package:moneta/features/settings/domain/profile.dart';

/// Reads and writes the stored profile.
///
/// Built over [preferencesStoreProvider], which is the **control** database's
/// store — not the active one. That is the whole point: a ledger-scoped
/// profile would mean turning demo mode on renamed the user.
final profileStoreProvider = FutureProvider<ProfileStore>((ref) async {
  return ProfileStore(await ref.watch(preferencesStoreProvider.future));
});

/// The stored profile, or null when the user has not set one.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final store = await ref.watch(profileStoreProvider.future);
  final read = await store.read();
  return read.when(
    ok: (profile) => profile,
    // A storage failure is not "no profile": it is a failure, and the future
    // carries it so a screen can tell the two apart.
    err: (failure) => throw StateError(failure.message),
  );
});

/// Saves [profile] and refreshes everything that reads it.
///
/// Returns the failure rather than throwing, because `08.02` renders it: a
/// validation failure lands on the email field and a storage failure above the
/// footer, and in both cases the typed values stay on screen.
Future<AppFailure?> saveProfile(WidgetRef ref, Profile profile) async {
  final store = await ref.read(profileStoreProvider.future);
  final saved = await store.save(profile);
  return saved.when(
    ok: (_) {
      ref.invalidate(profileProvider);
      return null;
    },
    err: (failure) => failure,
  );
}
