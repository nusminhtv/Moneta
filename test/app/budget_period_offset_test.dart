import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

/// The period switcher on `66:117`, which selects a period to look at.
///
/// It used to filter budgets by the *kind* of period they use, so tapping a
/// segment could empty a list of real budgets and drive the first-run empty
/// state. `66:117` labels its segments Jul / Aug / Sep.
void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 15);

  Budget budget({
    String id = 'b1',
    SpendCategory category = SpendCategory.food,
    BudgetPeriod period = BudgetPeriod.monthly,
    DateTime? startsOn,
    int limit = 4000000,
  }) => Budget.create(
    id: id,
    category: category,
    limit: Money(limit, vnd),
    period: period,
    startsOn: startsOn ?? DateTime.utc(2026, 1),
    createdAt: DateTime.utc(2026, 1),
  ).valueOrNull!;

  SpendEntry spend(int minor, DateTime at, {SpendCategory? category}) =>
      SpendEntry(
        id: 'e${at.microsecondsSinceEpoch}',
        category: category ?? SpendCategory.food,
        direction: TransactionDirection.expense,
        amount: Money(minor, vnd),
        occurredAt: at,
      );

  group('progressAt', () {
    test('offset zero is the current window', () {
      final p = progressAt(
        budget: budget(),
        entries: [spend(1000000, DateTime.utc(2026, 9, 10))],
        now: now,
        offset: 0,
      )!;
      expect(p.window.start, DateTime.utc(2026, 9));
      expect(p.spent, const Money(1000000, vnd));
    });

    test('offset one reads the previous window, not the current one', () {
      final p = progressAt(
        budget: budget(),
        entries: [
          spend(1000000, DateTime.utc(2026, 9, 10)),
          spend(2500000, DateTime.utc(2026, 8, 10)),
        ],
        now: now,
        offset: 1,
      )!;
      expect(p.window.start, DateTime.utc(2026, 8));
      expect(p.spent, const Money(2500000, vnd));
    });

    test('offset two goes back two windows', () {
      final p = progressAt(
        budget: budget(),
        entries: [spend(700000, DateTime.utc(2026, 7, 4))],
        now: now,
        offset: 2,
      )!;
      expect(p.window.start, DateTime.utc(2026, 7));
      expect(p.spent, const Money(700000, vnd));
    });

    test('a budget that did not exist that far back is null, not zeroed', () {
      // Its opening window under an earlier label would invent history.
      final young = budget(startsOn: DateTime.utc(2026, 9));
      expect(
        progressAt(budget: young, entries: const [], now: now, offset: 0),
        isNotNull,
      );
      expect(
        progressAt(budget: young, entries: const [], now: now, offset: 1),
        isNull,
      );
    });

    test('each budget steps by its own period, not by a shared month', () {
      // A weekly budget one segment back means one week, not one month.
      final weekly = budget(
        period: BudgetPeriod.weekly,
        startsOn: DateTime.utc(2026, 9, 7),
      );
      final p = progressAt(
        budget: weekly,
        entries: const [],
        now: now,
        offset: 1,
      )!;
      expect(p.window.start, DateTime.utc(2026, 9, 7));
      expect(p.window.end, DateTime.utc(2026, 9, 14));
    });
  });

  group('progressAtOffset', () {
    test('every budget is present, whatever period it uses', () {
      // The defect: a monthly-vs-weekly filter dropped budgets from the list.
      final out = progressAtOffset(
        budgets: [
          budget(id: 'm', category: SpendCategory.food),
          budget(
            id: 'w',
            category: SpendCategory.transport,
            period: BudgetPeriod.weekly,
          ),
          budget(
            id: 'y',
            category: SpendCategory.shopping,
            period: BudgetPeriod.yearly,
          ),
        ],
        entries: const [],
        now: now,
        offset: 0,
      );
      expect(out.map((p) => p.budget.id), containsAll(['m', 'w', 'y']));
      expect(out, hasLength(3));
    });

    test('results are ranked worst first', () {
      final out = progressAtOffset(
        budgets: [
          budget(id: 'light', category: SpendCategory.food),
          budget(id: 'heavy', category: SpendCategory.transport),
        ],
        entries: [
          spend(100000, DateTime.utc(2026, 9, 2)),
          spend(
            3900000,
            DateTime.utc(2026, 9, 2),
            category: SpendCategory.transport,
          ),
        ],
        now: now,
        offset: 0,
      );
      expect(out.first.budget.id, 'heavy');
    });

    test('budgets too young for the offset drop out of that period', () {
      final out = progressAtOffset(
        budgets: [
          budget(id: 'old'),
          budget(
            id: 'new',
            category: SpendCategory.transport,
            startsOn: DateTime.utc(2026, 9),
          ),
        ],
        entries: const [],
        now: now,
        offset: 2,
      );
      expect(out.map((p) => p.budget.id), ['old']);
    });
  });

  group('budgetPeriodLabels', () {
    test('monthly budgets read as month names, newest last', () {
      final labels = budgetPeriodLabels(
        budgets: [budget()],
        now: now,
        locale: 'en_US',
      );
      expect(labels, ['Jul', 'Aug', 'Sep']);
    });

    test('the newest label is the period the user is in', () {
      final labels = budgetPeriodLabels(
        budgets: [budget()],
        now: now,
        locale: 'en_US',
      );
      expect(labels.last, 'Sep');
      expect(labels, hasLength(budgetPeriodSegments));
    });

    test('yearly budgets read as years', () {
      final labels = budgetPeriodLabels(
        budgets: [
          budget(period: BudgetPeriod.yearly, startsOn: DateTime.utc(2020)),
        ],
        now: now,
        locale: 'en_US',
      );
      expect(labels, ['2024', '2025', '2026']);
    });

    test('a wallet younger than the switcher still gets distinct labels', () {
      // The defect: walking back through BudgetWindow.previous stopped at the
      // anchor and reused the last window reached, so a budget created this
      // month produced [Sep, Sep, Sep] -- three identical segments, two of
      // which showed "nothing to show for this period". First-run path.
      final labels = budgetPeriodLabels(
        budgets: [budget(startsOn: DateTime.utc(2026, 9))],
        now: now,
        locale: 'en_US',
      );
      expect(labels, ['Jul', 'Aug', 'Sep']);
      expect(labels.toSet(), hasLength(budgetPeriodSegments));
    });

    test('a budget created last month gets distinct labels too', () {
      final labels = budgetPeriodLabels(
        budgets: [budget(startsOn: DateTime.utc(2026, 8))],
        now: now,
        locale: 'en_US',
      );
      expect(labels, ['Jul', 'Aug', 'Sep']);
    });

    test('labels never repeat, for any start date', () {
      for (final month in [1, 5, 8, 9]) {
        final labels = budgetPeriodLabels(
          budgets: [budget(startsOn: DateTime.utc(2026, month))],
          now: now,
          locale: 'en_US',
        );
        expect(
          labels.toSet(),
          hasLength(budgetPeriodSegments),
          reason: 'duplicate labels for a budget starting month $month',
        );
      }
    });

    test('labels do not depend on which budget comes back first', () {
      // BudgetDao.all() has no ORDER BY, and the labels used to read an anchor
      // from budgets.first -- so the same wallet could label the current
      // segment "Aug" on 15 September depending on row order.
      final first = budgetPeriodLabels(
        budgets: [
          budget(id: 'a', startsOn: DateTime.utc(2026, 1, 20)),
          budget(
            id: 'z',
            category: SpendCategory.transport,
            startsOn: DateTime.utc(2026, 1),
          ),
        ],
        now: now,
        locale: 'en_US',
      );
      final reversed = budgetPeriodLabels(
        budgets: [
          budget(
            id: 'z',
            category: SpendCategory.transport,
            startsOn: DateTime.utc(2026, 1),
          ),
          budget(id: 'a', startsOn: DateTime.utc(2026, 1, 20)),
        ],
        now: now,
        locale: 'en_US',
      );
      expect(first, reversed);
      expect(first.last, 'Sep', reason: 'the newest segment is the month now');
    });

    test('mixed periods fall back to relative words', () {
      // "Aug" beside a weekly budget's window would be a lie, and one row of
      // three labels has to serve the whole switcher.
      final labels = budgetPeriodLabels(
        budgets: [
          budget(id: 'm'),
          budget(
            id: 'w',
            category: SpendCategory.transport,
            period: BudgetPeriod.weekly,
          ),
        ],
        now: now,
        locale: 'en_US',
      );
      expect(labels, ['Two back', 'Last', 'This']);
    });

    test('no budgets falls back too, rather than guessing a period', () {
      expect(
        budgetPeriodLabels(budgets: const [], now: now, locale: 'en_US'),
        ['Two back', 'Last', 'This'],
      );
    });
  });
}
