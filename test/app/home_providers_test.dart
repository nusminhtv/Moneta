import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

void main() {
  const vnd = Currency.vnd;
  const usd = Currency.usd;

  Transaction tx({
    required String id,
    required int minor,
    required TransactionDirection direction,
    Currency currency = vnd,
    SpendCategory category = SpendCategory.food,
    String? note,
    DateTime? at,
  }) => Transaction.create(
    id: id,
    amount: Money(minor, currency),
    direction: direction,
    category: category,
    occurredAt: at ?? DateTime.utc(2026, 8, 20, 10),
    createdAt: DateTime.utc(2026, 8, 20, 10),
    note: note,
  ).valueOrNull!;

  group('buildSnapshot', () {
    test('balance is income minus expenses', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(id: 'a', minor: 32000000, direction: TransactionDirection.income),
          tx(id: 'b', minor: 45000, direction: TransactionDirection.expense),
          tx(id: 'c', minor: 78000, direction: TransactionDirection.expense),
        ],
      );

      expect(snapshot.income, const Money(32000000, vnd));
      expect(snapshot.expenses, const Money(123000, vnd));
      expect(snapshot.totalBalance, const Money(31877000, vnd));
    });

    test('an empty wallet is zero, not a crash', () {
      final snapshot = buildSnapshot(all: [], currency: vnd);
      expect(snapshot.totalBalance, const Money.zero(vnd));
      expect(snapshot.income, const Money.zero(vnd));
      expect(snapshot.expenses, const Money.zero(vnd));
      expect(snapshot.isEmpty, isTrue);
    });

    test('spending more than earned gives a negative balance', () {
      // Not clamped to zero: an overdrawn wallet is a fact, and hiding it would
      // be the most expensive kind of rounding.
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(id: 'a', minor: 100000, direction: TransactionDirection.income),
          tx(id: 'b', minor: 250000, direction: TransactionDirection.expense),
        ],
      );
      expect(snapshot.totalBalance, const Money(-150000, vnd));
      expect(snapshot.totalBalance.isNegative, isTrue);
    });

    test('a very large amount does not overflow or lose precision', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(
            id: 'a',
            minor: 9007199254740991,
            direction: TransactionDirection.income,
          ),
        ],
      );
      expect(snapshot.totalBalance, const Money(9007199254740991, vnd));
    });

    test('a foreign currency is skipped, not silently added', () {
      // Adding 10 USD to a VND total would produce a number that is not money
      // in any currency. The wallet is single-currency today; this is where it
      // has to break loudly when it stops being.
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(id: 'a', minor: 100000, direction: TransactionDirection.income),
          tx(
            id: 'b',
            minor: 1000,
            direction: TransactionDirection.income,
            currency: usd,
          ),
        ],
      );
      expect(snapshot.income, const Money(100000, vnd));
    });

    test('recent is newest first and capped at the limit', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        limit: 2,
        all: [
          tx(
            id: 'old',
            minor: 1,
            direction: TransactionDirection.expense,
            at: DateTime.utc(2026, 8, 1),
          ),
          tx(
            id: 'new',
            minor: 2,
            direction: TransactionDirection.expense,
            at: DateTime.utc(2026, 8, 20),
          ),
          tx(
            id: 'mid',
            minor: 3,
            direction: TransactionDirection.expense,
            at: DateTime.utc(2026, 8, 10),
          ),
        ],
      );
      expect(snapshot.recent.map((e) => e.id), ['new', 'mid']);
    });

    test('the limit caps the list without changing the totals', () {
      // A summary that only summed what it displayed would show a balance that
      // disagrees with the transactions tab.
      final all = [
        for (var i = 0; i < 10; i++)
          tx(
            id: '$i',
            minor: 1000,
            direction: TransactionDirection.expense,
            at: DateTime.utc(2026, 8, i + 1),
          ),
      ];
      final snapshot = buildSnapshot(all: all, currency: vnd, limit: 2);
      expect(snapshot.recent, hasLength(2));
      expect(snapshot.expenses, const Money(10000, vnd));
    });
  });

  group('toRecentEntry', () {
    test('uses the note as the title', () {
      final entry = toRecentEntry(
        tx(
          id: 'a',
          minor: 1,
          direction: TransactionDirection.expense,
          note: 'Highlands Coffee',
        ),
      );
      expect(entry.title, 'Highlands Coffee');
    });

    test('falls back to the category when there is no note', () {
      for (final note in [null, '', '   ']) {
        final entry = toRecentEntry(
          tx(
            id: 'a',
            minor: 1,
            direction: TransactionDirection.expense,
            category: SpendCategory.salary,
            note: note,
          ),
        );
        expect(
          entry.title,
          SpendCategory.salary.label,
          reason:
              'a blank row reads as a rendering fault, not as an empty note',
        );
      }
    });

    test('carries the amount, direction, category and instant unchanged', () {
      final at = DateTime.utc(2026, 8, 20, 9, 24);
      final entry = toRecentEntry(
        tx(
          id: 'x',
          minor: 45000,
          direction: TransactionDirection.expense,
          category: SpendCategory.food,
          at: at,
        ),
      );
      expect(entry.id, 'x');
      expect(entry.amount, const Money(45000, vnd));
      expect(entry.direction, TransactionDirection.expense);
      expect(entry.category, SpendCategory.food);
      expect(entry.occurredAt, at);
    });
  });

  group('HomeSnapshot', () {
    test('empty reports itself empty', () {
      expect(HomeSnapshot.empty(vnd).isEmpty, isTrue);
    });

    test('two snapshots with the same content are equal', () {
      expect(HomeSnapshot.empty(vnd), HomeSnapshot.empty(vnd));
    });

    test('a snapshot with entries is not empty', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [tx(id: 'a', minor: 1, direction: TransactionDirection.expense)],
      );
      expect(snapshot.isEmpty, isFalse);
    });
  });

  group('the recent cap is five', () {
    // Annotation `52:362`: "Recent list is capped at 5 rows client-side."
    // This shipped as four, justified by counting the rows the frame draws.
    List<Transaction> many(int count) => [
      for (var i = 0; i < count; i++)
        tx(
          id: '$i',
          minor: 1000,
          direction: TransactionDirection.expense,
          at: DateTime.utc(2026, 8, i + 1),
        ),
    ];

    test('the default cap is five, not four', () {
      expect(homeRecentLimit, 5);
    });

    test('six transactions produce five rows', () {
      final snapshot = buildSnapshot(all: many(6), currency: vnd);
      expect(snapshot.recent, hasLength(5));
    });

    test('four transactions produce four rows and no padding', () {
      final snapshot = buildSnapshot(all: many(4), currency: vnd);
      expect(snapshot.recent, hasLength(4));
    });
  });

  group('safeToSpend', () {
    BudgetSummary summary({
      SpendCategory category = SpendCategory.food,
      int spent = 0,
      int limit = 5000000,
      Currency currency = vnd,
    }) => BudgetSummary(
      id: 'b-${category.name}',
      category: category,
      spent: Money(spent, currency),
      limit: Money(limit, currency),
      note: 'note',
    );

    test('with no budgets it is the balance', () {
      expect(
        safeToSpend(balance: const Money(10000000, vnd), budgets: const []),
        const Money(10000000, vnd),
      );
    });

    test('an untouched budget is subtracted in full', () {
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [summary(limit: 4000000)],
        ),
        const Money(6000000, vnd),
      );
    });

    test('only the unspent part is subtracted', () {
      // The spent 3m has already left the balance. Subtracting the whole 4m
      // limit would deduct it twice and understate the headroom by 3m.
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [summary(limit: 4000000, spent: 3000000)],
        ),
        const Money(9000000, vnd),
      );
    });

    test('a fully spent budget subtracts nothing further', () {
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [summary(limit: 4000000, spent: 4000000)],
        ),
        const Money(10000000, vnd),
      );
    });

    test('an overspent budget does not hand headroom back', () {
      // The clamp matters: an unclamped remainder would be negative here and
      // *raise* safe-to-spend because a budget was blown.
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [summary(limit: 4000000, spent: 6000000)],
        ),
        const Money(10000000, vnd),
      );
    });

    test('several budgets accumulate', () {
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [
            summary(limit: 4000000, spent: 1000000),
            summary(category: SpendCategory.transport, limit: 2000000),
          ],
        ),
        const Money(5000000, vnd),
      );
    });

    test('a foreign-currency budget is skipped, not added', () {
      expect(
        safeToSpend(
          balance: const Money(10000000, vnd),
          budgets: [summary(limit: 400, currency: usd)],
        ),
        const Money(10000000, vnd),
      );
    });

    test('it can go negative when budgets exceed the balance', () {
      // Not clamped at the top level: a user who has committed more than they
      // hold is exactly who needs to be told.
      expect(
        safeToSpend(
          balance: const Money(1000000, vnd),
          budgets: [summary(limit: 4000000)],
        ),
        const Money(-3000000, vnd),
      );
    });
  });

  group('buildSnapshot with budgets', () {
    test('safe to spend is on the snapshot, not the raw balance', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(
            id: 'in',
            minor: 10000000,
            direction: TransactionDirection.income,
          ),
        ],
        budgets: const [
          BudgetSummary(
            id: 'b1',
            category: SpendCategory.food,
            spent: Money.zero(vnd),
            limit: Money(4000000, vnd),
            note: 'note',
          ),
        ],
      );
      expect(snapshot.totalBalance, const Money(10000000, vnd));
      expect(snapshot.safeToSpend, const Money(6000000, vnd));
    });

    test('budgets are passed through in the order given', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: const [],
        budgets: const [
          BudgetSummary(
            id: 'b-transport',
            category: SpendCategory.transport,
            spent: Money.zero(vnd),
            limit: Money(1, vnd),
            note: 'a',
          ),
          BudgetSummary(
            id: 'b-food',
            category: SpendCategory.food,
            spent: Money.zero(vnd),
            limit: Money(1, vnd),
            note: 'b',
          ),
        ],
      );
      expect(
        snapshot.budgets.map((b) => b.category),
        [SpendCategory.transport, SpendCategory.food],
      );
    });

    test('with no budgets safe to spend equals the balance', () {
      final snapshot = buildSnapshot(
        currency: vnd,
        all: [
          tx(id: 'in', minor: 500, direction: TransactionDirection.income),
        ],
      );
      expect(snapshot.safeToSpend, snapshot.totalBalance);
      expect(snapshot.budgets, isEmpty);
    });
  });
}
