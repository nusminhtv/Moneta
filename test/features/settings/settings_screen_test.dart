import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/features/settings/presentation/settings_screen.dart';

import '../../support/pump.dart';

void main() {
  final groups = <SettingsGroup>[
    const SettingsGroup(
      title: 'Account',
      rows: [
        SettingsRow.push(
          title: 'Edit profile',
          subtitle: 'Not built yet',
          icon: MonetaIconName.user,
          onTap: null,
          available: false,
        ),
        SettingsRow.value(title: 'Main currency', value: 'VND'),
      ],
    ),
    SettingsGroup(
      title: 'Data',
      rows: [
        SettingsRow.toggle(
          title: 'Demo data',
          subtitle: 'Fill the app with generated data',
          toggled: false,
          onToggle: (_) {},
        ),
      ],
    ),
    SettingsGroup(
      title: 'Security',
      rows: [SettingsRow.push(title: 'Security', onTap: () {})],
    ),
    const SettingsGroup(
      title: 'About',
      rows: [SettingsRow.value(title: 'Version', value: '0.1.0')],
    ),
  ];

  Future<void> pumpSettings(
    WidgetTester tester, {
    List<SettingsGroup>? which,
  }) => pumpMonetaWidget(
    tester,
    SettingsScreen(groups: which ?? groups),
    surfaceSize: const Size(393, 1400),
  );

  group('the list is grouped', () {
    testWidgets('one header per group, in order', (tester) async {
      await pumpSettings(tester);
      final headers = tester
          .widgetList<SectionHeader>(find.byType(SectionHeader))
          .map((h) => h.title)
          .toList();
      expect(headers, ['Account', 'Data', 'Security', 'About']);
    });

    testWidgets('every row is rendered', (tester) async {
      await pumpSettings(tester);
      expect(
        find.byType(ListRow),
        findsNWidgets(groups.fold(0, (n, g) => n + g.rows.length)),
      );
    });
  });

  group('the trailing variant matches what the row does', () {
    // 100:728: "The Trailing variant is the whole information design of a
    // settings list... Getting that mapping wrong is the most common
    // settings-screen mistake."
    //
    // Asserted as an INVARIANT over every row, not row by row: a per-row
    // assertion would pass a list where a new row was added with the wrong
    // trailing, which is exactly the mistake being guarded against.
    test('a row cannot express the wrong promise', () {
      for (final group in groups) {
        for (final row in group.rows) {
          if (row.onToggle != null) {
            expect(row.accessory, ListRowAccessory.toggle, reason: row.title);
            expect(
              row.onTap,
              isNull,
              reason: '${row.title} both toggles and navigates',
            );
          } else if (row.value != null) {
            expect(row.accessory, ListRowAccessory.value, reason: row.title);
          } else if (row.onTap != null) {
            expect(row.accessory, ListRowAccessory.chevron, reason: row.title);
          } else {
            expect(row.accessory, ListRowAccessory.none, reason: row.title);
          }
        }
      }
    });

    test('the accessory is derived, so it cannot be passed wrongly', () {
      // The constructors take no accessory at all.
      const value = SettingsRow.value(title: 'x', value: 'y');
      expect(value.accessory, ListRowAccessory.value);
      final toggle = SettingsRow.toggle(
        title: 'x',
        toggled: true,
        onToggle: (_) {},
      );
      expect(toggle.accessory, ListRowAccessory.toggle);
      final push = SettingsRow.push(title: 'x', onTap: () {});
      expect(push.accessory, ListRowAccessory.chevron);
    });

    testWidgets('the rendered rows carry the derived accessory', (
      tester,
    ) async {
      await pumpSettings(tester);
      final rows = tester.widgetList<ListRow>(find.byType(ListRow)).toList();
      expect(
        rows.map((r) => r.accessory),
        [
          // Edit profile is unavailable, so it has no onTap — and therefore no
          // chevron promising a screen that is not there.
          ListRowAccessory.none,
          ListRowAccessory.value,
          ListRowAccessory.toggle,
          ListRowAccessory.chevron,
          ListRowAccessory.value,
        ],
      );
    });
  });

  group('a row whose destination is unbuilt', () {
    testWidgets('is visible but does not navigate', (tester) async {
      var tapped = 0;
      await pumpSettings(
        tester,
        which: [
          SettingsGroup(
            title: 'Account',
            rows: [
              SettingsRow.push(
                title: 'Edit profile',
                subtitle: 'Not built yet',
                onTap: () => tapped++,
                available: false,
              ),
            ],
          ),
        ],
      );

      expect(find.text('Edit profile'), findsOneWidget);
      await tester.tap(find.text('Edit profile'));
      await tester.pump();
      expect(
        tapped,
        0,
        reason: 'a row that navigates nowhere must not navigate',
      );
    });

    testWidgets('an available row does navigate', (tester) async {
      var tapped = 0;
      await pumpSettings(
        tester,
        which: [
          // The group heading is deliberately not the row's title: both render
          // as `Text` and the finder cannot tell them apart otherwise.
          SettingsGroup(
            title: 'Privacy',
            rows: [
              SettingsRow.push(title: 'Face ID', onTap: () => tapped++),
            ],
          ),
        ],
      );
      await tester.tap(find.text('Face ID'));
      await tester.pump();
      expect(tapped, 1, reason: 'the inverse: available rows still work');
    });
  });

  group('the demo switch', () {
    testWidgets('reflects its state and reports a change', (tester) async {
      final changes = <bool>[];
      await pumpSettings(
        tester,
        which: [
          SettingsGroup(
            title: 'Data',
            rows: [
              SettingsRow.toggle(
                title: 'Demo data',
                subtitle: 'Generated data; your real ledger is untouched.',
                toggled: false,
                onToggle: changes.add,
              ),
            ],
          ),
        ],
      );

      final row = tester.widget<ListRow>(find.byType(ListRow));
      expect(row.toggled, isFalse);
      expect(row.accessory, ListRowAccessory.toggle);
      expect(
        find.textContaining('real ledger is untouched'),
        findsOneWidget,
        reason: 'the row must say what it does to real data',
      );

      row.onToggle!(true);
      expect(changes, [true]);
    });

    testWidgets('shows as on when demo mode is active', (tester) async {
      await pumpSettings(
        tester,
        which: [
          SettingsGroup(
            title: 'Data',
            rows: [
              SettingsRow.toggle(
                title: 'Demo data',
                toggled: true,
                onToggle: (_) {},
              ),
            ],
          ),
        ],
      );
      expect(tester.widget<ListRow>(find.byType(ListRow)).toggled, isTrue);
    });
  });
}
