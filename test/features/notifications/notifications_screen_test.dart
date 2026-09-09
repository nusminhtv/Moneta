import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/notifications/presentation/notifications_screen.dart';

import '../../support/pump.dart';

/// The notification centre, against node `57:622` and annotation `57:830`.
void main() {
  // Noon local on 20 Sep. The gate pins TZ=Asia/Ho_Chi_Minh (UTC+7), so this
  // is 05:00 UTC and the local day boundary is 17:00 UTC the day before.
  final now = DateTime.utc(2026, 9, 20, 5);

  HomeNotification entry({
    String id = 'n1',
    NotificationKind kind = NotificationKind.budgetOverLimit,
    String title = 'Shopping is over budget',
    String detail = '740,000 ₫ over · 2 hours ago',
    MonetaIconName icon = MonetaIconName.alertTriangle,
    DateTime? occurredAt,
  }) => HomeNotification(
    id: id,
    kind: kind,
    title: title,
    detail: detail,
    icon: icon,
    occurredAt: occurredAt ?? now.subtract(const Duration(hours: 2)),
    targetId: 'b1',
  );

  Future<void> pump(
    WidgetTester tester,
    List<HomeNotification> notifications, {
    void Function(HomeNotification)? onOpen,
    VoidCallback? onBack,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 393,
      height: 852,
      child: NotificationsScreen(
        notifications: notifications,
        now: now,
        onOpen: onOpen,
        onBack: onBack,
      ),
    ),
    surfaceSize: const Size(393, 852),
  );

  group('the app bar', () {
    testWidgets('is the TitleBack variant, because this is a sub-screen', (
      tester,
    ) async {
      await pump(tester, [entry()]);
      final bar = tester.widget<MonetaAppBar>(find.byType(MonetaAppBar));
      expect(bar.variant, MonetaAppBarVariant.titleBack);
      expect(bar.variant.hasBack, isTrue);
    });

    testWidgets('is titled Notifications', (tester) async {
      await pump(tester, [entry()]);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('does not contain the bottom navigation', (tester) async {
      // The shell owns it, so the active tab cannot disagree with the route.
      await pump(tester, [entry()]);
      expect(find.text('Home'), findsNothing);
    });
  });

  group('the accessory follows actionability — 57:830', () {
    testWidgets('an actionable notification gets a chevron', (tester) async {
      await pump(tester, [entry()], onOpen: (_) {});
      expect(
        tester.widget<ListRow>(find.byType(ListRow)).accessory,
        ListRowAccessory.chevron,
      );
    });

    testWidgets('an informational notification gets no accessory', (
      tester,
    ) async {
      await pump(
        tester,
        [
          entry(
            kind: NotificationKind.budgetPeriodEnding,
            title: 'Budgets reset in 13 days',
          ),
        ],
        onOpen: (_) {},
      );
      expect(
        tester.widget<ListRow>(find.byType(ListRow)).accessory,
        ListRowAccessory.none,
      );
    });

    testWidgets('an informational notification does not respond to taps', (
      tester,
    ) async {
      final opened = <String>[];
      await pump(
        tester,
        [entry(kind: NotificationKind.budgetPeriodEnding)],
        onOpen: (n) => opened.add(n.id),
      );
      expect(tester.widget<ListRow>(find.byType(ListRow)).onTap, isNull);
      await tester.tap(find.byType(ListRow));
      expect(opened, isEmpty);
    });

    testWidgets('tapping an actionable notification reports which one', (
      tester,
    ) async {
      final opened = <String>[];
      await pump(
        tester,
        [
          entry(id: 'first'),
          entry(
            id: 'second',
            occurredAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
        onOpen: (n) => opened.add(n.id),
      );
      await tester.tap(find.byType(ListRow).last);
      expect(opened, ['second']);
    });

    testWidgets('the authored mix is three chevrons and two plain rows', (
      tester,
    ) async {
      await pump(
        tester,
        [
          entry(id: 'a'),
          entry(id: 'b', kind: NotificationKind.incomeReceived),
          entry(id: 'c'),
          entry(id: 'd', kind: NotificationKind.budgetPeriodEnding),
          entry(id: 'e', kind: NotificationKind.budgetPeriodEnding),
        ],
        onOpen: (_) {},
      );
      final rows = tester.widgetList<ListRow>(find.byType(ListRow));
      expect(
        rows.where((r) => r.accessory == ListRowAccessory.chevron),
        hasLength(3),
      );
      expect(
        rows.where((r) => r.accessory == ListRowAccessory.none),
        hasLength(2),
      );
    });
  });

  group('a chevron over nothing is not representable', () {
    testWidgets('an actionable row with no handler gets no chevron', (
      tester,
    ) async {
      // The accessory used to follow the kind alone, so this drew a chevron
      // over a row that did nothing -- the exact thing the spec forbids. The
      // first-run checklist already followed the stricter rule, so the two
      // screens disagreed about a rule they share.
      await pump(tester, [entry(kind: NotificationKind.budgetOverLimit)]);
      final row = tester.widget<ListRow>(find.byType(ListRow));
      expect(row.onTap, isNull);
      expect(row.accessory, ListRowAccessory.none);
    });

    testWidgets('the same row with a handler does get one', (tester) async {
      await pump(
        tester,
        [entry(kind: NotificationKind.budgetOverLimit)],
        onOpen: (_) {},
      );
      final row = tester.widget<ListRow>(find.byType(ListRow));
      expect(row.onTap, isNotNull);
      expect(row.accessory, ListRowAccessory.chevron);
    });
  });

  group('Today and Earlier', () {
    testWidgets('both headings appear when both groups have rows', (
      tester,
    ) async {
      await pump(tester, [
        entry(id: 'today'),
        entry(id: 'old', occurredAt: now.subtract(const Duration(days: 3))),
      ]);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
    });

    testWidgets('Today precedes Earlier', (tester) async {
      await pump(tester, [
        entry(id: 'today'),
        entry(id: 'old', occurredAt: now.subtract(const Duration(days: 3))),
      ]);
      expect(
        tester.getTopLeft(find.text('Today')).dy,
        lessThan(tester.getTopLeft(find.text('Earlier')).dy),
      );
    });

    testWidgets('an empty group leaves no heading behind', (tester) async {
      await pump(tester, [entry(id: 'today')]);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Earlier'), findsNothing);
    });

    testWidgets('only older rows produce only the Earlier heading', (
      tester,
    ) async {
      await pump(tester, [
        entry(id: 'old', occurredAt: now.subtract(const Duration(days: 5))),
      ]);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Earlier'), findsOneWidget);
    });

    testWidgets('both headings carry no action', (tester) async {
      await pump(tester, [
        entry(id: 'today'),
        entry(id: 'old', occurredAt: now.subtract(const Duration(days: 3))),
      ]);
      for (final header in tester.widgetList<SectionHeader>(
        find.byType(SectionHeader),
      )) {
        expect(header.onAction, isNull);
        expect(header.actionLabel, isNull);
      }
    });
  });

  group('grouping is by local day, not elapsed hours', () {
    test('late last night local groups under Earlier', () {
      // 19 Sep 22:00 local is 15:00 UTC. Under UTC+7 that is the previous
      // local day, so it belongs to Earlier -- while its subtitle would still
      // read in hours. The two answer different questions.
      final lastNight = DateTime.utc(2026, 9, 19, 15);
      final groups = NotificationsScreen.groupByRecency([
        HomeNotification(
          id: 'n',
          kind: NotificationKind.incomeReceived,
          title: 't',
          detail: 'd',
          icon: MonetaIconName.briefcase,
          occurredAt: lastNight,
        ),
      ], now);
      expect(groups.today, isEmpty);
      expect(groups.earlier, hasLength(1));
    });

    test('early this morning local groups under Today', () {
      // 20 Sep 00:30 local is 19 Sep 17:30 UTC -- a different UTC date, same
      // local day. Grouping on the UTC date would file it wrongly.
      final earlyToday = DateTime.utc(2026, 9, 19, 17, 30);
      final groups = NotificationsScreen.groupByRecency([
        HomeNotification(
          id: 'n',
          kind: NotificationKind.incomeReceived,
          title: 't',
          detail: 'd',
          icon: MonetaIconName.briefcase,
          occurredAt: earlyToday,
        ),
      ], now);
      expect(groups.today, hasLength(1));
      expect(groups.earlier, isEmpty);
    });

    test('before 07:00 local, yesterday is still Earlier', () {
      // THE discriminating case, and the one the fixture above cannot reach.
      //
      // `groupByRecency` converts **now** to local to find the start of today.
      // Every other test in this group passes the shared `now` of 12:00 local,
      // where the UTC and local dates agree -- so dropping that conversion
      // changed no answer and the whole suite stayed green. The entry-side
      // conversion is a genuine no-op: `isBefore` compares instants.
      //
      // Between 00:00 and 07:00 local the two dates differ. Here now is
      // 20 Sep 00:30 local (19 Sep 17:30 UTC). Built from the UTC date instead,
      // "start of today" lands on 19 Sep and the whole of yesterday is filed
      // under Today.
      final nowEarlyMorning = DateTime.utc(2026, 9, 19, 17, 30);
      final yesterdayMidday = DateTime.utc(
        2026,
        9,
        19,
        5,
      ); // 19 Sep 12:00 local

      final groups = NotificationsScreen.groupByRecency([
        HomeNotification(
          id: 'n',
          kind: NotificationKind.incomeReceived,
          title: 't',
          detail: 'd',
          icon: MonetaIconName.briefcase,
          occurredAt: yesterdayMidday,
        ),
      ], nowEarlyMorning);

      expect(
        groups.earlier,
        hasLength(1),
        reason:
            'start of today was computed from the UTC date, not the local '
            'one, so yesterday was filed under Today',
      );
      expect(groups.today, isEmpty);
    });

    test('before 07:00 local, this morning is still Today', () {
      // The other side of the same boundary, so the fix cannot be "put
      // everything in Earlier".
      final nowEarlyMorning = DateTime.utc(2026, 9, 19, 17, 30);
      final thisMorning = DateTime.utc(2026, 9, 19, 17, 15); // 20 Sep 00:15

      final groups = NotificationsScreen.groupByRecency([
        HomeNotification(
          id: 'n',
          kind: NotificationKind.incomeReceived,
          title: 't',
          detail: 'd',
          icon: MonetaIconName.briefcase,
          occurredAt: thisMorning,
        ),
      ], nowEarlyMorning);

      expect(groups.today, hasLength(1));
      expect(groups.earlier, isEmpty);
    });

    test('an empty list groups into nothing', () {
      final groups = NotificationsScreen.groupByRecency(const [], now);
      expect(groups.today, isEmpty);
      expect(groups.earlier, isEmpty);
    });
  });

  group('rendering', () {
    testWidgets('a row shows its title, detail and glyph', (tester) async {
      await pump(tester, [entry()]);
      expect(find.text('Shopping is over budget'), findsOneWidget);
      expect(find.text('740,000 ₫ over · 2 hours ago'), findsOneWidget);
      expect(
        tester.widget<ListRow>(find.byType(ListRow)).leadingIcon,
        MonetaIconName.alertTriangle,
      );
    });

    testWidgets('nothing overflows at the design size', (tester) async {
      await pump(tester, [
        entry(
          title:
              'A notification title long enough to need the whole row and '
              'then a good deal more besides',
          detail:
              'A supporting line that is also far longer than the row can '
              'reasonably hold in one line',
        ),
        entry(id: 'b', occurredAt: now.subtract(const Duration(days: 2))),
      ]);
      expect(tester.takeException(), isNull);
    });
  });

  group('the empty centre — 57:840', () {
    testWidgets('an empty list renders the empty state', (tester) async {
      await pump(tester, const []);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('it shows the authored copy from 57:861', (tester) async {
      await pump(tester, const []);
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(
        find.text(
          'Budget warnings, sync problems and goal milestones will show up '
          'here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('it offers no action, which 57:935 sanctions', (tester) async {
      // "the rare legitimate case for HasAction=False — there is genuinely
      // nothing for the user to do here". The general rule that an empty state
      // must offer a next step is deliberately not applied.
      await pump(tester, const []);
      final empty = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(empty.actionLabel, isNull);
      expect(empty.onAction, isNull);
    });

    testWidgets('no headings and no rows are left behind', (tester) async {
      await pump(tester, const []);
      expect(find.byType(SectionHeader), findsNothing);
      expect(find.byType(ListRow), findsNothing);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Earlier'), findsNothing);
    });

    testWidgets('the app bar and its back control survive', (tester) async {
      // The way out must not depend on there being content.
      await pump(tester, const []);
      expect(find.byType(MonetaAppBar), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('back still works from the empty state', (tester) async {
      var backs = 0;
      await pump(tester, const [], onBack: () => backs++);
      await tester.tap(find.bySemanticsLabel('Back').first);
      expect(backs, 1);
    });

    testWidgets('one notification replaces the empty state', (tester) async {
      await pump(tester, [entry()]);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ListRow), findsOneWidget);
    });

    testWidgets('it is distinct from a loading state', (tester) async {
      // The route renders an empty list while the read is pending, so this is
      // the screen a user sees mid-load too. It says something true either way
      // rather than showing skeletons that imply data is coming.
      await pump(tester, const []);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
