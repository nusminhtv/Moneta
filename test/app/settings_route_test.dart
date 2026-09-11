import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/settings_route_screens.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:moneta/features/settings/presentation/edit_profile_screen.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Profile? profile,
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
          // The stored profile, faked. The store's real behaviour — including
          // that it is control-scoped — is tested against a real database in
          // `profile_store_scope_test.dart`; **real I/O inside `testWidgets`
          // never completes** under `FakeAsync` (CLAUDE.md), so this harness
          // fakes the provider and tests the wiring.
          profileProvider.overrideWith((ref) async => profile),
        ],
        child: MaterialApp.router(
          theme: MonetaTheme.dark().toThemeData(),
          routerConfig: buildRouter(initialLocation: location),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('08.11 is reachable from both screens that link to it', () {
    testWidgets('from 08.01, the Profile tab', (tester) async {
      await pumpAt(tester, SettingsRoutes.profile);

      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('from 08.03, the settings list', (tester) async {
      await pumpAt(tester, SettingsRoutes.list);

      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('and the back control returns', (tester) async {
      await pumpAt(tester, SettingsRoutes.list);
      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsNothing);
    });
  });

  group('a row that goes somewhere does not say it is unbuilt', () {
    for (final location in [SettingsRoutes.profile, SettingsRoutes.list]) {
      testWidgets('on $location', (tester) async {
        await pumpAt(tester, location);

        // Every row with a tap target must not also carry "Not built yet".
        // The two are contradictory, and the screen shipped with three rows
        // saying it while `settings-components` was clearing their blockers.
        for (final row in tester.widgetList<ListRow>(find.byType(ListRow))) {
          if (row.onTap != null) {
            expect(
              row.subtitle,
              isNot('Not built yet'),
              reason: '"${row.title}" is tappable and claims to be unbuilt',
            );
          }
        }

        // And the Help row specifically has gained its destination.
        final help = tester
            .widgetList<ListRow>(find.byType(ListRow))
            .where((r) => r.title == 'Help & FAQ');
        expect(help, hasLength(1));
        expect(help.single.onTap, isNotNull);
        expect(help.single.accessory, ListRowAccessory.chevron);
      });
    }
  });

  group('the stored profile is what 08.01 and 08.03 show', () {
    testWidgets('name, email and the avatar initials', (tester) async {
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(
          name: 'Trần Văn Minh',
          email: 'minh@example.com',
        ),
      );

      expect(find.text('Trần Văn Minh'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      // Initials from the stored name, not from a placeholder.
      expect(
        tester.widget<MonetaAvatar>(find.byType(MonetaAvatar)).name,
        'Trần Văn Minh',
      );
      expect(find.text('TM'), findsOneWidget);
    });

    testWidgets('and with nothing stored it asks rather than inventing', (
      tester,
    ) async {
      await pumpAt(tester, SettingsRoutes.profile);

      expect(find.text('Add your name'), findsOneWidget);
      // The placeholders this screen shipped with are gone.
      expect(find.text('Moneta user'), findsNothing);
      expect(find.text('Not signed in'), findsNothing);
    });

    testWidgets('08.03 shows the stored currency, not a hard-coded VND', (
      tester,
    ) async {
      await pumpAt(
        tester,
        SettingsRoutes.list,
        profile: const Profile(name: 'Minh', currency: Currency.usd),
      );

      expect(find.text('USD'), findsOneWidget);
      expect(find.text('VND'), findsNothing);
    });
  });

  group('08.02 is reachable from both screens', () {
    testWidgets("from 08.01's Edit button", (tester) async {
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(name: 'Minh'),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      // And it opens on the stored values.
      expect(find.text('Minh'), findsWidgets);
    });

    testWidgets("from 08.03's Edit profile row", (tester) async {
      await pumpAt(tester, SettingsRoutes.list);

      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}
