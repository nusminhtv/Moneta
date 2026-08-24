import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../../../support/fake_transaction_repository.dart';

void main() {
  const vnd = Currency.vnd;
  final now = DateTime.utc(2026, 8, 24, 12);

  Transaction tx({
    required String id,
    int amount = 1000,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? at,
  }) {
    return Transaction.create(
      id: id,
      amount: Money(amount, vnd),
      direction: direction,
      category: category,
      occurredAt: at ?? DateTime.utc(2026, 8, 24, 9),
      createdAt: at ?? DateTime.utc(2026, 8, 24, 9),
    ).valueOrNull!;
  }

  late FakeTransactionRepository repository;
  late FixedClock clock;
  late ProviderContainer container;

  ProviderContainer build() {
    final c = ProviderContainer(
      overrides: [
        // Synchronous, not `async =>`: an override that completes later makes
        // the notifier rebuild mid-load, and Riverpod disposes the in-flight
        // build — the error that surfaces is the disposal, not the failure
        // under test.
        transactionRepositoryProvider.overrideWith((ref) => repository),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repository = FakeTransactionRepository();
    clock = FixedClock(now);
    container = build();
  });

  Future<TransactionListState> load() =>
      container.read(transactionListControllerProvider.future);

  TransactionListController controller() =>
      container.read(transactionListControllerProvider.notifier);

  group('loading', () {
    test('an empty repository loads an empty state, not an error', () async {
      final state = await load();
      expect(state.isEmpty, isTrue);
      expect(state.days, isEmpty);
      expect(state.summary.net.isZero, isTrue);
      expect(
        container.read(transactionListControllerProvider).hasError,
        isFalse,
      );
    });

    test('groups loaded transactions by day', () async {
      await repository.add(tx(id: 'a', at: DateTime(2026, 8, 24, 9).toUtc()));
      await repository.add(tx(id: 'b', at: DateTime(2026, 8, 23, 9).toUtc()));

      final state = await load();
      expect(state.days, hasLength(2));
      expect(state.isEmpty, isFalse);
    });

    test('exposes the period summary', () async {
      await repository.add(
        tx(
          id: 'in',
          amount: 5000,
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
        ),
      );
      await repository.add(tx(id: 'out', amount: 2000));

      final state = await load();
      expect(state.summary.income.minorUnits, 5000);
      expect(state.summary.expenses.minorUnits, 2000);
      expect(state.summary.net.minorUnits, 3000);
    });

    test('a read failure becomes an error state, not an empty list', () async {
      // An empty list here would render as "you have no transactions", which is
      // a different and much worse message than "we could not read them".
      //
      // Subscribed rather than awaiting `.future`: an unlistened provider whose
      // build throws is disposed mid-load, and the error that surfaces is the
      // disposal rather than the failure under test.
      repository.failWith = const AppFailure.storage('disk on fire');
      container.listen(transactionListControllerProvider, (_, _) {});
      await pumpEventQueue();

      final async = container.read(transactionListControllerProvider);
      expect(async.hasError, isTrue);
      expect(async.error, isA<TransactionListFailure>());
      expect(async.value, isNull);
    });

    test('retry after a failure recovers', () async {
      repository.failWith = const AppFailure.storage('disk on fire');
      container.listen(transactionListControllerProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(transactionListControllerProvider).hasError,
        isTrue,
      );

      repository.failWith = null;
      await repository.add(tx(id: 'a'));
      await controller().refresh();

      final async = container.read(transactionListControllerProvider);
      expect(async.hasError, isFalse);
      expect(async.value!.days, hasLength(1));
    });
  });

  group('adding', () {
    test('a new transaction appears without a manual refresh', () async {
      await load();
      final result = await controller().add(tx(id: 'new'));

      expect(result.isOk, isTrue);
      final state = container.read(transactionListControllerProvider).value!;
      expect(state.days.single.transactions.single.id, 'new');
    });

    test('a failed add leaves the list alone', () async {
      await load();
      repository.failWith = const AppFailure.storage('disk on fire');

      final result = await controller().add(tx(id: 'new'));
      expect(result.isOk, isFalse);
      expect(
        container.read(transactionListControllerProvider).value!.isEmpty,
        isTrue,
      );
    });
  });

  group('delete and undo', () {
    test('delete removes the transaction and opens an undo window', () async {
      final removed = tx(id: 'gone');
      await repository.add(removed);
      await load();

      final result = await controller().delete(removed);
      expect(result.isOk, isTrue);

      final state = container.read(transactionListControllerProvider).value!;
      expect(state.isEmpty, isTrue);
      expect(state.pendingUndo!.transaction, removed);
      expect(
        state.pendingUndo!.expiresAt,
        now.add(TransactionListController.undoWindow),
      );
    });

    test('undo restores the same record, not a copy', () async {
      final removed = tx(id: 'gone', amount: 4321);
      await repository.add(removed);
      await load();
      await controller().delete(removed);

      final result = await controller().undoDelete();
      expect(result.isOk, isTrue);

      final restored = container
          .read(transactionListControllerProvider)
          .value!
          .days
          .single
          .transactions
          .single;
      expect(restored.id, 'gone');
      expect(restored, removed);
    });

    test('undo restores the original position in the ordering', () async {
      final first = tx(id: 'c', at: DateTime.utc(2026, 8, 24, 12));
      final middle = tx(id: 'b', at: DateTime.utc(2026, 8, 24, 11));
      final last = tx(id: 'a', at: DateTime.utc(2026, 8, 24, 10));
      for (final t in [first, middle, last]) {
        await repository.add(t);
      }
      await load();

      await controller().delete(middle);
      await controller().undoDelete();

      final ids = container
          .read(transactionListControllerProvider)
          .value!
          .days
          .single
          .transactions
          .map((t) => t.id);
      expect(ids, ['c', 'b', 'a']);
    });

    test('undo clears the pending window', () async {
      final removed = tx(id: 'gone');
      await repository.add(removed);
      await load();
      await controller().delete(removed);
      await controller().undoDelete();

      expect(
        container.read(transactionListControllerProvider).value!.pendingUndo,
        isNull,
      );
    });

    test('the undo window expires', () async {
      final removed = tx(id: 'gone');
      await repository.add(removed);
      await load();
      await controller().delete(removed);

      clock.instant = now
          .add(TransactionListController.undoWindow)
          .add(const Duration(milliseconds: 1));

      final result = await controller().undoDelete();
      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (f) => expect(f.kind, FailureKind.notFound),
      );
      expect(
        container.read(transactionListControllerProvider).value!.isEmpty,
        isTrue,
        reason: 'an expired undo must not resurrect the transaction',
      );
    });

    test('undo is still allowed at the last instant of the window', () async {
      final removed = tx(id: 'gone');
      await repository.add(removed);
      await load();
      await controller().delete(removed);

      clock.instant = now
          .add(TransactionListController.undoWindow)
          .subtract(const Duration(milliseconds: 1));

      expect((await controller().undoDelete()).isOk, isTrue);
    });

    test('undo with nothing pending reports not-found', () async {
      await load();
      final result = await controller().undoDelete();
      expect(result.isOk, isFalse);
    });

    test('dismissing the undo drops it without restoring', () async {
      final removed = tx(id: 'gone');
      await repository.add(removed);
      await load();
      await controller().delete(removed);

      controller().dismissUndo();

      final state = container.read(transactionListControllerProvider).value!;
      expect(state.pendingUndo, isNull);
      expect(state.isEmpty, isTrue);
    });

    test('deleting something already gone reports not-found', () async {
      await load();
      final result = await controller().delete(tx(id: 'never-existed'));
      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (f) => expect(f.kind, FailureKind.notFound),
      );
    });
  });

  group('filtering', () {
    test('applying a filter reloads with it', () async {
      await repository.add(tx(id: 'food', category: SpendCategory.food));
      await repository.add(tx(id: 'bills', category: SpendCategory.bills));
      await load();

      final query = TransactionQuery.build(
        categories: {SpendCategory.bills},
      ).valueOrNull!;
      await controller().applyFilter(query);

      final state = container.read(transactionListControllerProvider).value!;
      expect(state.days.single.transactions.single.id, 'bills');
      expect(controller().query, query);
    });

    test('the summary respects the filter', () async {
      await repository.add(
        tx(id: 'food', amount: 1000, category: SpendCategory.food),
      );
      await repository.add(
        tx(id: 'bills', amount: 7000, category: SpendCategory.bills),
      );
      await load();

      await controller().applyFilter(
        TransactionQuery.build(
          categories: {SpendCategory.bills},
        ).valueOrNull!,
      );

      expect(
        container
            .read(transactionListControllerProvider)
            .value!
            .summary
            .expenses
            .minorUnits,
        7000,
      );
    });
  });

  group('state', () {
    test('copyWith can clear the pending undo explicitly', () {
      final state = TransactionListState(
        days: const [],
        summary: PeriodSummary.zero(vnd),
        pendingUndo: PendingUndo(
          transaction: tx(id: 'x'),
          expiresAt: now,
        ),
      );
      expect(state.copyWith(clearPendingUndo: true).pendingUndo, isNull);
      expect(state.copyWith().pendingUndo, isNotNull);
    });

    test('states with the same contents are equal', () {
      final a = TransactionListState(
        days: const [],
        summary: PeriodSummary.zero(vnd),
      );
      final b = TransactionListState(
        days: const [],
        summary: PeriodSummary.zero(vnd),
      );
      expect(a, b);
    });

    test('the failure wrapper shows the underlying message', () {
      expect(
        const TransactionListFailure(
          AppFailure.storage('disk on fire'),
        ).toString(),
        'disk on fire',
      );
    });
  });
}
