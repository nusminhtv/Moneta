import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_detail_route_screen.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/notification_providers.dart';
import 'package:moneta/app/notifications_route_screen.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/notifications/presentation/notifications_screen.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:moneta/features/transactions/presentation/transactions_screen.dart';

import '../support/fake_transaction_repository.dart';

/// The notification centre wired to the real provider graph.
///
/// `deriveNotifications` had 25 tests and the wiring had none: nothing ever ran
/// `notificationsProvider` with data, and nothing exercised where tapping a row
/// goes. Both are the parts a user actually meets.
void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 20, 3);

  Transaction tx({
    required String id,
    required TransactionDirection direction,
    required int minor,
    SpendCategory category = SpendCategory.food,
    String? note,
    DateTime? at,
  }) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: direction,
    category: category,
    occurredAt: at ?? DateTime.utc(2026, 9, 19, 3),
    createdAt: DateTime.utc(2026, 9, 19, 3),
    note: note,
  ).valueOrNull!;

  List<dynamic> overrides({
    List<Transaction> transactions = const [],
    bool withBudget = true,
  }) => [
    transactionRepositoryProvider.overrideWith(
      (ref) => FakeTransactionRepository(initial: transactions),
    ),
    clockProvider.overrideWithValue(TickingClock(now)),
    budgetListProvider.overrideWith(
      (ref) async => withBudget
          ? [
              Budget.create(
                id: 'b-food',
                category: SpendCategory.food,
                limit: const Money(1000000, vnd),
                period: BudgetPeriod.monthly,
                startsOn: DateTime.utc(2026, 9),
                createdAt: DateTime.utc(2026, 9),
              ).valueOrNull!,
            ]
          : const [],
    ),
  ];

  Future<ProviderContainer> read(List<dynamic> o) async {
    final c = ProviderContainer(overrides: o.cast());
    addTearDown(c.dispose);
    await c.read(transactionListControllerProvider.future);
    await c.read(budgetListProvider.future);
    return c;
  }

  group('notificationsProvider with real data', () {
    test('an over-limit budget produces an actionable entry', () async {
      final c = await read(
        overrides(
          transactions: [
            tx(
              id: 't1',
              direction: TransactionDirection.expense,
              minor: 1500000,
            ),
          ],
        ),
      );
      final list = c.read(notificationsProvider).value!;
      final over = list.where(
        (n) => n.kind == NotificationKind.budgetOverLimit,
      );
      expect(over, hasLength(1));
      expect(over.single.isActionable, isTrue);
      expect(over.single.targetId, 'b-food');
    });

    test('income produces an entry carrying the amount', () async {
      final c = await read(
        overrides(
          transactions: [
            tx(
              id: 't1',
              direction: TransactionDirection.income,
              minor: 32000000,
              category: SpendCategory.salary,
              note: 'NUS Technology',
            ),
          ],
        ),
      );
      final list = c.read(notificationsProvider).value!;
      final income = list.where(
        (n) => n.kind == NotificationKind.incomeReceived,
      );
      expect(income, hasLength(1));
      expect(income.single.detail, contains('NUS Technology'));
    });

    test('with no budgets and no ledger the feed is empty', () async {
      final c = await read(overrides(withBudget: false));
      expect(c.read(notificationsProvider).value, isEmpty);
    });

    test('entries arrive newest first', () async {
      final c = await read(
        overrides(
          transactions: [
            tx(
              id: 'old',
              direction: TransactionDirection.income,
              minor: 1000,
              at: DateTime.utc(2026, 9, 12, 3),
            ),
            tx(
              id: 'new',
              direction: TransactionDirection.income,
              minor: 2000,
              at: DateTime.utc(2026, 9, 19, 3),
            ),
          ],
        ),
      );
      final list = c.read(notificationsProvider).value!;
      final times = list.map((n) => n.occurredAt).toList();
      for (var i = 1; i < times.length; i++) {
        expect(
          times[i - 1].isAfter(times[i]) || times[i - 1] == times[i],
          isTrue,
        );
      }
    });
  });

  group('where a notification goes', () {
    Future<void> pumpRoute(WidgetTester tester, List<dynamic> o) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: o.cast(),
          child: MaterialApp.router(
            theme: MonetaTheme.dark().toThemeData(),
            routerConfig: buildRouter(
              initialLocation: NotificationRoutes.path,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an over-budget row opens that budget detail', (tester) async {
      await pumpRoute(
        tester,
        overrides(
          transactions: [
            tx(
              id: 't1',
              direction: TransactionDirection.expense,
              minor: 1500000,
            ),
          ],
        ),
      );
      await tester.tap(
        find.ancestor(
          of: find.textContaining('is over budget'),
          matching: find.byType(ListRow),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BudgetDetailRouteScreen), findsOneWidget);
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('an income row opens the transactions tab', (tester) async {
      await pumpRoute(
        tester,
        overrides(
          transactions: [
            tx(
              id: 't1',
              direction: TransactionDirection.income,
              minor: 32000000,
              category: SpendCategory.salary,
            ),
          ],
        ),
      );
      await tester.tap(
        find.ancestor(
          of: find.textContaining('received'),
          matching: find.byType(ListRow),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('the informational reset row does not navigate', (
      tester,
    ) async {
      await pumpRoute(tester, overrides());
      final row = find.ancestor(
        of: find.textContaining('Budgets reset in'),
        matching: find.byType(ListRow),
      );
      expect(tester.widget<ListRow>(row).onTap, isNull);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}
