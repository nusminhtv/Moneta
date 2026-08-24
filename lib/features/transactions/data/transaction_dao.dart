import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
// sqflite exports its own `Transaction` (a database transaction). Hiding it
// keeps the unqualified name meaning our domain entity throughout this file.
import 'package:sqflite/sqflite.dart' hide Transaction;

/// A SQL statement and its positional arguments.
typedef SqlStatement = ({String sql, List<Object?> args});

/// SQL access to the `transactions` table.
///
/// Throws whatever `sqflite` throws. Converting to [Result] is the repository's
/// job, so the `try`/`catch` lives in exactly one layer.
final class TransactionDao {
  /// Creates a DAO over [db].
  const TransactionDao(this.db);

  /// The open connection.
  final DatabaseExecutor db;

  /// Table name.
  static const String table = 'transactions';

  /// Columns, in a fixed order, so a mapping mistake is visible in one place.
  static const List<String> columns = [
    'id',
    'amount_minor',
    'currency',
    'direction',
    'category',
    'occurred_at',
    'note',
    'created_at',
  ];

  /// Builds the SELECT for [query].
  ///
  /// Pure and public so the boundary semantics — inclusive start, exclusive
  /// end — can be asserted directly against the SQL, not only inferred from
  /// results.
  static SqlStatement buildListStatement(TransactionQuery query) {
    final where = <String>[];
    final args = <Object?>[];

    if (query.categories.isNotEmpty) {
      final placeholders = List.filled(query.categories.length, '?').join(', ');
      where.add('category IN ($placeholders)');
      args.addAll(query.categories.map((c) => c.name));
    }
    if (query.start != null) {
      where.add('occurred_at >= ?');
      args.add(query.start!.millisecondsSinceEpoch);
    }
    if (query.end != null) {
      where.add('occurred_at < ?');
      args.add(query.end!.millisecondsSinceEpoch);
    }

    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    // created_at then id break ties deterministically, so two transactions at
    // the same instant keep the same relative order on every read.
    final limit = query.limit == null ? '' : ' LIMIT ${query.limit}';

    return (
      sql:
          'SELECT ${columns.join(', ')} FROM $table$clause '
          'ORDER BY occurred_at DESC, created_at DESC, id DESC$limit',
      args: args,
    );
  }

  /// Builds the aggregate summary for [query]'s range.
  ///
  /// An aggregate, not a row read: folding rows in Dart makes the home screen
  /// an O(n) query that gets slower every month a person uses the app.
  static SqlStatement buildSummaryStatement(TransactionQuery query) {
    final where = <String>[];
    final args = <Object?>[];

    if (query.categories.isNotEmpty) {
      final placeholders = List.filled(query.categories.length, '?').join(', ');
      where.add('category IN ($placeholders)');
      args.addAll(query.categories.map((c) => c.name));
    }
    if (query.start != null) {
      where.add('occurred_at >= ?');
      args.add(query.start!.millisecondsSinceEpoch);
    }
    if (query.end != null) {
      where.add('occurred_at < ?');
      args.add(query.end!.millisecondsSinceEpoch);
    }

    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    return (
      sql:
          'SELECT direction, SUM(amount_minor) AS total, COUNT(*) AS count '
          'FROM $table$clause GROUP BY direction',
      args: args,
    );
  }

  /// Serialises [transaction] to a row.
  static Map<String, Object?> toRow(Transaction transaction) => {
    'id': transaction.id,
    'amount_minor': transaction.amount.minorUnits,
    'currency': transaction.amount.currency.code,
    'direction': transaction.direction.name,
    'category': transaction.category.name,
    'occurred_at': transaction.occurredAt.millisecondsSinceEpoch,
    'note': transaction.note,
    'created_at': transaction.createdAt.millisecondsSinceEpoch,
  };

  /// Parses a row back into a [Transaction].
  ///
  /// A row this app cannot understand — an unknown category or direction from a
  /// newer schema — is a [FailureKind.storage] failure, not a crash and not a
  /// guess.
  static Result<Transaction> fromRow(Map<String, Object?> row) {
    final direction = TransactionDirection.tryParse(
      row['direction']! as String,
    );
    if (direction == null) {
      return Err(
        AppFailure.storage('Unknown direction "${row['direction']}"'),
      );
    }
    final category = SpendCategory.tryParse(row['category']! as String);
    if (category == null) {
      return Err(AppFailure.storage('Unknown category "${row['category']}"'));
    }

    return Transaction.create(
      id: row['id']! as String,
      amount: Money(
        row['amount_minor']! as int,
        Currency.fromCode(row['currency']! as String),
      ),
      direction: direction,
      category: category,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at']! as int,
        isUtc: true,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      note: row['note'] as String?,
    );
  }

  /// Inserts [transaction].
  Future<void> insert(Transaction transaction) async {
    await db.insert(table, toRow(transaction));
  }

  /// Reads transactions matching [query], newest first.
  Future<Result<List<Transaction>>> list(TransactionQuery query) async {
    final statement = buildListStatement(query);
    final rows = await db.rawQuery(statement.sql, statement.args);

    final transactions = <Transaction>[];
    for (final row in rows) {
      final parsed = fromRow(row);
      // One unreadable row fails the whole read. Skipping it would silently
      // change a balance, which is worse than an error the user can see.
      if (parsed is Err<Transaction>) return Err(parsed.failure);
      transactions.add((parsed as Ok<Transaction>).value);
    }
    return Ok(transactions);
  }

  /// Deletes by id, returning how many rows were removed.
  Future<int> delete(String id) =>
      db.delete(table, where: 'id = ?', whereArgs: [id]);

  /// Totals for [query]'s range, in [currency].
  Future<PeriodSummary> summarise(
    TransactionQuery query,
    Currency currency,
  ) async {
    final statement = buildSummaryStatement(query);
    final rows = await db.rawQuery(statement.sql, statement.args);

    var income = 0;
    var expenses = 0;
    for (final row in rows) {
      final total = (row['total'] as int?) ?? 0;
      switch (TransactionDirection.tryParse(row['direction']! as String)) {
        case TransactionDirection.income:
          income = total;
        case TransactionDirection.expense:
          expenses = total;
        case null:
          // A direction this build does not know about cannot be attributed to
          // income or expenses, so it is excluded rather than guessed at.
          continue;
      }
    }

    return PeriodSummary(
      income: Money(income, currency),
      expenses: Money(expenses, currency),
    );
  }
}
