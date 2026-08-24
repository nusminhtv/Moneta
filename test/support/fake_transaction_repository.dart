import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';

/// In-memory repository for presentation tests.
///
/// Mirrors the SQLite implementation's *contract*, not its internals: the same
/// ordering, the same not-found on a missing delete, the same rejection of a
/// duplicate id. Where the two could drift, the data-layer tests cover the real
/// one; this exists so a screen test does not need a database.
final class FakeTransactionRepository implements TransactionRepository {
  /// Creates a fake, optionally pre-populated.
  FakeTransactionRepository({
    List<Transaction>? initial,
    this.currency = Currency.vnd,
  }) : _items = [...?initial];

  final List<Transaction> _items;

  /// Currency the fake wallet is denominated in.
  final Currency currency;

  /// When set, every method fails with this instead of succeeding.
  AppFailure? failWith;

  /// How many times [list] has been called, so a test can prove a refresh
  /// happened rather than inferring it from the result.
  int listCalls = 0;

  /// Current contents, newest first.
  List<Transaction> get items => List.unmodifiable(_sorted());

  List<Transaction> _sorted() {
    return [..._items]..sort((a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
  }

  @override
  Future<Result<List<Transaction>>> list(TransactionQuery query) async {
    listCalls++;
    final failure = failWith;
    if (failure != null) return Err(failure);

    return Ok([
      for (final item in _sorted())
        if ((query.categories.isEmpty ||
                query.categories.contains(item.category)) &&
            query.containsInstant(item.occurredAt))
          item,
    ]);
  }

  @override
  Future<Result<Transaction>> add(Transaction transaction) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    if (_items.any((t) => t.id == transaction.id)) {
      return Err(AppFailure.storage('Duplicate id "${transaction.id}"'));
    }
    _items.add(transaction);
    return Ok(transaction);
  }

  @override
  Future<Result<void>> delete(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    final before = _items.length;
    _items.removeWhere((t) => t.id == id);
    if (_items.length == before) {
      return Err(AppFailure.notFound('No transaction with id "$id"'));
    }
    return const Ok(null);
  }

  @override
  Future<Result<PeriodSummary>> summarise(TransactionQuery query) async {
    final failure = failWith;
    if (failure != null) return Err(failure);

    var income = 0;
    var expenses = 0;
    for (final item in _items) {
      if (query.categories.isNotEmpty &&
          !query.categories.contains(item.category)) {
        continue;
      }
      if (!query.containsInstant(item.occurredAt)) continue;
      if (item.isIncome) {
        income += item.amount.minorUnits;
      } else {
        expenses += item.amount.minorUnits;
      }
    }
    return Ok(
      PeriodSummary(
        income: Money(income, currency),
        expenses: Money(expenses, currency),
      ),
    );
  }
}
