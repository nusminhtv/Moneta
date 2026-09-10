import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

void main() {
  // Mid-month on purpose: a clock on the 1st or the 28th hides off-by-one
  // errors in "the current month is only partly over".
  final anchor = DateTime.utc(2026, 9, 17, 14, 30);

  DemoDataset generate({DateTime? at, IdGenerator? ids, int? months}) =>
      generateDemoDataset(
        clock: FixedClock(at ?? anchor),
        ids: ids ?? FixedIdGenerator(prefix: 'demo'),
        monthsOfHistory: months ?? defaultMonthsOfHistory,
      );

  /// [source] with `//` and `///` comments removed, so a source-level check
  /// reads code rather than the prose explaining it.
  String codeOnly(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  String monthOf(Transaction t) =>
      '${t.occurredAt.year}-${t.occurredAt.month.toString().padLeft(2, '0')}';

  String transactionLine(Transaction t) =>
      '${t.id}|${t.amount.minorUnits}|${t.direction.name}|${t.category.name}'
      '|${t.occurredAt.toIso8601String()}|${t.note}';

  String budgetLine(Budget b) =>
      '${b.id}|${b.category.name}|${b.limit.minorUnits}|${b.period.name}'
      '|${b.startsOn.toIso8601String()}';

  String fingerprint(DemoDataset dataset) => [
    for (final t in dataset.transactions) transactionLine(t),
    for (final b in dataset.budgets) budgetLine(b),
  ].join('\n');

  group('determinism', () {
    test('two runs at the same clock and seed are equal, ids included', () {
      expect(fingerprint(generate()), fingerprint(generate()));
    });

    test('the dataset value type compares equal, not just its fields', () {
      expect(generate(), generate());
    });

    test('a different seed gives different data', () {
      // Otherwise "deterministic" could be satisfied by ignoring the seed.
      final a = generateDemoDataset(
        clock: FixedClock(anchor),
        ids: FixedIdGenerator(prefix: 'demo'),
      );
      final b = generateDemoDataset(
        clock: FixedClock(anchor),
        ids: FixedIdGenerator(prefix: 'demo'),
        seed: defaultDemoSeed + 1,
      );
      expect(fingerprint(a), isNot(fingerprint(b)));
    });

    test('the generator reaches for no global clock or random source', () {
      // A signature check cannot see inside the body, so read the source. The
      // production id generator is `Random.secure()` plus `DateTime.now()`, so
      // a generator that built its own would be non-deterministic in
      // production while every test that injects one passed.
      // Comments stripped first: the class doc *names* `SystemIdGenerator` and
      // `Random.secure()` to explain why they are not used, and a check that
      // cannot tell prose from code would fail on its own rationale.
      final source = codeOnly(
        File('lib/app/demo/demo_dataset.dart').readAsStringSync(),
      );
      expect(source, isNot(contains('DateTime.now(')));
      expect(source, isNot(contains('SystemIdGenerator(')));
      expect(source, isNot(contains('Random.secure')));
      expect(
        source,
        contains('required IdGenerator ids'),
        reason: 'the id source must be a parameter',
      );
      expect(source, contains('required Clock clock'));
    });

    test('and that check can fail', () {
      // Guards the guard, both halves: the stripper must remove comments and
      // must NOT remove code.
      const counterfeit = '''
        /// Explains that DateTime.now() and Random.secure() are avoided.
        // SystemIdGenerator( in a comment too.
        final now = DateTime.now();
        final r = Random.secure();
      ''';
      final stripped = codeOnly(counterfeit);
      expect(stripped, contains('DateTime.now('));
      expect(stripped, contains('Random.secure'));
      expect(
        stripped,
        isNot(contains('Explains')),
        reason: 'the stripper did not strip',
      );
      expect(
        codeOnly('/// only DateTime.now() in prose'),
        isNot(contains('DateTime.now(')),
      );
    });
  });

  group('span and anchoring', () {
    test('fifteen whole months up to the clock month, all populated', () {
      final dataset = generate();
      final months = {for (final t in dataset.transactions) monthOf(t)};
      expect(months, hasLength(defaultMonthsOfHistory));
      expect(months, contains('2026-09'));
      // 15 months back from September 2026 is July 2025.
      expect(months, contains('2025-07'));
      expect(months, isNot(contains('2025-06')));
    });

    test('nothing is dated after the clock', () {
      // The clock is the 17th; the current month runs to the 30th, so a
      // generator that filled the whole month would fail here.
      final dataset = generate();
      for (final t in dataset.transactions) {
        expect(
          t.occurredAt.isAfter(anchor),
          isFalse,
          reason: '${t.note} on ${t.occurredAt} is in the future',
        );
      }
    });

    test('the current month is only partly filled', () {
      final dataset = generate();
      final thisMonth = dataset.transactions.where(
        (t) => t.occurredAt.year == 2026 && t.occurredAt.month == 9,
      );
      expect(thisMonth, isNotEmpty);
      expect(
        thisMonth.every((t) => t.occurredAt.day <= 17),
        isTrue,
      );
    });

    test('a clock a month later spans the same window, moved', () {
      final later = generate(at: DateTime.utc(2026, 10, 17, 14, 30));
      final months = {for (final t in later.transactions) monthOf(t)};
      expect(months, hasLength(defaultMonthsOfHistory));
      expect(months, contains('2026-10'));
      expect(months, contains('2025-08'));
      expect(months, isNot(contains('2025-07')));
    });

    test('a January clock crosses the year boundary correctly', () {
      final january = generate(at: DateTime.utc(2027, 1, 9, 10), months: 3);
      final months = {for (final t in january.transactions) monthOf(t)};
      expect(months, {'2026-11', '2026-12', '2027-01'});
    });

    test('every timestamp is UTC', () {
      for (final t in generate().transactions) {
        expect(t.occurredAt.isUtc, isTrue);
      }
    });

    test('the list is chronological', () {
      final transactions = generate().transactions;
      for (var i = 1; i < transactions.length; i++) {
        expect(
          transactions[i].occurredAt.isBefore(transactions[i - 1].occurredAt),
          isFalse,
        );
      }
    });
  });

  group('coverage of what the screens need', () {
    test('it is a substantial ledger, not a handful of rows', () {
      // A range, not a count: a fixture asserting an exact number would fail on
      // every tuning of the weight table and prove nothing about the ledger.
      expect(generate().transactions.length, greaterThan(900));
    });

    test('every expense category appears, with distinct totals', () {
      final dataset = generate();
      final totals = <SpendCategory, int>{};
      for (final t in dataset.transactions) {
        if (t.direction != TransactionDirection.expense) continue;
        totals[t.category] = (totals[t.category] ?? 0) + t.amount.minorUnits;
      }

      for (final weight in demoCategoryWeights) {
        expect(
          totals[weight.category],
          isNotNull,
          reason: '${weight.category.name} has no spending at all',
        );
      }
      expect(
        totals.values.toSet(),
        hasLength(totals.length),
        reason: 'two categories tied, so a ranked chart has no real order',
      );
    });

    test('every expense category appears in the current month too', () {
      final current = generate().transactions.where(
        (t) =>
            t.direction == TransactionDirection.expense &&
            t.occurredAt.year == 2026 &&
            t.occurredAt.month == 9,
      );
      expect(
        {for (final t in current) t.category},
        {for (final weight in demoCategoryWeights) weight.category},
      );
    });

    test('salary is income, monthly, on the same day every month', () {
      final salary = generate().transactions
          .where((t) => t.category == SpendCategory.salary)
          .toList();

      expect(salary, isNotEmpty);
      for (final t in salary) {
        expect(t.direction, TransactionDirection.income);
        expect(
          t.occurredAt.day,
          salaryDayOfMonth,
          reason: 'a cycle means the same day, not roughly monthly',
        );
      }
      // One per month, except the current one when payday has not arrived.
      expect(salary, hasLength(defaultMonthsOfHistory - 1));
    });

    test('income is only salary, and expense is never salary', () {
      for (final t in generate().transactions) {
        if (t.direction == TransactionDirection.income) {
          expect(t.category, SpendCategory.salary);
        } else {
          expect(t.category, isNot(SpendCategory.salary));
        }
      }
    });
  });

  group('budgets reach every state at the generating clock', () {
    test('all three periods are present', () {
      expect(
        {for (final b in generate().budgets) b.period},
        BudgetPeriod.values.toSet(),
      );
    });

    test('one over, one near the limit, one on track', () {
      final dataset = generate();
      final entries = [
        for (final t in dataset.transactions)
          SpendEntry(
            id: t.id,
            category: t.category,
            direction: t.direction,
            amount: t.amount,
            occurredAt: t.occurredAt,
          ),
      ];
      final statuses = <BudgetStatus>[];
      for (final budget in dataset.budgets) {
        statuses.add(
          BudgetProgress.compute(
            budget: budget,
            entries: entries,
            now: anchor,
          ).status,
        );
      }
      expect(
        statuses.toSet(),
        BudgetStatus.values.toSet(),
        reason:
            'a demo ledger whose budgets are all comfortably on track shows a '
            'reviewer nothing: got $statuses',
      );
    });

    test('every budget limit is positive, and none is zero', () {
      for (final budget in generate().budgets) {
        expect(budget.limit.minorUnits, greaterThan(0));
      }
    });

    test('budget dates are UTC', () {
      for (final budget in generate().budgets) {
        expect(budget.startsOn.isUtc, isTrue);
        expect(budget.createdAt.isUtc, isTrue);
      }
    });
  });

  group('amounts', () {
    test('every amount is a positive whole number of minor units', () {
      for (final t in generate().transactions) {
        expect(t.amount.minorUnits, greaterThan(0));
        expect(t.amount.currency, Currency.vnd);
      }
    });

    test('the weight table itself only offers positive whole amounts', () {
      // Asserted on the table rather than on the finished objects, because
      // `Transaction.create` already rejects a non-positive amount — so an
      // assertion on the output would test `transaction.dart` and would pass
      // for a generator that emitted nothing at all.
      for (final weight in demoCategoryWeights) {
        expect(weight.lowMinor, greaterThan(0));
        expect(weight.highMinor, greaterThanOrEqualTo(weight.lowMinor));
        expect(weight.share, greaterThan(0));
      }
      expect(salaryMinor, greaterThan(0));
      expect(largePurchaseMinor, greaterThan(0));
    });

    test('one deliberately large purchase is present', () {
      final largest = generate().transactions
          .where((t) => t.direction == TransactionDirection.expense)
          .map((t) => t.amount.minorUnits)
          .reduce((a, b) => a > b ? a : b);
      expect(largest, largePurchaseMinor);
      expect(
        largest,
        greaterThan(
          demoCategoryWeights
              .map((w) => w.highMinor)
              .reduce((a, b) => a > b ? a : b),
        ),
        reason:
            'the large row must be larger than the ordinary ceiling, or it '
            'is not exercising anything',
      );
    });

    test('the fifteen-month total is larger still', () {
      final total = generate().transactions
          .where((t) => t.direction == TransactionDirection.expense)
          .fold(0, (sum, t) => sum + t.amount.minorUnits);
      expect(total, greaterThan(largePurchaseMinor));
    });

    test('ids are unique', () {
      final dataset = generate();
      final ids = [
        for (final t in dataset.transactions) t.id,
        for (final b in dataset.budgets) b.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('DemoRandom is stable arithmetic, not dart:math', () {
    test('the same seed replays the same sequence', () {
      final a = [for (var i = 0; i < 40; i++) DemoRandom(7).next(1000)];
      final b = [for (var i = 0; i < 40; i++) DemoRandom(7).next(1000)];
      expect(a, b);
    });

    test('a sequence advances', () {
      final random = DemoRandom(7);
      final drawn = [for (var i = 0; i < 40; i++) random.next(1000)];
      expect(drawn.toSet().length, greaterThan(1));
    });

    test('between is inclusive at both ends and never escapes', () {
      final random = DemoRandom(99);
      final seen = <int>{};
      for (var i = 0; i < 2000; i++) {
        seen.add(random.between(3, 6));
      }
      expect(seen, {3, 4, 5, 6});
    });

    test('the sequence is not a counter', () {
      // Every other assertion in this group is satisfied by
      // `_state = _state + 1`: it replays from a seed, it advances, it covers
      // `between`'s range, and — because cycling every residue uniformly hits
      // each category in proportion to its share — even the dataset's
      // distribution tests pass. What a counter breaks is the one thing dummy
      // data is for: it makes amounts march upward in lockstep and categories
      // cycle in order. That is visible to a reviewer and was invisible to the
      // suite, so this is the assertion that tells the two apart.
      final random = DemoRandom(42);
      final drawn = [for (var i = 0; i < 200; i++) random.next(1000)];

      var descents = 0;
      for (var i = 1; i < drawn.length; i++) {
        if (drawn[i] < drawn[i - 1]) descents++;
      }
      expect(
        descents,
        greaterThan(drawn.length ~/ 4),
        reason:
            'a sequence that almost never decreases is a counter, not a '
            'pseudo-random draw',
      );
    });

    test('a bound of one is the only value', () {
      final random = DemoRandom(1);
      for (var i = 0; i < 10; i++) {
        expect(random.next(1), 0);
      }
    });
  });
}
