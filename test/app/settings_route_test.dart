import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/settings_route_screens.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.binding.setSurfaceSize(const Size(393, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
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
}
