import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:moneta/features/transactions/presentation/transactions_screen.dart';

import '../../../support/fake_transaction_repository.dart';

void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 8, 24, 12);

  late FakeTransactionRepository repository;
  late FixedClock clock;

  Transaction tx({
    required String id,
    int amount = 45000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? at,
    String? note,
  }) {
    return Transaction.create(
      id: id,
      amount: Money(amount, vnd),
      direction: direction,
      category: category,
      occurredAt: at ?? DateTime.utc(2026, 8, 24, 9),
      createdAt: at ?? DateTime.utc(2026, 8, 24, 9),
      note: note,
    ).valueOrNull!;
  }

  setUp(() {
    repository = FakeTransactionRepository();
    clock = FixedClock(now);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
          clockProvider.overrideWithValue(clock),
          idGeneratorProvider.overrideWithValue(FixedIdGenerator(prefix: 'tx')),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('states are distinguishable', () {
    testWidgets('empty shows the empty state and no error', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(TransactionsScreen.emptyStateKey), findsOneWidget);
      expect(find.byKey(TransactionsScreen.errorStateKey), findsNothing);
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('a read failure shows the error state and no empty state', (
      tester,
    ) async {
      // "Nothing here" and "we could not look" mean different things; showing
      // the empty state on a failure would tell the user their data is gone.
      repository.failWith = const AppFailure.storage('disk on fire');
      await pumpScreen(tester);

      expect(find.byKey(TransactionsScreen.errorStateKey), findsOneWidget);
      expect(find.byKey(TransactionsScreen.emptyStateKey), findsNothing);
      expect(find.text('disk on fire'), findsOneWidget);
    });

    testWidgets('only the error state offers a retry', (tester) async {
      // Pumped in separate tests rather than twice in one: re-pumping the same
      // ProviderScope keeps the container, so the provider would serve its
      // cached state and the second assertion would be meaningless.
      await pumpScreen(tester);
      expect(find.byKey(TransactionsScreen.retryKey), findsNothing);
    });

    testWidgets('the error state names the failure and offers a retry', (
      tester,
    ) async {
      repository.failWith = const AppFailure.storage('disk on fire');
      await pumpScreen(tester);

      expect(find.text('Could not load your transactions'), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);
      expect(find.byKey(TransactionsScreen.retryKey), findsOneWidget);
    });
  });

  group('retry', () {
    testWidgets('recovers from a failure', (tester) async {
      repository.failWith = const AppFailure.storage('disk on fire');
      await pumpScreen(tester);
      expect(find.byKey(TransactionsScreen.errorStateKey), findsOneWidget);

      repository.failWith = null;
      await repository.add(tx(id: 'a', note: 'phở'));

      await tester.tap(find.byKey(TransactionsScreen.retryKey));
      await tester.pumpAndSettle();

      expect(find.byKey(TransactionsScreen.errorStateKey), findsNothing);
      expect(find.text('phở'), findsOneWidget);
    });

    testWidgets('a still-failing retry keeps the error state', (tester) async {
      repository.failWith = const AppFailure.storage('disk on fire');
      await pumpScreen(tester);

      await tester.tap(find.byKey(TransactionsScreen.retryKey));
      await tester.pumpAndSettle();

      expect(find.byKey(TransactionsScreen.errorStateKey), findsOneWidget);
    });
  });

  group('list', () {
    testWidgets('renders a row per transaction, grouped by day', (
      tester,
    ) async {
      await repository.add(
        tx(id: 'a', note: 'phở', at: DateTime(2026, 8, 24, 9).toUtc()),
      );
      await repository.add(
        tx(id: 'b', note: 'cà phê', at: DateTime(2026, 8, 23, 9).toUtc()),
      );
      await pumpScreen(tester);

      expect(find.byType(TransactionRow), findsNWidgets(2));
      expect(find.text('phở'), findsOneWidget);
      expect(find.text('cà phê'), findsOneWidget);
    });

    testWidgets('a transaction with no note shows its category', (
      tester,
    ) async {
      await repository.add(tx(id: 'a', category: SpendCategory.bills));
      await pumpScreen(tester);
      expect(find.text(SpendCategory.bills.label), findsOneWidget);
    });

    testWidgets('shows a heading with the day net', (tester) async {
      await repository.add(
        tx(
          id: 'in',
          amount: 5000,
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
          at: DateTime(2026, 8, 24, 9).toUtc(),
        ),
      );
      await repository.add(
        tx(id: 'out', amount: 2000, at: DateTime(2026, 8, 24, 10).toUtc()),
      );
      await pumpScreen(tester);

      // Net is +3000; the heading shows it signed.
      expect(
        find.text(const Money(3000, vnd).format(showSign: true)),
        findsOneWidget,
      );
    });
  });

  group('delete and undo', () {
    testWidgets('swiping deletes and offers undo', (tester) async {
      await repository.add(tx(id: 'a', note: 'phở'));
      await pumpScreen(tester);

      await tester.drag(find.text('phở'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('phở'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
      expect(repository.items, isEmpty);
    });

    testWidgets('undo restores the transaction', (tester) async {
      await repository.add(tx(id: 'a', note: 'phở'));
      await pumpScreen(tester);

      await tester.drag(find.text('phở'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.items.single.id, 'a');
      expect(find.text('phở'), findsOneWidget);
    });
  });

  group('adding', () {
    testWidgets('a new transaction appears without a manual refresh', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byKey(TransactionsScreen.emptyStateKey), findsOneWidget);

      final element = tester.element(find.byType(TransactionsScreen));
      final container = ProviderScope.containerOf(element);
      await container
          .read(transactionListControllerProvider.notifier)
          .add(tx(id: 'new', note: 'bánh mì'));
      await tester.pumpAndSettle();

      expect(find.byKey(TransactionsScreen.emptyStateKey), findsNothing);
      expect(find.text('bánh mì'), findsOneWidget);
    });
  });
}
