/// Providers every feature may reach for.
///
/// These lived in `features/transactions/presentation` until a second feature
/// needed them — at which point `tool/check_architecture.dart` correctly refused
/// the cross-feature import. `lib/data` is the only legal shared home:
/// `lib/core` must stay Flutter-free, and features may not import `lib/app`.
///
/// Riverpod is a package rather than a layer, so nothing in the architecture
/// rules objects to providers living here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

/// Time source. Overridden in tests with a `FixedClock`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Identifier source. Overridden in tests with a `FixedIdGenerator`.
final idGeneratorProvider = Provider<IdGenerator>((ref) => SystemIdGenerator());

/// The currency this wallet is denominated in.
final walletCurrencyProvider = Provider<Currency>((ref) => Currency.vnd);

/// Whether the demo ledger is the active one.
///
/// A plain synchronous flag, because [activeDatabaseProvider] has to choose a
/// file without awaiting one. Hydrating it from the control database at startup
/// and persisting a change belong to `DemoModeController` in `lib/app/demo/`;
/// this holds only the current answer.
///
/// It lives here rather than in `lib/app` because [activeDatabaseProvider]
/// depends on it, and `lib/data` may not import `lib/app`.
class DemoMode extends Notifier<bool> {
  @override
  bool build() => false;

  /// Whether the demo ledger is the active one. Same value the provider
  /// exposes; paired with the setter so reading and writing read alike.
  bool get active => state;

  /// Points the ledger at the demo database, or back at the real one.
  ///
  /// A setter rather than a method because it does nothing but set — the
  /// persisting and the seeding belong to `DemoModeController`, which calls
  /// this last, once the durable write has succeeded.
  set active(bool value) => state = value;
}

/// See [DemoMode].
final demoModeProvider = NotifierProvider<DemoMode, bool>(DemoMode.new);

/// File the real ledger lives in.
///
/// A provider rather than a constant so a test can point it at a temporary
/// directory while still running the production provider bodies below. The
/// bodies are the thing under test; overriding them instead would leave the
/// shipped code unexecuted, which is how the previous single database provider
/// reached zero coverage while every widget test passed.
final realDatabasePathProvider = Provider<String>((ref) => 'moneta.db');

/// File the demo ledger lives in. See [realDatabasePathProvider].
final demoDatabasePathProvider = Provider<String>(
  (ref) => 'moneta_demo.db',
);

/// The database that holds application settings, and the real ledger.
///
/// **Never swapped.** The setting that chooses the active ledger cannot live in
/// the file it chooses: writing "use the demo database" to the real database
/// and then reading the value back from the demo database returns whatever the
/// demo database happens to say, and the toggle undoes itself.
///
/// Closed when the provider is disposed, so a test container does not leak
/// connections between cases.
final controlDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    path: ref.watch(realDatabasePathProvider),
    factory: databaseFactory,
  );
  ref.onDispose(database.close);
  return database;
});

/// The database the ledger is read from and written to.
///
/// With demo mode off this **is** [controlDatabaseProvider] — the same
/// instance, so the real file is not opened twice. With it on, a separate
/// connection to the demo file, closed when the flag flips back.
///
/// Everything that reads or writes a transaction, a budget or anything else a
/// ledger contains watches this. Settings watch the control database instead.
final activeDatabaseProvider = Provider<AppDatabase>((ref) {
  if (!ref.watch(demoModeProvider)) {
    // Deliberately the same object, not a second AppDatabase on the same path:
    // two handles to one file would each open it, and "the database is opened
    // once" is a requirement.
    return ref.watch(controlDatabaseProvider);
  }
  final database = AppDatabase(
    path: ref.watch(demoDatabasePathProvider),
    factory: databaseFactory,
  );
  // Registered only on this branch. When the flag flips back to real, this
  // callback closes the demo connection, and the control database — which the
  // other branch returns without registering anything — stays open for
  // settings.
  ref.onDispose(database.close);
  return database;
});

/// Key/value preference storage.
///
/// Bound to the control database, so no preference changes value when the
/// active ledger does. Every preference this application has is about the
/// person using it rather than about the ledger.
final preferencesStoreProvider = FutureProvider<PreferencesStore>((ref) async {
  final opened = await ref.watch(controlDatabaseProvider).open();
  return opened.when(
    ok: PreferencesStore.new,
    err: (failure) => throw StateError(failure.message),
  );
});
