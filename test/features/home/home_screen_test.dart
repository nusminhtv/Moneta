import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/banner.dart';
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

    testWidgets('draws at most two cards however many budgets exist', (
      tester,
    ) async {
      // The cap is a display decision and lives here. It used to live beside
      // the snapshot, where it reached safeToSpend and dropped the least-spent
      // budgets out of the arithmetic.
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            budget(),
            budget(category: SpendCategory.transport),
            budget(category: SpendCategory.shopping),
          ],
        ),
      );
      expect(find.byType(BudgetCard), findsNWidgets(2));
      expect(HomeScreen.budgetCardLimit, 2);
    });

    testWidgets('the two it draws are the two worst, which arrive first', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            budget(spent: 4800000),
            budget(category: SpendCategory.transport, spent: 4000000),
            budget(category: SpendCategory.shopping, spent: 0),
          ],
        ),
      );
      final drawn = tester
          .widgetList<BudgetCard>(find.byType(BudgetCard))
          .map((c) => c.category)
          .toList();
      expect(drawn, [SpendCategory.food, SpendCategory.transport]);
      expect(drawn, isNot(contains(SpendCategory.shopping)));
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

  group('the first-run checklist', () {
    // Annotation `52:537`: "An empty state with no action is a dead end, so
    // this one carries both a primary CTA and a 3-step checklist."
    HomeSnapshot firstRun({List<BudgetSummary> budgets = const []}) =>
        HomeSnapshot(
          totalBalance: const Money.zero(vnd),
          income: const Money.zero(vnd),
          expenses: const Money.zero(vnd),
          recent: const [],
          safeToSpend: const Money.zero(vnd),
          budgets: budgets,
        );

    Future<void> pump(
      WidgetTester tester,
      HomeSnapshot snapshot, {
      VoidCallback? onLogFirstExpense,
      VoidCallback? onSetBudget,
      VoidCallback? onLinkAccount,
    }) => pumpMonetaWidget(
      tester,
      SizedBox(
        width: 393,
        height: 852,
        child: HomeScreen(
          snapshot: snapshot,
          greeting: 'Hi there',
          now: DateTime.utc(2026, 8, 20, 3),
          onLogFirstExpense: onLogFirstExpense,
          onSetBudget: onSetBudget,
          onLinkAccount: onLinkAccount,
        ),
      ),
      surfaceSize: const Size(393, 852),
    );

    testWidgets('the primary action logs an expense, which the app can do', (
      tester,
    ) async {
      // Figma's CTA is "Link an account". Accounts does not exist, so wiring
      // the first screen to it would be the dead end 52:537 warns about.
      var logged = 0;
      await pump(tester, firstRun(), onLogFirstExpense: () => logged++);
      await tester.tap(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text('Log your first expense'),
        ),
      );
      expect(logged, 1);
    });

    testWidgets('the primary action is never the unbuilt account step', (
      tester,
    ) async {
      var linked = 0;
      await pump(tester, firstRun(), onLinkAccount: () => linked++);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text('Link an account'),
        ),
        findsNothing,
      );
      expect(linked, 0);
    });

    testWidgets('all three steps are always listed', (tester) async {
      await pump(tester, firstRun());
      expect(find.byType(ListRow), findsNWidgets(3));
    });

    testWidgets('a step with no destination shows no chevron', (tester) async {
      // A chevron would advertise navigation that cannot happen.
      await pump(tester, firstRun(), onSetBudget: () {});
      final account = tester.widget<ListRow>(
        find.ancestor(
          of: find.text('Bank, cash or e-wallet'),
          matching: find.byType(ListRow),
        ),
      );
      expect(account.onTap, isNull);
      expect(account.accessory, ListRowAccessory.none);
    });

    testWidgets('a step with a destination keeps its chevron', (tester) async {
      await pump(tester, firstRun(), onSetBudget: () {});
      final budgetStep = tester.widget<ListRow>(
        find.ancestor(
          of: find.text('Start with your biggest category'),
          matching: find.byType(ListRow),
        ),
      );
      expect(budgetStep.accessory, ListRowAccessory.chevron);
    });

    testWidgets('setting a budget ticks that step and only that step', (
      tester,
    ) async {
      await pump(
        tester,
        firstRun(
          budgets: [
            budget(),
          ],
        ),
        onSetBudget: () {},
      );
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      final done = rows.where((r) => r.accessory == ListRowAccessory.badge);
      expect(done, hasLength(1));
      expect(done.single.title, 'Set one budget');
      expect(done.single.badgeLabel, 'Done');
    });

    testWidgets('a ticked step stops responding to taps', (tester) async {
      var setBudget = 0;
      await pump(
        tester,
        firstRun(budgets: [budget()]),
        onSetBudget: () => setBudget++,
      );
      final done = tester.widget<ListRow>(
        find.ancestor(
          of: find.text('Set one budget'),
          matching: find.byType(ListRow),
        ),
      );
      expect(done.onTap, isNull);
      expect(setBudget, 0);
    });

    testWidgets('with no budget set, nothing is ticked', (tester) async {
      await pump(tester, firstRun(), onSetBudget: () {});
      expect(
        tester
            .widgetList<ListRow>(find.byType(ListRow))
            .where((r) => r.accessory == ListRowAccessory.badge),
        isEmpty,
      );
    });

    testWidgets('the first-run screen shows no balance card', (tester) async {
      // No hero over zero, and no quick actions to nowhere.
      await pump(tester, firstRun());
      expect(find.byType(BalanceCard), findsNothing);
    });
  });

  group('the over-budget alert', () {
    // `57:414`, annotation `57:612`. This state did not exist: Banner appeared
    // nowhere in lib/features/home.
    BudgetSummary over({
      SpendCategory category = SpendCategory.food,
      int spent = 5620000,
      int limit = 5000000,
    }) => BudgetSummary(
      id: 'over-${category.name}',
      category: category,
      spent: Money(spent, vnd),
      limit: Money(limit, vnd),
      note: 'note',
    );

    testWidgets('no banner while every budget is on track', (tester) async {
      await pumpHome(tester, snapshotWith([], budgets: [budget()]));
      expect(find.byType(MonetaBanner), findsNothing);
    });

    testWidgets('a budget over its limit raises the banner', (tester) async {
      await pumpHome(tester, snapshotWith([], budgets: [over()]));
      expect(find.byType(MonetaBanner), findsOneWidget);
    });

    testWidgets('a budget exactly at its limit raises nothing', (tester) async {
      // Exactly 1.0 is the limit reached, not exceeded.
      await pumpHome(
        tester,
        snapshotWith([], budgets: [over(spent: 5000000, limit: 5000000)]),
      );
      expect(find.byType(MonetaBanner), findsNothing);
    });

    testWidgets('the banner sits above the balance card', (tester) async {
      await pumpHome(tester, snapshotWith([], budgets: [over()]));
      final banner = tester.getTopLeft(find.byType(MonetaBanner)).dy;
      final card = tester.getTopLeft(find.byType(BalanceCard)).dy;
      expect(banner, lessThan(card));
    });

    testWidgets('the banner names the worst category only', (tester) async {
      // Annotation: "names the worst category only, even if several are over."
      // budgets arrives ranked, so the head is the worst.
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            over(spent: 9000000),
            over(category: SpendCategory.transport, spent: 5100000),
          ],
        ),
      );
      final banner = tester.widget<MonetaBanner>(find.byType(MonetaBanner));
      expect(banner.title, contains(SpendCategory.food.label));
      expect(banner.title, isNot(contains(SpendCategory.transport.label)));
      expect(banner.message, isNot(contains(SpendCategory.transport.label)));
    });

    testWidgets('only one banner appears however many budgets are over', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith(
          [],
          budgets: [
            over(spent: 9000000),
            over(category: SpendCategory.transport, spent: 5100000),
          ],
        ),
      );
      expect(find.byType(MonetaBanner), findsOneWidget);
    });

    testWidgets('the alert is not carried by colour alone', (tester) async {
      await pumpHome(tester, snapshotWith([], budgets: [over()]));
      final banner = tester.widget<MonetaBanner>(find.byType(MonetaBanner));
      expect(banner.title, isNotEmpty);
      expect(banner.message, isNotEmpty);
    });

    testWidgets('the banner reports how far over, not just that it is over', (
      tester,
    ) async {
      await pumpHome(
        tester,
        snapshotWith([], budgets: [over(spent: 5620000, limit: 5000000)]),
      );
      final banner = tester.widget<MonetaBanner>(find.byType(MonetaBanner));
      expect(banner.message, contains(const Money(620000, vnd).format()));
    });

    testWidgets('this state drops the quick-actions row', (tester) async {
      // `57:414` authors none, while `52:2` does.
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(
            snapshot: snapshotWith([], budgets: [over()]),
            greeting: 'Hi there',
            now: DateTime.utc(2026, 8, 20, 3),
            quickActions: const [
              (icon: MonetaIconName.plus, label: 'Add', onPressed: null),
            ],
          ),
        ),
        surfaceSize: const Size(393, 852),
      );
      expect(find.text('Add'), findsNothing);
    });

    testWidgets('the on-track screen keeps its quick actions', (tester) async {
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(
            snapshot: snapshotWith([], budgets: [budget()]),
            greeting: 'Hi there',
            now: DateTime.utc(2026, 8, 20, 3),
            quickActions: const [
              (icon: MonetaIconName.plus, label: 'Add', onPressed: null),
            ],
          ),
        ),
        surfaceSize: const Size(393, 852),
      );
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('the rest of the screen is still there', (tester) async {
      // "Same layout as 02.01" apart from the banner and the quick actions.
      await pumpHome(tester, snapshotWith([], budgets: [over()]));
      expect(find.byType(MonetaAppBar), findsOneWidget);
      expect(find.byType(BalanceCard), findsOneWidget);
      expect(find.byType(BudgetCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
