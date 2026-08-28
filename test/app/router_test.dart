import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/app/home_route_screen.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_providers.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_screen.dart';
import 'package:moneta/features/onboarding/presentation/splash_screen.dart';
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
      // Was `find.text('Moneta')`, which was the placeholder's title. Home is a
      // real screen now, so the assertion is on the screen, not on the copy the
      // placeholder happened to carry.
      expect(find.byType(HomeRouteScreen), findsOneWidget);
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

  group('startup', () {
    // The decision is overridden rather than read: pumpAndSettle in a FakeAsync
    // zone would never see a real sqflite read complete, so the test would hang
    // rather than fail. See CLAUDE.md.
    Future<List<int>> pumpFromSplash(
      WidgetTester tester, {
      required bool showOnboarding,
    }) async {
      final completions = <int>[];
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWith((ref) => repository),
            shouldShowOnboardingProvider.overrideWith(
              (ref) => Future.value(showOnboarding),
            ),
            completeOnboardingProvider.overrideWithValue(() async {
              completions.add(1);
            }),
          ],
          child: MaterialApp.router(
            theme: MonetaTheme.dark().toThemeData(),
            routerConfig: buildRouter(initialLocation: SplashRoute.path),
          ),
        ),
      );
      await tester.pump();
      return completions;
    }

    // pumpAndSettle alone will not do: with no animation scheduled it returns
    // on the first pump and leaves the splash's minimum-duration timer pending.
    // The duration is read off the widget so this does not hardcode 900ms.
    Future<void> settleSplash(WidgetTester tester) async {
      final splash = tester.widget<SplashScreen>(find.byType(SplashScreen));
      await tester.pump(splash.minimumDuration);
      await tester.pumpAndSettle();
    }

    testWidgets('the app opens on the splash, not on a destination', (
      tester,
    ) async {
      await pumpFromSplash(tester, showOnboarding: true);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(MonetaBottomNav), findsNothing);
      await settleSplash(tester);
    });

    testWidgets('a first run goes on to the introduction', (tester) async {
      await pumpFromSplash(tester, showOnboarding: true);
      await settleSplash(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(
        find.byType(MonetaBottomNav),
        findsNothing,
        reason: 'the introduction is not a destination inside the shell',
      );
    });

    testWidgets('a returning run goes straight to the shell', (tester) async {
      await pumpFromSplash(tester, showOnboarding: false);
      await settleSplash(tester);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(MonetaBottomNav), findsOneWidget);
      expect(tabColour(tester, MonetaDestination.home), colors.brandOnSurface);
    });

    testWidgets('finishing the introduction records it and lands on Home', (
      tester,
    ) async {
      final completions = await pumpFromSplash(tester, showOnboarding: true);
      await settleSplash(tester);

      // Skip is the shortest path through; the screen's own tests cover Next.
      await tester.tap(find.byKey(OnboardingScreen.skipKey));
      await tester.pumpAndSettle();

      expect(
        completions,
        hasLength(1),
        reason: 'left the introduction without recording it — it would return',
      );
      expect(find.byType(MonetaBottomNav), findsOneWidget);
      expect(tabColour(tester, MonetaDestination.home), colors.brandOnSurface);
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
