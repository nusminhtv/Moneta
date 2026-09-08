import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:sqflite/sqflite.dart';

/// SQL access to the `budgets` table.
///
/// Throws whatever `sqflite` throws. Converting to `Result` is the repository's
/// job, so the `try`/`catch` lives in exactly one layer.
final class BudgetDao {
  /// Creates a DAO over [db].
  const BudgetDao(this.db);

  /// The open connection.
  final DatabaseExecutor db;

  /// Table name.
  static const String table = 'budgets';

  /// Columns, in a fixed order, so a mapping mistake is visible in one place.
  static const List<String> columns = [
    'id',
    'category',
    'limit_minor',
    'currency',
    'period',
    'starts_on',
    'rolls_over',
    'alert_threshold',
    'created_at',
  ];

  /// Every budget.
  Future<List<Budget>> all() async {
    final rows = await db.query(table, columns: columns);
    return rows.map(fromRow).toList();
  }

  /// One budget, or null.
  Future<Budget?> byId(String id) async {
    final rows = await db.query(
      table,
      columns: columns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : fromRow(rows.first);
  }

  /// Whether a budget already covers this category and period.
  Future<bool> exists({
    required SpendCategory category,
    required BudgetPeriod period,
  }) async {
    final rows = await db.query(
      table,
      columns: const ['id'],
      where: 'category = ? AND period = ?',
      whereArgs: [category.name, period.name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Inserts a budget. Fails on the unique index if one already covers the
  /// same category and period.
  Future<void> insert(Budget budget) => db.insert(
    table,
    toRow(budget),
    conflictAlgorithm: ConflictAlgorithm.fail,
  );

  /// Replaces a budget by id.
  Future<int> update(Budget budget) => db.update(
    table,
    toRow(budget),
    where: 'id = ?',
    whereArgs: [budget.id],
  );

  /// Deletes a budget. Returns how many rows went.
  Future<int> delete(String id) =>
      db.delete(table, where: 'id = ?', whereArgs: [id]);

  /// Maps a budget onto a row.
  static Map<String, Object?> toRow(Budget budget) => {
    'id': budget.id,
    'category': budget.category.name,
    'limit_minor': budget.limit.minorUnits,
    'currency': budget.limit.currency.code,
    'period': budget.period.name,
    'starts_on': budget.startsOn.millisecondsSinceEpoch,
    // SQLite has no boolean. 0 and 1, converted in one place.
    'rolls_over': budget.rollsOver ? 1 : 0,
    'alert_threshold': budget.alertThreshold,
    'created_at': budget.createdAt.millisecondsSinceEpoch,
  };

  /// Maps a row back to a budget.
  ///
  /// Uses `Budget.fromStorage`, which does not re-validate: a row already in
  /// the database is a fact, and refusing to read it back because a rule
  /// changed afterwards would strand the user's own budgets.
  static Budget fromRow(Map<String, Object?> row) => Budget.fromStorage(
    id: row['id']! as String,
    category: SpendCategory.values.byName(row['category']! as String),
    limit: Money(
      row['limit_minor']! as int,
      Currency.fromCode(row['currency']! as String),
    ),
    period: BudgetPeriod.values.byName(row['period']! as String),
    startsOn: DateTime.fromMillisecondsSinceEpoch(
      row['starts_on']! as int,
      isUtc: true,
    ),
    rollsOver: (row['rolls_over']! as int) != 0,
    alertThreshold: (row['alert_threshold']! as num).toDouble(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ),
  );
}
