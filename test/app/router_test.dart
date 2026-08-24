import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:moneta/features/transactions/presentation/transactions_screen.dart';

import '../support/fake_transaction_repository.dart';

void main() {
  const colors = MonetaColors.dark();
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = '/',
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp.router(
          theme: MonetaTheme.dark().toThemeData(),
          routerConfig: buildRouter(initialLocation: initialLocation),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color tabColour(WidgetTester tester, MonetaDestination destination) {
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(MonetaBottomNav.tabKey(destination)),
        matching: find.text(destination.label),
      ),
    );
    return label.style!.color!;
  }

  group('DestinationRoutes', () {
    test('every destination has a route', () {
      for (final destination in MonetaDestination.values) {
        expect(
          DestinationRoutes.paths[destination],
          isNotNull,
          reason: destination.name,
        );
      }
    });

    test('routes are distinct', () {
      expect(
        DestinationRoutes.paths.values.toSet(),
        hasLength(MonetaDestination.values.length),
      );
    });

    test('a location maps back to its own destination', () {
      // The mapping must be a genuine round trip, not two tables that can drift.
      for (final entry in DestinationRoutes.paths.entries) {
        expect(
          DestinationRoutes.of(entry.value),
          entry.key,
          reason: entry.value,
        );
      }
    });

    test('a nested route keeps its parent destination active', () {
      expect(
        DestinationRoutes.of('/transactions/tx-1'),
        MonetaDestination.transactions,
      );
    });

    test('an unknown location falls back to home', () {
      expect(DestinationRoutes.of('/nope'), MonetaDestination.home);
    });

    test('/transactions does not match as a prefix of /transactionsfoo', () {
      expect(
        DestinationRoutes.of('/transactionsfoo'),
        MonetaDestination.home,
      );
    });
  });

  group('navigation', () {
    testWidgets('starts on home with Home active', (tester) async {
      await pumpApp(tester);
      expect(find.text('Moneta'), findsOneWidget);
      expect(
        tabColour(tester, MonetaDestination.home),
        colors.brandOnSurface,
      );
    });

    testWidgets('each destination reaches its screen and becomes active', (
      tester,
    ) async {
      await pumpApp(tester);

      for (final destination in MonetaDestination.values) {
        await tester.tap(find.byKey(MonetaBottomNav.tabKey(destination)));
        await tester.pumpAndSettle();

        expect(
          tabColour(tester, destination),
          colors.brandOnSurface,
          reason: '${destination.name} should be active after tapping it',
        );
        for (final other in MonetaDestination.values) {
          if (other == destination) continue;
          expect(
            tabColour(tester, other),
            colors.textTertiary,
            reason: '${other.name} should be inactive',
          );
        }
      }
    });

    testWidgets('the transactions route shows the transactions screen', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: '/transactions');
      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(
        tabColour(tester, MonetaDestination.transactions),
        colors.brandOnSurface,
      );
    });

    testWidgets('deep-linking straight to a destination sets its tab', (
      tester,
    ) async {
      // The active tab is derived from the location, so it is right even when
      // the user never tapped anything.
      await pumpApp(tester, initialLocation: '/profile');
      expect(
        tabColour(tester, MonetaDestination.profile),
        colors.brandOnSurface,
      );
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('the navigation bar persists across destinations', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(MonetaBottomNav), findsOneWidget);

      await tester.tap(
        find.byKey(MonetaBottomNav.tabKey(MonetaDestination.insights)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MonetaBottomNav), findsOneWidget);
    });
  });

  group('add action', () {
    testWidgets('opens the add sheet', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(MonetaBottomNav.fabKey));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.text('New transaction'), findsOneWidget);
    });

    testWidgets('does not change the active destination', (tester) async {
      // Figma: the FAB "is not a fifth tab".
      await pumpApp(tester, initialLocation: '/transactions');
      await tester.tap(find.byKey(MonetaBottomNav.fabKey));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();

      expect(
        tabColour(tester, MonetaDestination.transactions),
        colors.brandOnSurface,
      );
    });
  });

  group('gallery', () {
    testWidgets('is reachable and has no navigation bar', (tester) async {
      // It is a development surface, not a destination.
      await pumpApp(tester, initialLocation: GalleryScreen.routePath);
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.byType(MonetaBottomNav), findsNothing);
    });
  });
}
