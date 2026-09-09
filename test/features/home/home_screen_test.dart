import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/home/presentation/home_screen.dart';

import '../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;

  RecentEntry entry({
    required String id,
    required DateTime at,
    int minor = 45000,
    TransactionDirection direction = TransactionDirection.expense,
  }) => RecentEntry(
    id: id,
    title: 'Entry $id',
    amount: Money(minor, vnd),
    direction: direction,
    category: SpendCategory.food,
    occurredAt: at,
  );

  HomeSnapshot snapshotWith(
    List<RecentEntry> recent, {
    List<BudgetSummary> budgets = const [],
    Money? safeToSpend,
  }) => HomeSnapshot(
    totalBalance: const Money(31877000, vnd),
    income: const Money(32000000, vnd),
    expenses: const Money(123000, vnd),
    recent: recent,
    safeToSpend: safeToSpend ?? const Money(31877000, vnd),
    budgets: budgets,
  );

  BudgetSummary budget({
    SpendCategory category = SpendCategory.food,
    int spent = 4000000,
    int limit = 5000000,
    String note = '8 days left',
  }) => BudgetSummary(
    id: 'b-${category.name}',
    category: category,
    spent: Money(spent, vnd),
    limit: Money(limit, vnd),
    note: note,
  );

  Future<void> pumpHome(WidgetTester tester, HomeSnapshot snapshot) =>
      pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(
            snapshot: snapshot,
            greeting: 'Hi there',
            now: DateTime.utc(2026, 8, 20, 3),
          ),
        ),
        surfaceSize: const Size(393, 852),
      );

  group('layout', () {
    testWidgets('shows the greeting, the balance card and the recent rows', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith([
          entry(id: 'a', at: DateTime.utc(2026, 8, 20, 3)),
          entry(id: 'b', at: DateTime.utc(2026, 8, 20, 2)),
        ]),
      );

      expect(find.text('Hi there'), findsOneWidget);
      expect(find.byType(MonetaAppBar), findsOneWidget);
      expect(find.byType(BalanceCard), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the balance card is given the snapshot figures', (
      tester,
    ) async {
      await pumpHome(tester, snapshotWith([]));
      final card = tester.widget<BalanceCard>(find.byType(BalanceCard));
      expect(card.totalBalance, const Money(31877000, vnd));
      expect(card.income, const Money(32000000, vnd));
      expect(card.expenses, const Money(123000, vnd));
    });

    testWidgets('an empty wallet gets the first-run screen, not a gap', (
      tester,
    ) async {
      // Figma 52:372 is a different screen, not the normal one with a hole in
      // the middle: no balance card reading zero, no quick actions to nowhere,
      // no "See all" pointing at an empty list.
      await pumpHome(tester, HomeSnapshot.empty(vnd));

      expect(find.byType(TransactionRow), findsNothing);
      expect(find.byType(DateGroupHeader), findsNothing);
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.text('See all'), findsNothing);
      expect(find.text('Recent transactions'), findsNothing);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text("Let's set up your money"), findsOneWidget);
    });

    testWidgets('the first-run screen offers the three setup steps', (
      tester,
    ) async {
      await pumpHome(tester, HomeSnapshot.empty(vnd));

      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(rows.map((r) => r.title), [
        'Link an account',
        'Log your first expense',
        'Set one budget',
      ]);
      // `35:138`: an empty state with no primary action is a dead end.
      expect(
        tester.widget<EmptyState>(find.byType(EmptyState)).hasAction,
        isTrue,
      );
    });

    testWidgets('a wallet with one transaction is not the first-run screen', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith([entry(id: 'a', at: DateTime.utc(2026, 8, 20, 3))]),
      );
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(BalanceCard), findsOneWidget);
    });

    testWidgets('a balance with no recent rows still shows the balance', (
      tester,
    ) async {
      // Money with nothing recent is not first run. Showing the setup
      // checklist here would hide a real balance behind "Link an account".
      await pumpHome(tester, snapshotWith([]));
      expect(find.byType(EmptyState), findsNothing);
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).totalBalance,
        const Money(31877000, vnd),
      );
    });

    testWidgets('the bottom navigation is not part of the screen', (
      tester,
    ) async {
      // The shell owns it, so the active tab cannot disagree with the route.
      // Figma draws it inside the frame because Figma has no router.
      await pumpHome(tester, snapshotWith([]));
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('BottomNav'),
        ),
        findsNothing,
      );
    });

    testWidgets('no overflow at the design size', (tester) async {
      await pumpHome(
        tester,
        snapshotWith([
          for (var i = 0; i < 4; i++)
            entry(id: '$i', at: DateTime.utc(2026, 8, 20 - i, 3)),
        ]),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('grouping by day', () {
    test('groups by LOCAL day, newest day first', () {
      // 2026-08-20T18:00Z is 2026-08-21 01:00 in Asia/Ho_Chi_Minh, which the
      // gate pins. Grouping in UTC would file it under the 20th — and under UTC
      // this test would pass either way, which is why the zone is pinned.
      final groups = HomeScreen.groupByDay([
        entry(id: 'late', at: DateTime.utc(2026, 8, 20, 18)),
        entry(id: 'early', at: DateTime.utc(2026, 8, 20, 2)),
      ]);

      expect(groups, hasLength(2), reason: 'the two fell in one day — UTC?');
      expect(groups.first.day.day, 21);
      expect(groups.first.entries.single.id, 'late');
      expect(groups.last.day.day, 20);
      expect(groups.last.entries.single.id, 'early');
    });

    test('entries on the same local day share one group', () {
      final groups = HomeScreen.groupByDay([
        entry(id: 'a', at: DateTime.utc(2026, 8, 20, 3)),
        entry(id: 'b', at: DateTime.utc(2026, 8, 20, 4)),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.entries.map((e) => e.id), ['a', 'b']);
    });

    test('an empty list groups into nothing', () {
      expect(HomeScreen.groupByDay([]), isEmpty);
    });
  });

  group('masking', () {
    testWidgets('the mask flag reaches the balance card', (tester) async {
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(
            now: DateTime.utc(2026, 8, 20, 3),
            snapshot: snapshotWith([]),
            greeting: 'Hi there',
            masked: true,
          ),
        ),
        surfaceSize: const Size(393, 852),
      );
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).masked,
        isTrue,
      );
    });
  });

  group('the budgets section', () {
    // `52:116` titles this "Budgets" and carries a See all action; the two cards
    // are `52:125` and `52:143`.
    testWidgets('renders a card per budget under a Budgets header', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            budget(),
            budget(category: SpendCategory.transport, spent: 1000000),
          ],
        ),
      );
      expect(find.byType(BudgetCard), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(SectionHeader),
          matching: find.text('Budgets'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is absent entirely when there are no budgets', (tester) async {
      // A heading with nothing under it reads as a failed load, not an absence.
      await pumpHome(tester, snapshotWith([]));
      expect(find.byType(BudgetCard), findsNothing);
      expect(find.text('Budgets'), findsNothing);
    });

    testWidgets("each card is given its own figures, not the first budget's", (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            budget(spent: 4000000, limit: 5000000),
            budget(
              category: SpendCategory.transport,
              spent: 500000,
              limit: 2000000,
            ),
          ],
        ),
      );
      final cards = tester
          .widgetList<BudgetCard>(find.byType(BudgetCard))
          .toList();
      expect(cards[0].spent, const Money(4000000, vnd));
      expect(cards[0].limit, const Money(5000000, vnd));
      expect(cards[1].spent, const Money(500000, vnd));
      expect(cards[1].limit, const Money(2000000, vnd));
    });

    testWidgets('a budget carries its own alert threshold to its card', (
      tester,
    ) async {
      // Annotation `04.04` made the threshold per-budget. A card reading the
      // default would show the warning colour at the wrong point.
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: const [
            BudgetSummary(
              id: 'b1',
              category: SpendCategory.food,
              spent: Money(3000000, vnd),
              limit: Money(5000000, vnd),
              note: 'note',
              alertThreshold: 0.5,
            ),
          ],
        ),
      );
      expect(
        tester.widget<BudgetCard>(find.byType(BudgetCard)).nearLimitThreshold,
        0.5,
      );
    });

    testWidgets('tapping a card opens that budget, not the budgets list', (
      tester,
    ) async {
      // Routing every card to /budgets would make which card you tapped
      // irrelevant to where you land.
      final opened = <String>[];
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(
            snapshot: snapshotWith(
              [],
              budgets: [
                budget(),
                budget(category: SpendCategory.transport),
              ],
            ),
            greeting: 'Hi there',
            now: DateTime.utc(2026, 8, 20, 3),
            onOpenBudget: opened.add,
          ),
        ),
        surfaceSize: const Size(393, 852),
      );
      await tester.tap(find.byType(BudgetCard).last);
      expect(opened, ['b-transport']);
    });

    testWidgets('cards are inert when no budget handler is given', (
      tester,
    ) async {
      await pumpHome(tester, snapshotWith([], budgets: [budget()]));
      expect(
        tester.widget<BudgetCard>(find.byType(BudgetCard)).onTap,
        isNull,
      );
    });

    testWidgets('the section survives a full-width budget note without '
        'overflowing', (tester) async {
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            budget(
              note:
                  'A supporting line long enough to need the whole row and '
                  'then rather more than that as well',
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('safe to spend', () {
    testWidgets('the balance card shows safe to spend, not the balance', (
      tester,
    ) async {
      // These were the same value until annotation `52:362` was read.
      await pumpHome(
        tester,
        snapshotWith([], safeToSpend: const Money(6000000, vnd)),
      );
      final card = tester.widget<BalanceCard>(find.byType(BalanceCard));
      expect(card.safeToSpend, const Money(6000000, vnd));
      expect(card.totalBalance, const Money(31877000, vnd));
      expect(card.safeToSpend, isNot(card.totalBalance));
    });
  });
}
