import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/features/transactions/data/sqlite_transaction_repository.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' hide Transaction;

/// Time source. Overridden in tests with a [FixedClock].
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Identifier source. Overridden in tests with a [FixedIdGenerator].
final idGeneratorProvider = Provider<IdGenerator>((ref) => SystemIdGenerator());

/// The currency this wallet is denominated in.
///
/// Single-currency for now; a provider rather than a constant so the change
/// that adds currencies has one place to start.
final walletCurrencyProvider = Provider<Currency>((ref) => Currency.vnd);

/// The application database.
///
/// Closed when the provider is disposed, so a test container does not leak
/// connections between cases.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    path: p.join('moneta.db'),
    factory: databaseFactory,
  );
  ref.onDispose(database.close);
  return database;
});

/// The transaction repository.
///
/// Overridden wholesale in widget tests; the database providers above are only
/// used by the real app and by data-layer tests.
final transactionRepositoryProvider = FutureProvider<TransactionRepository>((
  ref,
) async {
  final database = ref.watch(appDatabaseProvider);
  final opened = await database.open();
  return opened.when(
    ok: (db) => SqliteTransactionRepository(
      TransactionDao(db),
      currency: ref.watch(walletCurrencyProvider),
    ),
    // Surfacing this as a thrown error is deliberate: a FutureProvider's error
    // state is what the UI already knows how to render, and a repository that
    // cannot be built is not something a caller can work around.
    err: (failure) => throw StateError(failure.message),
  );
});
