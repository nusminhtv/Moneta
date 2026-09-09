import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/notification_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

/// The notification centre's contents, against the five rows on `57:622`.
///
/// Three of the five are produced; two depend on features that do not exist.
void main() {
  const vnd = Currency.vnd;
  final september = DateTime.utc(2026, 9);
  final now = DateTime.utc(2026, 9, 20, 12);

  Budget budget({
    String id = 'b1',
    SpendCategory category = SpendCategory.shopping,
    Money limit = const Money(4000000, vnd),
    BudgetPeriod period = BudgetPeriod.monthly,
    DateTime? startsOn,
  }) => Budget.create(
    id: id,
    category: category,
    limit: limit,
    period: period,
    startsOn: startsOn ?? september,
    createdAt: DateTime.utc(2026, 8, 30),
    rollsOver: false,
    alertThreshold: 0.8,
  ).valueOrNull!;

  SpendEntry spend(
    int minor, {
    required DateTime at,
    SpendCategory category = SpendCategory.shopping,
    String id = 'e1',
  }) => SpendEntry(
    id: id,
    category: category,
    direction: TransactionDirection.expense,
    amount: Money(minor, vnd),
    occurredAt: at,
  );

  BudgetProgress progress({
    Budget? b,
    List<SpendEntry> entries = const [],
  }) => BudgetProgress.compute(
    budget: b ?? budget(),
    entries: entries,
    now: now,
  );

  Transaction tx({
    String id = 't1',
    int minor = 32000000,
    TransactionDirection direction = TransactionDirection.income,
    SpendCategory category = SpendCategory.salary,
    String? note,
    DateTime? at,
  }) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: direction,
    category: category,
    occurredAt: at ?? now.subtract(const Duration(hours: 8)),
    createdAt: DateTime.utc(2026, 9, 1),
    note: note,
  ).valueOrNull!;

  /// A budget pushed past its limit by one late entry.
  BudgetProgress overShopping() => progress(
    entries: [
      spend(4740000, at: now.subtract(const Duration(hours: 2))),
    ],
  );

  group('nothing to report', () {
    test('no budgets and no transactions produce no notifications', () {
      expect(
        deriveNotifications(
          budgets: const [],
          transactions: const [],
          now: now,
        ),
        isEmpty,
      );
    });

    test('an on-track budget raises no over-limit notice', () {
      final result = deriveNotifications(
        budgets: [
          progress(entries: [spend(1000000, at: september)]),
        ],
        transactions: const [],
        now: now,
      );
      expect(
        result.where((n) => n.kind == NotificationKind.budgetOverLimit),
        isEmpty,
      );
    });

    test('an expense raises nothing on its own', () {
      final result = deriveNotifications(
        budgets: const [],
        transactions: [tx(direction: TransactionDirection.expense)],
        now: now,
      );
      expect(result, isEmpty);
    });
  });

  group('budget over limit — 57:662', () {
    test('names the category and how far over', () {
      final result = deriveNotifications(
        budgets: [overShopping()],
        transactions: const [],
        now: now,
      );
      final entry = result.firstWhere(
        (n) => n.kind == NotificationKind.budgetOverLimit,
      );
      expect(entry.title, 'Shopping is over budget');
      expect(entry.detail, contains('over'));
      expect(entry.detail, contains('2 hours ago'));
      expect(entry.icon, MonetaIconName.alertTriangle);
    });

    test('is actionable and carries the budget it opens', () {
      final result = deriveNotifications(
        budgets: [overShopping()],
        transactions: const [],
        now: now,
      );
      final entry = result.firstWhere(
        (n) => n.kind == NotificationKind.budgetOverLimit,
      );
      expect(entry.isActionable, isTrue);
      expect(entry.targetId, 'b1');
    });

    test(
      'is dated when the budget tipped over, not when the list was built',
      () {
        // A notification dated "now" would climb back to the top of the list
        // every time the screen opened.
        final result = deriveNotifications(
          budgets: [overShopping()],
          transactions: const [],
          now: now,
        );
        final entry = result.firstWhere(
          (n) => n.kind == NotificationKind.budgetOverLimit,
        );
        expect(entry.occurredAt, isNot(now));
        expect(entry.occurredAt, now.subtract(const Duration(hours: 2)));
      },
    );

    test('one notice per over-limit budget', () {
      final other = budget(id: 'b2', category: SpendCategory.food);
      final result = deriveNotifications(
        budgets: [
          overShopping(),
          progress(
            b: other,
            entries: [
              spend(
                9000000,
                at: now.subtract(const Duration(hours: 5)),
                category: SpendCategory.food,
                id: 'e2',
              ),
            ],
          ),
        ],
        transactions: const [],
        now: now,
      );
      expect(
        result.where((n) => n.kind == NotificationKind.budgetOverLimit),
        hasLength(2),
      );
    });
  });

  group('income received — 57:688', () {
    test('names the category and the amount with its sign', () {
      final result = deriveNotifications(
        budgets: const [],
        transactions: [tx(note: 'NUS Technology')],
        now: now,
      );
      final entry = result.single;
      expect(entry.title, 'Salary received');
      expect(entry.detail, startsWith('+'));
      expect(entry.detail, contains('from NUS Technology'));
      expect(entry.detail, contains('8 hours ago'));
    });

    test('omits the source when the transaction has no note', () {
      final result = deriveNotifications(
        budgets: const [],
        transactions: [tx()],
        now: now,
      );
      expect(result.single.detail, isNot(contains('from')));
    });

    test('omits the source when the note is only whitespace', () {
      final result = deriveNotifications(
        budgets: const [],
        transactions: [tx(note: '   ')],
        now: now,
      );
      expect(result.single.detail, isNot(contains('from')));
    });

    test('the glyph comes from the category, not from the kind', () {
      // 57:688 uses icon/briefcase, which is what SpendCategory.salary names.
      // Hard-coding a briefcase would put the wrong glyph on a gift.
      final salary = deriveNotifications(
        budgets: const [],
        transactions: [tx()],
        now: now,
      ).single;
      final gift = deriveNotifications(
        budgets: const [],
        transactions: [tx(category: SpendCategory.gift)],
        now: now,
      ).single;

      expect(salary.icon, MonetaIconName.briefcase);
      expect(gift.icon, MonetaIconName.gift);
      expect(salary.icon, isNot(gift.icon));
    });

    test('every income transaction is reported, with no threshold', () {
      // "Notify above X" is a rule the design never states, and a made-up
      // threshold would silently decide which income is worth mentioning.
      final result = deriveNotifications(
        budgets: const [],
        transactions: [
          tx(id: 'a', minor: 1),
          tx(id: 'b', minor: 500000000),
        ],
        now: now,
      );
      expect(result, hasLength(2));
    });

    test('is actionable but carries no target', () {
      final entry = deriveNotifications(
        budgets: const [],
        transactions: [tx()],
        now: now,
      ).single;
      expect(entry.isActionable, isTrue);
      expect(entry.targetId, isNull);
    });
  });

  group('budgets reset — 57:773', () {
    test('one notice however many budgets there are', () {
      final result = deriveNotifications(
        budgets: [
          progress(),
          progress(b: budget(id: 'b2')),
        ],
        transactions: const [],
        now: now,
      );
      expect(
        result.where((n) => n.kind == NotificationKind.budgetPeriodEnding),
        hasLength(1),
      );
    });

    test('names the days left and the month that starts fresh', () {
      final entry = deriveNotifications(
        budgets: [progress()],
        transactions: const [],
        now: now,
        locale: 'en_US',
      ).firstWhere((n) => n.kind == NotificationKind.budgetPeriodEnding);

      // Monthly, anchored 1 Sep, read at noon on 20 Sep. September has 30
      // days, so 1 Oct 00:00 is 10 days and 12 hours away, and whole days
      // truncate to 10 — not the 11 you get by counting calendar dates.
      expect(entry.title, 'Budgets reset in 10 days');
      expect(entry.detail, contains('October budgets will start fresh'));
      expect(entry.icon, MonetaIconName.calendar);
    });

    test('is informational, so it leads nowhere', () {
      final entry = deriveNotifications(
        budgets: [progress()],
        transactions: const [],
        now: now,
      ).firstWhere((n) => n.kind == NotificationKind.budgetPeriodEnding);
      expect(entry.isActionable, isFalse);
      expect(entry.targetId, isNull);
    });

    test('uses the soonest window when periods differ', () {
      // A weekly budget resets before a monthly one, and that is the reset the
      // user actually meets next.
      final result = deriveNotifications(
        budgets: [
          progress(),
          progress(
            b: budget(
              id: 'b2',
              period: BudgetPeriod.weekly,
              startsOn: DateTime.utc(2026, 9, 14),
            ),
          ),
        ],
        transactions: const [],
        now: now,
        locale: 'en_US',
      );
      final entry = result.firstWhere(
        (n) => n.kind == NotificationKind.budgetPeriodEnding,
      );
      // 21 Sep is the weekly reset; the monthly one would have said 10 days.
      expect(entry.title, 'Budgets reset in 1 day');
    });

    test('is absent when there are no budgets', () {
      final result = deriveNotifications(
        budgets: const [],
        transactions: [tx()],
        now: now,
      );
      expect(
        result.where((n) => n.kind == NotificationKind.budgetPeriodEnding),
        isEmpty,
      );
    });
  });

  group('ordering', () {
    test('newest first across kinds', () {
      final result = deriveNotifications(
        budgets: [overShopping()],
        transactions: [
          tx(id: 'old', at: now.subtract(const Duration(days: 4))),
          tx(id: 'new', at: now.subtract(const Duration(minutes: 5))),
        ],
        now: now,
      );
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i - 1].occurredAt.isAfter(result[i].occurredAt) ||
              result[i - 1].occurredAt == result[i].occurredAt,
          isTrue,
          reason: 'entry $i is newer than the one before it',
        );
      }
      expect(result.first.id, 'income-new');
    });
  });

  group('the two authored kinds that are not produced', () {
    test('no sync-failure notice exists, because account syncing does not', () {
      // 57:718 authors "Vietcombank sync failed". Seeding it would put an
      // invented fact about the user's bank on screen.
      final result = deriveNotifications(
        budgets: [overShopping()],
        transactions: [tx()],
        now: now,
      );
      expect(
        result.map((n) => n.title),
        everyElement(isNot(contains('sync'))),
      );
    });

    test('no goal-progress notice exists, because goals do not', () {
      final result = deriveNotifications(
        budgets: [overShopping()],
        transactions: [tx()],
        now: now,
      );
      expect(
        result.map((n) => n.kind).toSet(),
        everyElement(isIn(NotificationKind.values)),
      );
      expect(NotificationKind.values, hasLength(3));
    });
  });
}
