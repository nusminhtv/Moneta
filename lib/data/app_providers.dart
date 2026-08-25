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

/// The application database.
///
/// Closed when the provider is disposed, so a test container does not leak
/// connections between cases.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(path: 'moneta.db', factory: databaseFactory);
  ref.onDispose(database.close);
  return database;
});

/// Key/value preference storage.
final preferencesStoreProvider = FutureProvider<PreferencesStore>((ref) async {
  final opened = await ref.watch(appDatabaseProvider).open();
  return opened.when(
    ok: PreferencesStore.new,
    err: (failure) => throw StateError(failure.message),
  );
});
