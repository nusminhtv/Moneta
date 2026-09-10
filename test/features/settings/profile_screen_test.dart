import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/settings/presentation/profile_screen.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  const stats = [
    ProfileStat(value: '214', label: 'Days tracked'),
    ProfileStat(value: '1,842', label: 'Transactions'),
    ProfileStat(value: '4', label: 'Active goals'),
  ];

  Future<void> pumpProfile(
    WidgetTester tester, {
    List<ListRow> rows = const [],
    VoidCallback? onEdit,
    VoidCallback? onOpenSettings,
    String name = 'Minh Tran',
  }) => pumpMonetaWidget(
    tester,
    ProfileScreen(
      name: name,
      email: 'minh.tran@example.com',
      stats: stats,
      rows: rows,
      onEdit: onEdit,
      onOpenSettings: onOpenSettings,
    ),
    surfaceSize: const Size(393, 1000),
  );

  group('identity', () {
    testWidgets('the avatar derives its initials from the name', (
      tester,
    ) async {
      await pumpProfile(tester);
      final avatar = tester.widget<MonetaAvatar>(find.byType(MonetaAvatar));
      expect(avatar.name, 'Minh Tran');
      expect(avatar.size, MonetaAvatarSize.lg);
      expect(avatar.type, MonetaAvatarType.initials);
      expect(find.text('MT'), findsOneWidget);
    });

    testWidgets('the name and email are shown', (tester) async {
      await pumpProfile(tester);
      expect(find.text('Minh Tran'), findsOneWidget);
      expect(find.text('minh.tran@example.com'), findsOneWidget);
    });

    testWidgets('the edit button is a ghost, small', (tester) async {
      await pumpProfile(tester, onEdit: () {});
      final button = tester.widget<MonetaButton>(find.byType(MonetaButton));
      expect(button.style, MonetaButtonStyle.ghost);
      expect(button.size, MonetaButtonSize.sm);
    });

    testWidgets('a long name does not push the button off screen', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        name: 'Nguyen Thi Minh Khai Van Anh Tuan Hoang Long',
        onEdit: () {},
      );
      expect(tester.takeException(), isNull);
      final screen = tester.getRect(find.byType(ProfileScreen));
      final button = tester.getRect(find.byType(MonetaButton));
      expect(button.right, lessThanOrEqualTo(screen.right));
    });
  });

  group('the stat tiles are local, not StatTile', () {
    testWidgets('StatTile is not used', (tester) async {
      // Annotation `100:275`: "The stat tiles are local, not StatTile. StatTile
      // is built around a delta with a direction arrow, and 'days tracked' has
      // no delta. Reuse that fights the component's meaning is worse than a
      // local frame."
      await pumpProfile(tester);
      expect(
        find.byType(StatTile),
        findsNothing,
        reason: 'a delta arrow on "days tracked" would be meaningless',
      );
    });

    test('and the source does not reach for it', () {
      // A widget test only proves it is absent for this fixture; the screen
      // must not be able to use it at all.
      //
      // Comments stripped first: the class doc *quotes* the annotation that
      // names `StatTile` to explain why it is not used, and a check that
      // cannot tell prose from code fails on its own rationale — the same trap
      // the demo generator's check hit.
      final source =
          File(
                'lib/features/settings/presentation/profile_screen.dart',
              )
              .readAsStringSync()
              .split('\n')
              .where(
                (line) => !line.trimLeft().startsWith('//'),
              )
              .join('\n');

      // The import is the real constraint: the component cannot be used
      // without it.
      expect(source, isNot(contains('stat_tile.dart')));
      // And a bare `StatTile` identifier — the lookbehind is what stops this
      // matching a *local* class whose name merely ends in it, which is how
      // the first version of this check failed against `_StatTile`. That local
      // class is now `_StatCard`, and the check no longer depends on it.
      expect(
        RegExp('(?<![A-Za-z_])StatTile').hasMatch(source),
        isFalse,
        reason: 'the screen reaches for the design-system StatTile',
      );
    });

    testWidgets('all three figures and labels are shown', (tester) async {
      await pumpProfile(tester);
      for (final stat in stats) {
        expect(find.text(stat.value), findsOneWidget, reason: stat.label);
        expect(find.text(stat.label), findsOneWidget);
      }
    });

    testWidgets('the three tiles share the row evenly', (tester) async {
      await pumpProfile(tester);
      final widths = <double>[];
      for (final stat in stats) {
        widths.add(
          tester
              .getRect(
                find
                    .ancestor(
                      of: find.text(stat.value),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .width,
        );
      }
      expect(
        widths.map((w) => w.round()).toSet(),
        hasLength(1),
        reason: 'the columns are equal in `100:60`: $widths',
      );
    });
  });

  group('the menu', () {
    testWidgets('rows are rendered under a section header', (tester) async {
      await pumpProfile(
        tester,
        rows: const [
          ListRow(title: 'Settings', accessory: ListRowAccessory.chevron),
          ListRow(
            title: 'Premium',
            accessory: ListRowAccessory.badge,
            badgeLabel: 'TRY FREE',
          ),
        ],
      );
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.byType(ListRow), findsNWidgets(2));
      expect(find.text('TRY FREE'), findsOneWidget);
    });

    testWidgets('sign out is the only red label', (tester) async {
      // `100:269`: "Sign out is the only destructive row and is the only label
      // not on text/primary."
      await pumpProfile(
        tester,
        rows: const [
          ListRow(title: 'Settings', accessory: ListRowAccessory.chevron),
          ListRow(
            title: 'Sign out',
            accessory: ListRowAccessory.none,
            destructive: true,
          ),
        ],
      );

      expect(
        tester.widget<Text>(find.text('Sign out')).style!.color,
        colors.expense,
      );
      expect(
        tester.widget<Text>(find.text('Settings')).style!.color,
        colors.textPrimary,
        reason: 'only one row may be off text/primary',
      );
    });
  });

  group('the app bar action is sliders, not a bell', () {
    testWidgets('and it opens settings', (tester) async {
      // `100:266`: the large-title action is "swapped to sliders" here.
      var opened = 0;
      await pumpProfile(tester, onOpenSettings: () => opened++);

      final bar = tester.widget<MonetaAppBar>(find.byType(MonetaAppBar));
      expect(bar.variant, MonetaAppBarVariant.largeTitle);
      expect(bar.actions.single.icon, MonetaIconName.sliders);
      expect(bar.actions.single.icon, isNot(MonetaIconName.bell));

      bar.actions.single.onPressed!();
      expect(opened, 1);
    });
  });

  group('the figure count is pinned', () {
    testWidgets('three, because 100:60 shows three', (tester) async {
      // A build-time assert surfaces through `takeException`, not by the pump's
      // future rejecting — the first version of this test awaited a throw that
      // never arrived there.
      await pumpMonetaWidget(
        tester,
        const ProfileScreen(
          name: 'Minh Tran',
          email: 'e',
          stats: [ProfileStat(value: '1', label: 'One')],
          rows: [],
        ),
        surfaceSize: const Size(393, 1000),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
