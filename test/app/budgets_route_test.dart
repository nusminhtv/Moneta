import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/presentation/budgets_screen.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

/// The wiring between the period switcher and the offset it means.
///
/// `budgets_route_screen.dart` sat at 3 of 29 lines covered: nothing
/// constructed it. The segment-index-to-offset inversion and the
/// `hasAnyBudget` flag were correct by reading and unproven by test — an
/// inverted mapping would show September when Jul is tapped and nothing would
/// notice.
void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 9, 15, 3);

  Transaction spend(String id, int minor, DateTime at) => Transaction.create(
    id: id,
    amount: Money(minor, vnd),
    direction: TransactionDirection.expense,
    category: SpendCategory.food,
    occurredAt: at,
    createdAt: at,
  ).valueOrNull!;

  Budget monthly({DateTime? startsOn}) => Budget.create(
    id: 'b-food',
    category: SpendCategory.food,
    limit: const Money(4000000, vnd),
    period: BudgetPeriod.monthly,
    startsOn: startsOn ?? DateTime.utc(2026, 1),
    createdAt: DateTime.utc(2026, 1),
  ).valueOrNull!;

  Future<void> pump(
    WidgetTester tester, {
    List<Transaction> transactions = const [],
    List<Budget>? budgets,
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith(
            (ref) => FakeTransactionRepository(initial: transactions),
          ),
          clockProvider.overrideWithValue(TickingClock(now)),
          budgetListProvider.overrideWith(
            (ref) async => budgets ?? [monthly()],
          ),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const BudgetsRouteScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('it opens on the newest segment', (tester) async {
    await pump(tester);
    final control = tester.widget<MonetaSegmentedControl>(
      find.byType(MonetaSegmentedControl),
    );
    expect(control.selectedIndex, 2);
    expect(control.labels, ['Jul', 'Aug', 'Sep']);
  });

  testWidgets('the newest segment shows this period spend', (tester) async {
    await pump(
      tester,
      transactions: [spend('sep', 1000000, DateTime.utc(2026, 9, 5, 3))],
    );
    expect(
      tester.widget<BudgetCard>(find.byType(BudgetCard)).spent,
      const Money(1000000, vnd),
    );
  });

  testWidgets('tapping the oldest segment shows that period, not this one', (
    tester,
  ) async {
    // An inverted index-to-offset mapping would leave September's figure here.
    await pump(
      tester,
      transactions: [
        spend('sep', 1000000, DateTime.utc(2026, 9, 5, 3)),
        spend('jul', 250000, DateTime.utc(2026, 7, 5, 3)),
      ],
    );
    await tester.tap(find.text('Jul'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BudgetCard>(find.byType(BudgetCard)).spent,
      const Money(250000, vnd),
    );
  });

  testWidgets('the middle segment is the previous period', (tester) async {
    await pump(
      tester,
      transactions: [spend('aug', 700000, DateTime.utc(2026, 8, 5, 3))],
    );
    await tester.tap(find.text('Aug'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BudgetCard>(find.byType(BudgetCard)).spent,
      const Money(700000, vnd),
    );
  });

  testWidgets('a wallet with no budgets gets the first-run state', (
    tester,
  ) async {
    await pump(tester, budgets: const []);
    final screen = tester.widget<BudgetsScreen>(find.byType(BudgetsScreen));
    expect(screen.hasAnyBudget, isFalse);
    expect(find.text('Create a budget'), findsOneWidget);
  });

  testWidgets('a budget younger than the segment is not first-run', (
    tester,
  ) async {
    // hasAnyBudget must reflect the wallet, not the selected period.
    await pump(tester, budgets: [monthly(startsOn: DateTime.utc(2026, 9))]);
    await tester.tap(find.text('Jul'));
    await tester.pumpAndSettle();

    final screen = tester.widget<BudgetsScreen>(find.byType(BudgetsScreen));
    expect(screen.hasAnyBudget, isTrue);
    expect(screen.progress, isEmpty);
    expect(find.text('Create a budget'), findsNothing);
    expect(find.textContaining('Nothing to show'), findsOneWidget);
  });

  testWidgets('the switcher stays usable after landing on an empty period', (
    tester,
  ) async {
    await pump(tester, budgets: [monthly(startsOn: DateTime.utc(2026, 9))]);
    await tester.tap(find.text('Jul'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sep'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetCard), findsOneWidget);
  });
}
