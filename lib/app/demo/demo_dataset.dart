import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

/// A generated ledger: transactions and budgets, and nothing else.
@immutable
class DemoDataset extends Equatable {
  /// Creates a dataset.
  const DemoDataset({required this.transactions, required this.budgets});

  /// Every generated transaction, oldest first.
  final List<Transaction> transactions;

  /// Every generated budget.
  final List<Budget> budgets;

  @override
  List<Object?> get props => [transactions, budgets];
}

/// A deterministic sequence, deliberately not `dart:math`'s `Random`.
///
/// `Random(seed)` is not documented to produce the same sequence across Dart
/// releases, so a dataset built on it can change under an SDK upgrade — and the
/// symptom would be a test failing for a reason nowhere in the diff. Twelve
/// lines of arithmetic buys a sequence that is stable forever.
///
/// The constants are Numerical Recipes' 32-bit LCG. Quality is irrelevant here;
/// reproducibility is the whole requirement.
@visibleForTesting
class DemoRandom {
  /// Creates a sequence from [seed].
  DemoRandom(this.seed) : _state = seed;

  /// The seed this sequence started from.
  final int seed;
  int _state;

  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;
  static const int _modulus = 1 << 32;

  /// The next value in `0..bound-1`.
  int next(int bound) {
    assert(bound > 0, 'bound must be positive, got $bound');
    _state = (_state * _multiplier + _increment) % _modulus;
    return _state % bound;
  }

  /// The next value in `low..high`, inclusive.
  int between(int low, int high) {
    assert(high >= low, 'high must not be below low');
    return low + next(high - low + 1);
  }

  /// True with probability `numerator/denominator`.
  bool chance(int numerator, int denominator) => next(denominator) < numerator;
}

/// How much of the spending each expense category takes, and what one purchase
/// in it costs.
///
/// **These numbers are invented.** They come from nowhere in Figma and nowhere
/// in this repository, and that is correct here: the values *are* the dummy
/// data, and there is no source of truth for what a fictional person spent on
/// coffee. What has to be true is structural — every category present, totals
/// distinct, amounts whole and positive — and the tests assert those rather
/// than any number below. Tune them freely.
@visibleForTesting
class DemoCategoryWeight {
  /// Creates a weight.
  const DemoCategoryWeight({
    required this.category,
    required this.share,
    required this.lowMinor,
    required this.highMinor,
  });

  /// Which category.
  final SpendCategory category;

  /// Relative frequency, out of the sum of every share.
  final int share;

  /// Cheapest single purchase, in minor units.
  final int lowMinor;

  /// Dearest single purchase, in minor units.
  final int highMinor;
}

/// The weights, largest first. Salary is absent: it is income and is generated
/// on its own cycle.
///
/// The ceilings were tuned once, after looking at what the generated month
/// actually said: `bills` came out at **43%** of spending and `food` at 9%,
/// because a 1.9M ceiling on a 12%-frequency category beats a 420k ceiling on
/// a 34% one. Plausible-looking dummy data is the whole point, so the ceilings
/// now put food first — which is also the shape `47:62`'s own sample has.
@visibleForTesting
const List<DemoCategoryWeight> demoCategoryWeights = [
  DemoCategoryWeight(
    category: SpendCategory.food,
    share: 34,
    lowMinor: 25000,
    highMinor: 420000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.transport,
    share: 20,
    lowMinor: 15000,
    highMinor: 260000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.shopping,
    share: 14,
    lowMinor: 90000,
    highMinor: 600000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.bills,
    share: 12,
    lowMinor: 180000,
    highMinor: 500000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.entertainment,
    share: 9,
    lowMinor: 60000,
    highMinor: 500000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.health,
    share: 7,
    lowMinor: 50000,
    highMinor: 600000,
  ),
  DemoCategoryWeight(
    category: SpendCategory.gift,
    share: 4,
    lowMinor: 100000,
    highMinor: 800000,
  ),
];

/// Merchant-flavoured notes, so the ledger reads like someone's actual month
/// rather than seven repeated rows.
///
/// **Invented, like the weights** — see the note on [demoCategoryWeights].
/// Recognisable Vietnamese and international names because the wallet is VND
/// and a demo of a finance app is much easier to read when the rows look like
/// somewhere you have been. Nothing here is a real transaction and no test
/// depends on any particular string.
const Map<SpendCategory, List<String>> _notes = {
  SpendCategory.food: [
    'Highlands Coffee',
    'The Coffee House',
    'Bánh mì Huỳnh Hoa',
    'Phở Thìn',
    'Cơm tấm Ba Ghiền',
    'VinMart+',
    'Circle K',
    'Bún bò Huế',
    "Pizza 4P's",
    'Trà sữa Phúc Long',
  ],
  SpendCategory.transport: [
    'Grab Bike',
    'Grab Car',
    'Be',
    'Xăng Petrolimex',
    'Metro card top-up',
    'Parking — Vincom',
    'Xanh SM taxi',
  ],
  SpendCategory.shopping: [
    'Shopee',
    'Uniqlo',
    'Lazada',
    'Muji',
    'Nhà sách Fahasa',
    'Decathlon',
    'Điện Máy Xanh',
  ],
  SpendCategory.bills: [
    'EVN — electricity',
    'SAWACO — water',
    'Viettel fibre',
    'Mobifone top-up',
    'Apartment service fee',
    'Netflix',
    'Spotify',
  ],
  SpendCategory.entertainment: [
    'CGV Cinemas',
    'Galaxy Cinema',
    'Bowling — Vincom',
    'Concert ticket',
    'Steam',
    'Bể bơi Lan Anh',
  ],
  SpendCategory.health: [
    'Pharmacity',
    'Long Châu pharmacy',
    'Dentist — Nha khoa Kim',
    'California Fitness',
    'Vinmec check-up',
    'Eye test',
  ],
  SpendCategory.gift: [
    'Birthday — Linh',
    'Wedding — Minh & Hà',
    'Tết lucky money',
    'Flowers',
    'Housewarming',
  ],
  SpendCategory.salary: ['Salary — NIK Technology'],
};

/// Generates the demo ledger.
///
/// Pure: no I/O, no globals. Both sources of non-determinism are parameters —
/// [clock] and [ids] — because the production `SystemIdGenerator` is
/// `Random.secure()` plus the wall clock, so a dataset built with it would not
/// be reproducible even though every test that injects a fixed generator would
/// pass.
///
/// Anchored to [clock] rather than to a fixed calendar, so the ledger always
/// looks current: it spans [monthsOfHistory] whole months up to the clock's own
/// month, and nothing is dated after the clock.
DemoDataset generateDemoDataset({
  required Clock clock,
  required IdGenerator ids,
  Currency currency = Currency.vnd,
  int seed = defaultDemoSeed,
  int monthsOfHistory = defaultMonthsOfHistory,
}) {
  final random = DemoRandom(seed);
  final now = clock.nowUtc();
  final createdAt = now;

  final transactions = <Transaction>[];
  final shareTotal = demoCategoryWeights.fold<int>(
    0,
    (sum, weight) => sum + weight.share,
  );

  // Oldest month first, so the list is chronological and a reader of the raw
  // dataset sees it the way the ledger grew.
  for (var back = monthsOfHistory - 1; back >= 0; back--) {
    final monthStart = DateTime.utc(now.year, now.month - back);
    final nextMonth = DateTime.utc(now.year, now.month - back + 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;

    // Salary: the same day of the month every month, which is what makes it
    // read as a cycle rather than as another random row.
    final payday = DateTime.utc(
      monthStart.year,
      monthStart.month,
      salaryDayOfMonth,
      9,
    );
    if (!payday.isAfter(now)) {
      transactions.add(
        _transaction(
          ids: ids,
          amount: Money(salaryMinor, currency),
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
          at: payday,
          createdAt: createdAt,
          note: _notes[SpendCategory.salary]!.first,
        ),
      );
    }

    final count = random.between(
      transactionsPerMonthLow,
      transactionsPerMonthHigh,
    );
    for (var i = 0; i < count; i++) {
      final weight = _pickWeight(random, shareTotal);
      final day = random.between(1, daysInMonth);
      final at = DateTime.utc(
        monthStart.year,
        monthStart.month,
        day,
        random.between(7, 21),
        random.between(0, 59),
      );
      // The current month is only partly over. A transaction dated tomorrow
      // would break every "this month" aggregate in the app.
      if (at.isAfter(now)) continue;

      final options = _notes[weight.category]!;
      transactions.add(
        _transaction(
          ids: ids,
          amount: Money(
            random.between(weight.lowMinor, weight.highMinor),
            currency,
          ),
          direction: TransactionDirection.expense,
          category: weight.category,
          at: at,
          createdAt: createdAt,
          note: options[random.next(options.length)],
        ),
      );
    }

    // Every expense category, every month — including a current month that is
    // only part over. Left to the weights alone this was *probabilistic*: at a
    // 4% share, `gift` was simply missing from a 17-day month, and the spec
    // scenario "every expense category appears in the current month" failed.
    // A guarantee that holds for one seed and breaks on the next tuning of the
    // weight table is not a guarantee.
    final lastDay = monthStart.month == now.month && monthStart.year == now.year
        ? now.day
        : daysInMonth;
    for (final weight in demoCategoryWeights) {
      final present = transactions.any(
        (t) =>
            t.category == weight.category &&
            t.occurredAt.year == monthStart.year &&
            t.occurredAt.month == monthStart.month,
      );
      if (present) continue;
      final at = DateTime.utc(
        monthStart.year,
        monthStart.month,
        random.between(1, lastDay),
        random.between(7, 21),
      );
      if (at.isAfter(now)) continue;
      final options = _notes[weight.category]!;
      transactions.add(
        _transaction(
          ids: ids,
          amount: Money(
            random.between(weight.lowMinor, weight.highMinor),
            currency,
          ),
          direction: TransactionDirection.expense,
          category: weight.category,
          at: at,
          createdAt: createdAt,
          note: options[random.next(options.length)],
        ),
      );
    }
  }

  // One deliberately large purchase, so the widest amount the screens have to
  // render is actually present rather than assumed absent.
  final largeAt = DateTime.utc(now.year, now.month - 2, 12, 15);
  transactions.add(
    _transaction(
      ids: ids,
      amount: Money(largePurchaseMinor, currency),
      direction: TransactionDirection.expense,
      category: SpendCategory.shopping,
      at: largeAt,
      createdAt: createdAt,
      note: 'MacBook Air — Thế Giới Di Động',
    ),
  );

  // Chronological, so a reader of the raw dataset sees it the way the ledger
  // grew, and so `list` and the generator agree about order.
  final ordered = [...transactions]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  return DemoDataset(
    transactions: ordered,
    budgets: _budgets(
      ids: ids,
      transactions: ordered,
      now: now,
      currency: currency,
      createdAt: createdAt,
    ),
  );
}

/// Seed the dataset is generated from. One dataset, one seed.
const int defaultDemoSeed = 20260910;

/// Whole months of history, ending with the current one.
const int defaultMonthsOfHistory = 15;

/// Day of the month salary arrives.
///
/// Early in the month on purpose. On the 25th, a demo opened before the 25th
/// showed **zero income for the current month** — so the cash-flow chart's
/// income line dropped to the baseline for its most recent point and Insights
/// reported income of 0 ₫. The 5th means any demo after the 5th has a full
/// month of both directions.
const int salaryDayOfMonth = 5;

/// Monthly salary, in minor units.
const int salaryMinor = 32000000;

/// The one large purchase, in minor units.
const int largePurchaseMinor = 38500000;

/// Fewest generated expenses in a month.
const int transactionsPerMonthLow = 68;

/// Most generated expenses in a month.
const int transactionsPerMonthHigh = 92;

Transaction _transaction({
  required IdGenerator ids,
  required Money amount,
  required TransactionDirection direction,
  required SpendCategory category,
  required DateTime at,
  required DateTime createdAt,
  required String note,
}) {
  final result = Transaction.create(
    id: ids.next(),
    amount: amount,
    direction: direction,
    category: category,
    occurredAt: at,
    createdAt: createdAt,
    note: note,
  );
  // Deliberately not caught. Every value here is generated by this file, so a
  // rejection is a bug in the generator rather than a storage failure, and it
  // should stop the seed loudly instead of quietly producing a shorter ledger.
  return result.when(
    ok: (transaction) => transaction,
    err: (failure) => throw StateError(
      'the generator produced a transaction the domain rejects: '
      '${failure.message}',
    ),
  );
}

DemoCategoryWeight _pickWeight(DemoRandom random, int shareTotal) {
  var roll = random.next(shareTotal);
  for (final weight in demoCategoryWeights) {
    if (roll < weight.share) return weight;
    roll -= weight.share;
  }
  return demoCategoryWeights.last;
}

/// Budgets chosen so that, evaluated at [now], one is over its limit, one is
/// near it and one is on track — and all three periods are represented.
///
/// The limits are derived from the spending actually generated, not guessed: a
/// hardcoded limit would drift into the wrong state on any tuning of the weight
/// table, and a demo ledger whose budgets are all comfortably on track shows a
/// reviewer nothing.
List<Budget> _budgets({
  required IdGenerator ids,
  required List<Transaction> transactions,
  required DateTime now,
  required Currency currency,
  required DateTime createdAt,
}) {
  final monthStart = DateTime.utc(now.year, now.month);
  final weekStart = DateTime.utc(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  final yearStart = DateTime.utc(now.year);

  int spentIn(SpendCategory category, DateTime from) => transactions
      .where(
        (t) =>
            t.category == category &&
            t.direction == TransactionDirection.expense &&
            !t.occurredAt.isBefore(from) &&
            !t.occurredAt.isAfter(now),
      )
      .fold(0, (sum, t) => sum + t.amount.minorUnits);

  Budget budget({
    required SpendCategory category,
    required BudgetPeriod period,
    required DateTime startsOn,
    required int limitMinor,
  }) {
    final result = Budget.create(
      id: ids.next(),
      category: category,
      // A limit of zero is rejected by the domain, and a category with no
      // spending in the window would produce one.
      limit: Money(limitMinor < 1000 ? 1000 : limitMinor, currency),
      period: period,
      startsOn: startsOn,
      createdAt: createdAt,
    );
    return result.when(
      ok: (value) => value,
      err: (failure) => throw StateError(
        'the generator produced a budget the domain rejects: '
        '${failure.message}',
      ),
    );
  }

  // Over: the limit is below what has already been spent this month.
  final foodSpent = spentIn(SpendCategory.food, monthStart);
  // Near the limit: spent is just under the default 80% alert threshold's
  // reciprocal, so the ratio lands between 0.8 and 1.0.
  final transportSpent = spentIn(SpendCategory.transport, weekStart);
  // On track: a limit comfortably above a year's spending in the category.
  final giftSpent = spentIn(SpendCategory.gift, yearStart);

  return [
    budget(
      category: SpendCategory.food,
      period: BudgetPeriod.monthly,
      startsOn: monthStart,
      limitMinor: (foodSpent * 100) ~/ overBudgetPercent,
    ),
    budget(
      category: SpendCategory.transport,
      period: BudgetPeriod.weekly,
      startsOn: weekStart,
      limitMinor: (transportSpent * 100) ~/ nearLimitPercent,
    ),
    budget(
      category: SpendCategory.gift,
      period: BudgetPeriod.yearly,
      startsOn: yearStart,
      limitMinor: (giftSpent * 100) ~/ onTrackPercent,
    ),
  ];
}

/// Where the over-budget budget lands, as a percentage of its limit.
const int overBudgetPercent = 118;

/// Where the near-limit budget lands. Above the default 80% alert threshold and
/// below 100%.
const int nearLimitPercent = 88;

/// Where the on-track budget lands. Comfortably below the alert threshold.
const int onTrackPercent = 41;
