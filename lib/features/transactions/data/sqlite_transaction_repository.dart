import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/transactions/data/transaction_dao.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';

/// SQLite-backed [TransactionRepository].
///
/// This is the only layer that catches storage exceptions. Everything above it
/// sees [Result].
final class SqliteTransactionRepository implements TransactionRepository {
  /// Creates a repository over [dao].
  const SqliteTransactionRepository(this.dao, {this.currency = Currency.vnd});

  /// SQL access.
  final TransactionDao dao;

  /// Currency every stored amount is denominated in.
  ///
  /// Single-currency for now (see the change's non-goals). Kept explicit rather
  /// than hard-coded at each call site so adding currencies later is a change
  /// of one field, not a search.
  final Currency currency;

  @override
  Future<Result<List<Transaction>>> list(TransactionQuery query) async {
    try {
      return await dao.list(query);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not read transactions', cause: error),
      );
    }
  }

  @override
  Future<Result<Transaction>> add(Transaction transaction) async {
    if (transaction.amount.currency != currency) {
      return Err(
        AppFailure.validation(
          'This wallet is in ${currency.code}; got '
          '${transaction.amount.currency.code}',
        ),
      );
    }
    try {
      await dao.insert(transaction);
      return Ok(transaction);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not save the transaction', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (id.isEmpty) {
      return const Err(AppFailure.validation('A transaction id is required'));
    }
    try {
      final removed = await dao.delete(id);
      if (removed == 0) {
        // Reporting success here would hide a stale UI: the row the user tapped
        // is already gone, and they should be told rather than shown a no-op.
        return Err(AppFailure.notFound('No transaction with id "$id"'));
      }
      return const Ok(null);
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not delete the transaction', cause: error),
      );
    }
  }

  @override
  Future<Result<PeriodSummary>> summarise(TransactionQuery query) async {
    try {
      return Ok(await dao.summarise(query, currency));
    } on Object catch (error) {
      return Err(
        AppFailure.storage('Could not summarise the period', cause: error),
      );
    }
  }
}
