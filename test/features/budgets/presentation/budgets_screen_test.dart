import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/budgets/presentation/budgets_screen.dart';

import '../../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;
  const usd = Currency.usd;
  final now = DateTime.utc(2026, 9, 21);

  BudgetProgress progressFor({
    required String id,
    required SpendCategory category,
    required int limit,
    required int spent,
    double threshold = 0.8,
    Currency currency = vnd,
  }) => BudgetProgress.compute(
    budget: Budget.create(
      id: id,
      category: category,
      limit: Money(limit, currency),
      period: BudgetPeriod.monthly,
      startsOn: DateTime.utc(2026, 9),
      createdAt: DateTime.utc(2026, 8, 30),
      alertThreshold: threshold,
    ).valueOrNull!,
    entries: [
      SpendEntry(
        id: 's$id',
        category: category,
        direction: TransactionDirection.expense,
        amount: Money(spent, currency),
        occurredAt: DateTime.utc(2026, 9, 10),
      ),
    ],
    now: now,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    List<BudgetProgress> progress, {
    ValueChanged<int>? onPeriodChanged,
    VoidCallback? onAdd,
    ValueChanged<String>? onOpen,
    bool hasAnyBudget = true,
    int selectedPeriod = 2,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 393,
      height: 852,
      child: BudgetsScreen(
        progress: progress,
        periodLabels: const ['Jul', 'Aug', 'Sep'],
        selectedPeriod: selectedPeriod,
        hasAnyBudget: hasAnyBudget,
        currency: vnd,
        onPeriodChanged: onPeriodChanged,
        onAdd: onAdd,
        onOpen: onOpen,
      ),
    ),
    surfaceSize: const Size(393, 852),
  );

  group('ranking', () {
    test('the over-limit budget cannot be below the fold', () {
      final list = [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 1800000,
        ),
        progressFor(
          id: 'bills',
          category: SpendCategory.bills,
          limit: 2000000,
          spent: 2400000,
        ),
        progressFor(
          id: 'shop',
          category: SpendCategory.shopping,
          limit: 1000000,
          spent: 820000,
        ),
      ]..sort(compareWorstFirst);
      expect(list.map((p) => p.budget.id), ['bills', 'shop', 'food']);
    });

    testWidgets('the cards render in the order they are given', (tester) async {
      final list = [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 1800000,
        ),
        progressFor(
          id: 'bills',
          category: SpendCategory.bills,
          limit: 2000000,
          spent: 2400000,
        ),
      ]..sort(compareWorstFirst);
      await pumpScreen(tester, list);

      final cards = tester
          .widgetList<BudgetCard>(find.byType(BudgetCard))
          .toList();
      expect(cards.map((c) => c.category), [
        SpendCategory.bills,
        SpendCategory.food,
      ]);
    });
  });

  group('the total ring', () {
    test('is total over total, not an average of fractions', () {
      // Averaging treats a 50,000 budget at 100% and a 5,000,000 budget at 10%
      // as equally weighted, which answers a question nobody asked.
      final list = [
        progressFor(
          id: 'small',
          category: SpendCategory.food,
          limit: 50000,
          spent: 50000,
        ),
        progressFor(
          id: 'large',
          category: SpendCategory.bills,
          limit: 5000000,
          spent: 500000,
        ),
      ];
      final overall = BudgetsScreen.overallFraction(list);
      expect(overall, closeTo(550000 / 5050000, 1e-9));
      expect(
        overall,
        isNot(closeTo((1.0 + 0.1) / 2, 1e-9)),
        reason: 'the ring is showing an average of fractions',
      );
    });

    test('an empty list is zero, not a division by zero', () {
      expect(BudgetsScreen.overallFraction([]), 0);
    });

    testWidgets('the ring reflects the combined figures', (tester) async {
      await pumpScreen(tester, [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 2000000,
        ),
      ]);
      final ring = tester.widget<MonetaCircularProgress>(
        find.byType(MonetaCircularProgress),
      );
      expect(ring.fraction, closeTo(0.5, 1e-9));
    });
  });

  group('each card carries its own threshold', () {
    testWidgets('a budget alerting at 50% reaches the card', (tester) async {
      await pumpScreen(tester, [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 2400000,
          threshold: 0.5,
        ),
      ]);
      final card = tester.widget<BudgetCard>(find.byType(BudgetCard));
      expect(card.nearLimitThreshold, 0.5);
    });
  });

  group('empty', () {
    testWidgets('offers the one action that helps', (tester) async {
      // The first-run state, `66:277`: no budgets anywhere, not merely none in
      // the period being looked at. hasAnyBudget separates the two.
      var added = 0;
      await pumpScreen(
        tester,
        [],
        hasAnyBudget: false,
        onAdd: () => added++,
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(BudgetCard), findsNothing);
      expect(find.byType(MonetaSegmentedControl), findsNothing);
      expect(find.byType(MonetaCircularProgress), findsNothing);

      await tester.tap(find.text('Create a budget'));
      expect(added, 1);
    });
  });

  group('interaction', () {
    testWidgets('the period switcher reports which segment was chosen', (
      tester,
    ) async {
      // The switcher selects a period to look at -- `66:117` labels the
      // segments Jul / Aug / Sep -- not a kind of budget. It used to report a
      // BudgetPeriod, which the screen then used to filter budgets by their
      // own period, so tapping a segment could empty a list of real budgets.
      int? chosen;
      await pumpScreen(
        tester,
        [
          progressFor(
            id: 'food',
            category: SpendCategory.food,
            limit: 4000000,
            spent: 100000,
          ),
        ],
        onPeriodChanged: (i) => chosen = i,
      );
      await tester.tap(find.text('Jul'));
      expect(chosen, 0);
    });

    testWidgets('the authored labels are rendered, not period names', (
      tester,
    ) async {
      await pumpScreen(tester, [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 100000,
        ),
      ]);
      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Weekly'), findsNothing);
      expect(find.text('Monthly'), findsNothing);
      expect(find.text('Yearly'), findsNothing);
    });

    testWidgets('exactly one segment is selected', (tester) async {
      await pumpScreen(tester, [
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 100000,
        ),
      ]);
      final items = tester.widgetList<MonetaSegmentedItem>(
        find.byType(MonetaSegmentedItem),
      );
      expect(items.where((i) => i.selected), hasLength(1));
    });

    testWidgets('opening a card reports its id', (tester) async {
      String? opened;
      await pumpScreen(
        tester,
        [
          progressFor(
            id: 'food',
            category: SpendCategory.food,
            limit: 4000000,
            spent: 100000,
          ),
        ],
        onOpen: (id) => opened = id,
      );
      await tester.tap(find.byType(BudgetCard));
      expect(opened, 'food');
    });
  });

  group('the card note', () {
    test('says how much is used and how long is left', () {
      final note = BudgetsScreen.noteFor(
        progressFor(
          id: 'food',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 1000000,
        ),
      );
      expect(note, contains('25%'));
      expect(note, contains('10 days left'));
    });

    test('singular on the last day', () {
      final entry = BudgetProgress.compute(
        budget: Budget.create(
          id: 'food',
          category: SpendCategory.food,
          limit: const Money(4000000, vnd),
          period: BudgetPeriod.monthly,
          startsOn: DateTime.utc(2026, 9),
          createdAt: DateTime.utc(2026, 8, 30),
        ).valueOrNull!,
        entries: const [],
        now: DateTime.utc(2026, 9, 30, 12),
      );
      expect(BudgetsScreen.noteFor(entry), contains('1 day left'));
    });
  });

  group('layout', () {
    testWidgets('nothing overflows at the design size', (tester) async {
      await pumpScreen(tester, [
        for (final c in SpendCategory.values.take(6))
          progressFor(
            id: c.name,
            category: c,
            limit: 4000000,
            spent: 3900000,
          ),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bottom navigation is not part of the screen', (
      tester,
    ) async {
      // The shell owns it, so the active tab cannot disagree with the route.
      await pumpScreen(tester, []);
      expect(find.text('Insights'), findsNothing);
      expect(find.text('Profile'), findsNothing);
    });
  });

  group('an empty period is not an empty wallet', () {
    testWidgets('no budgets at all offers the create action', (tester) async {
      await pumpScreen(tester, const [], hasAnyBudget: false, onAdd: () {});
      expect(find.byType(EmptyState), findsOneWidget);
      final empty = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(empty.onAction, isNotNull);
    });

    testWidgets('budgets that predate this period offer no create action', (
      tester,
    ) async {
      // Someone with three budgets scrolling back before they existed was
      // being told "No budgets yet" and offered a create button.
      await pumpScreen(tester, const [], onAdd: () {});
      final empty = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(empty.onAction, isNull);
      expect(empty.actionLabel, isNull);
      expect(find.textContaining('Nothing to show'), findsOneWidget);
    });

    testWidgets('the switcher stays reachable when a period is empty', (
      tester,
    ) async {
      // Otherwise the only way back to a period with data would be gone.
      await pumpScreen(tester, const []);
      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Jul'), findsOneWidget);
    });

    testWidgets('the first-run state has no switcher, per 66:277', (
      tester,
    ) async {
      await pumpScreen(tester, const [], hasAnyBudget: false);
      expect(find.text('Sep'), findsNothing);
    });
  });

  group('totals never mix currencies', () {
    test('a foreign-currency budget is skipped, not added in', () {
      // Money.+ guards this; folding raw minorUnits bypassed the guard and
      // labelled the result with whichever entry happened to be first.
      final entries = [
        progressFor(
          id: 'vnd',
          category: SpendCategory.food,
          limit: 4000000,
          spent: 1000000,
        ),
        progressFor(
          id: 'usd',
          category: SpendCategory.transport,
          limit: 400,
          spent: 9000,
          currency: usd,
        ),
      ];
      expect(
        BudgetsScreen.totalSpent(entries, vnd),
        const Money(1000000, vnd),
      );
      expect(
        BudgetsScreen.totalLimit(entries, vnd),
        const Money(4000000, vnd),
      );
      expect(BudgetsScreen.overallFraction(entries, vnd), 0.25);
    });

    test('an empty list totals zero in the wallet currency', () {
      expect(BudgetsScreen.totalSpent(const [], vnd), const Money(0, vnd));
      expect(BudgetsScreen.overallFraction(const [], vnd), 0);
    });
  });
}
