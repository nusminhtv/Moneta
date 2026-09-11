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

/// Saves [profile] through [store].
///
/// Returns the failure rather than throwing, because `08.02` renders it — the
/// email field takes what is about the email and a banner takes the rest, and
/// in both cases the typed values stay on screen.
///
/// **Takes the store, not a `Ref`.** The first version took a `WidgetRef`,
/// which tied it to the widget layer for no reason and made it untestable from
/// a `ProviderContainer` — `change-verifier` found it at **0 of 9 lines
/// covered**, and the silent-failure defect on `08.02` was living in exactly
/// that hole. Refreshing what reads the profile is the caller's line, right
/// beside its own `setState`.
Future<AppFailure?> saveProfile(ProfileStore store, Profile profile) async {
  final saved = await store.save(profile);
  return saved.when(ok: (_) => null, err: (failure) => failure);
}
