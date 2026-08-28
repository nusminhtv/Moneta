import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
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

  HomeSnapshot snapshotWith(List<RecentEntry> recent) => HomeSnapshot(
    totalBalance: const Money(31877000, vnd),
    income: const Money(32000000, vnd),
    expenses: const Money(123000, vnd),
    recent: recent,
  );

  Future<void> pumpHome(WidgetTester tester, HomeSnapshot snapshot) =>
      pumpMonetaWidget(
        tester,
        SizedBox(
          width: 393,
          height: 852,
          child: HomeScreen(snapshot: snapshot, greeting: 'Hi there'),
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

    testWidgets('an empty wallet says so instead of showing a bare list', (
      tester,
    ) async {
      await pumpHome(tester, HomeSnapshot.empty(vnd));
      expect(find.byType(TransactionRow), findsNothing);
      expect(find.byType(DateGroupHeader), findsNothing);
      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
      // No "See all" either: a link to an empty list is a dead end.
      expect(find.text('See all'), findsNothing);
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
}
