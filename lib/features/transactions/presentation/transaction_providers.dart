import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/transactions/data/sqlite_transaction_repository.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';

// clockProvider, idGeneratorProvider, walletCurrencyProvider and the database
// providers used to live here. They moved to lib/data/app_providers.dart when a
// second feature needed them — a feature may not import another feature, and
// the architecture checker said so. Re-exported so existing call sites and
// their test overrides keep working with one import.
export 'package:moneta/data/app_providers.dart'
    show
        activeDatabaseProvider,
        clockProvider,
        controlDatabaseProvider,
        demoModeProvider,
        idGeneratorProvider,
        walletCurrencyProvider;

/// The transaction repository.
final transactionRepositoryProvider = FutureProvider<TransactionRepository>((
  ref,
) async {
  final database = ref.watch(activeDatabaseProvider);
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
