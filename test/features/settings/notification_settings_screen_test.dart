import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/notification_providers.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/settings/presentation/notification_settings_screen.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    NotificationPreferences preferences = const NotificationPreferences(),
    ValueChanged<NotificationPreferences>? onChanged,
  }) => pumpMonetaWidget(
    tester,
    NotificationSettingsScreen(
      preferences: preferences,
      onChanged: onChanged ?? (_) {},
    ),
    surfaceSize: const Size(393, 1400),
  );

  group('the screen 101:618 authors', () {
    testWidgets('four groups, six rows — one short of the authored seven', (
      tester,
    ) async {
      // `101:853` authors "4x SectionHeader, 7x ListRow (5 Toggle, 2 Value)".
      // This builds **six**, and the shortfall is deliberate and recorded in
      // `figma-map.md`: the seventh row is "Monthly report ready", and nothing
      // in this app produces a monthly report. A switch that silences a
      // notification which cannot be sent is a switch that does nothing, and
      // `100:728` says a toggle promises an immediate change.
      //
      // Two of the six are also **renamed** from the frame, for the same
      // reason: "Bill due in 3 days" and "Goal milestone reached" become
      // "Budget period ending" and "Money received", which are the kinds
      // `NotificationKind` actually has. There is no bills feature and no
      // goals feature.
      //
      // The four group headings are kept exactly as authored, including
      // "Bills & goals", so the shape of the screen still matches the design
      // and the gap is visible rather than papered over.
      await pumpScreen(tester);

      expect(find.byType(SectionHeader), findsNWidgets(4));
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(rows, hasLength(6));

      final toggles = rows
          .where((r) => r.accessory == ListRowAccessory.toggle)
          .length;
      final values = rows
          .where((r) => r.accessory == ListRowAccessory.value)
          .length;
      expect(values, 2, reason: 'a time is not a boolean');
      expect(
        toggles,
        4,
        reason: 'four, not the authored five: see the note above',
      );
      expect(
        toggles + values,
        rows.length,
        reason: 'every row is one of the two treatments',
      );
    });

    testWidgets('the group titles are the authored ones', (tester) async {
      await pumpScreen(tester);
      expect(
        tester
            .widgetList<SectionHeader>(find.byType(SectionHeader))
            .map((h) => h.title),
        ['Budgets', 'Bills & goals', 'Summaries', 'Quiet hours'],
      );
    });

    testWidgets('the two Value rows carry the app defaults', (tester) async {
      // `101:859`: "22:00 – 07:00 quiet hours and the Sunday 20:00 summary are
      // the app's defaults."
      await pumpScreen(tester);
      expect(find.text('Sunday 20:00'), findsOneWidget);
      expect(find.text('22:00 – 07:00'), findsOneWidget);
    });

    testWidgets('a time row is a Value, never a Toggle', (tester) async {
      // `101:862`: "Two rows here are Value, not Toggle, because they carry a
      // time the user can change. A time is not a boolean. This is the mapping
      // mistake from 08.03 seen from the other side."
      await pumpScreen(tester);
      for (final title in ['Weekly summary', 'Do not disturb']) {
        final row = tester.widget<ListRow>(
          find.ancestor(of: find.text(title), matching: find.byType(ListRow)),
        );
        expect(row.accessory, ListRowAccessory.value, reason: title);
        expect(row.onToggle, isNull, reason: '$title is not a boolean');
      }
    });

    testWidgets('the defaults are mixed, not all on', (tester) async {
      // `101:856`: "Mixed on and off deliberately — a settings screen where
      // every switch is on tells you nothing about how the off state reads."
      await pumpScreen(tester);
      final states = tester
          .widgetList<ListRow>(find.byType(ListRow))
          .where((r) => r.accessory == ListRowAccessory.toggle)
          .map((r) => r.toggled)
          .toSet();
      expect(
        states,
        {true, false},
        reason: 'both states must be visible on the default screen',
      );
    });
  });

  group('changing a switch reports the whole set', () {
    testWidgets('turning one off leaves the others alone', (tester) async {
      final reported = <NotificationPreferences>[];
      await pumpScreen(tester, onChanged: reported.add);

      await tester.tap(find.text('Budget exceeded'));
      await tester.pump();

      expect(reported, hasLength(1));
      expect(reported.single.budgetExceeded, isFalse);
      // Everything else keeps its default: off for the 80% warning, on for the
      // two that have a notification behind them.
      expect(reported.single.budgetNearLimit, isFalse);
      expect(reported.single.periodEnding, isTrue);
      expect(reported.single.income, isTrue);
    });

    testWidgets('turning the off-by-default one on works too', (tester) async {
      final reported = <NotificationPreferences>[];
      await pumpScreen(tester, onChanged: reported.add);

      await tester.tap(find.text('80% of a budget used'));
      await tester.pump();
      expect(
        reported.single.budgetNearLimit,
        isTrue,
        reason: 'the one off-by-default switch must turn on',
      );
    });

    testWidgets('the whole row is the tap target, not just the switch', (
      tester,
    ) async {
      // `35:70`: "never make just the trailing control tappable."
      final reported = <NotificationPreferences>[];
      await pumpScreen(tester, onChanged: reported.add);

      await tester.tap(find.text('One warning per budget per month'));
      await tester.pump();
      expect(reported, hasLength(1));
    });
  });

  group('the switches actually silence notifications', () {
    // The point of the screen, from `101:850`: "so a user can silence one
    // category without silencing everything." Without this the switches would
    // persist a boolean and change nothing, which `100:728` forbids — a toggle
    // promises an immediate change.

    test('each kind is gated by its own switch', () {
      const all = NotificationPreferences(
        budgetNearLimit: true,
        budgetExceeded: true,
        periodEnding: true,
        income: true,
      );
      for (final kind in NotificationKind.values) {
        expect(allows(all, kind), isTrue, reason: kind.name);
      }

      expect(
        allows(
          all.copyWith(budgetExceeded: false),
          NotificationKind.budgetOverLimit,
        ),
        isFalse,
      );
      expect(
        allows(
          all.copyWith(periodEnding: false),
          NotificationKind.budgetPeriodEnding,
        ),
        isFalse,
      );
      expect(
        allows(all.copyWith(income: false), NotificationKind.incomeReceived),
        isFalse,
      );
    });

    test('silencing one category leaves the others audible', () {
      const all = NotificationPreferences(
        budgetNearLimit: true,
        budgetExceeded: true,
        periodEnding: true,
        income: true,
      );
      final quiet = all.copyWith(income: false);
      expect(allows(quiet, NotificationKind.incomeReceived), isFalse);
      expect(allows(quiet, NotificationKind.budgetOverLimit), isTrue);
      expect(
        allows(quiet, NotificationKind.budgetPeriodEnding),
        isTrue,
        reason: 'silencing one must not silence everything',
      );
    });

    test('every kind is covered, so a new one cannot be forgotten', () {
      // `allows` switches exhaustively over `NotificationKind`, so adding a
      // kind is a compile error rather than a notification that silently
      // ignores its switch. This asserts the coverage is real.
      const none = NotificationPreferences(
        budgetNearLimit: false,
        budgetExceeded: false,
        periodEnding: false,
        income: false,
      );
      for (final kind in NotificationKind.values) {
        expect(allows(none, kind), isFalse, reason: kind.name);
      }
    });
  });

  group('the value type', () {
    test('copyWith changes one flag and keeps the rest', () {
      const base = NotificationPreferences();
      expect(base.copyWith(budgetNearLimit: true).budgetNearLimit, isTrue);
      expect(base.copyWith(budgetNearLimit: true).budgetExceeded, isTrue);
      expect(
        base.copyWith(budgetExceeded: false).income,
        isTrue,
        reason: 'changing one flag must not move another',
      );
      expect(base.copyWith(income: false).income, isFalse);
    });

    test('equality is by value, on every flag', () {
      expect(const NotificationPreferences(), const NotificationPreferences());
      for (final other in const [
        NotificationPreferences(budgetNearLimit: true),
        NotificationPreferences(budgetExceeded: false),
        NotificationPreferences(periodEnding: false),
        NotificationPreferences(income: false),
      ]) {
        expect(const NotificationPreferences(), isNot(other));
      }
    });

    test('the defaults are mixed, and income stays on', () {
      const defaults = NotificationPreferences();
      // Income is ON because it already shipped — an off default would have
      // silently removed a working feature behind a new switch, which the
      // first version of this screen did and two existing tests caught.
      expect(defaults.income, isTrue);
      expect(defaults.budgetExceeded, isTrue);
      expect(defaults.periodEnding, isTrue);
      // And the one switch with nothing behind it yet is off, which is both
      // honest and what makes the defaults mixed.
      expect(defaults.budgetNearLimit, isFalse);
    });
  });
}
