import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_screen.dart';
import 'package:moneta/features/onboarding/presentation/splash_screen.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:moneta/features/transactions/presentation/transactions_screen.dart';

/// Route the app opens on.
///
/// Overridable at build time with
/// `--dart-define=MONETA_INITIAL_ROUTE=/transactions`. This exists so a
/// verification run can launch straight into a screen on a simulator, which has
/// no way to script a tap; it defaults to `/` and has no effect on a normal
/// build.
const String defaultInitialRoute = String.fromEnvironment(
  'MONETA_INITIAL_ROUTE',
  defaultValue: SplashRoute.path,
);

/// Builds the application's routes.
///
/// The four destinations live inside a shell so the bottom navigation persists
/// across them and its active tab is derived from the current location rather
/// than tracked separately.
GoRouter buildRouter({String initialLocation = defaultInitialRoute}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MonetaShell(
          onAdd: () => showAddTransactionSheet(context),
          child: child,
        ),
        routes: [
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.home]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Moneta'),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.transactions]!,
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.insights]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Insights'),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.profile]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),
      // First run lives outside the shell: it has no navigation bar, and
      // showing one would imply the user is already in the app.
      GoRoute(
        path: SplashRoute.path,
        builder: (context, state) => SplashScreen(
          onComplete: () => context.go(OnboardingRoute.path),
        ),
      ),
      GoRoute(
        path: OnboardingRoute.path,
        builder: (context, state) => OnboardingScreen(
          onFinished: () => context.go(
            DestinationRoutes.paths[MonetaDestination.home]!,
          ),
        ),
      ),
      // Outside the shell: the gallery is a development surface, not a
      // destination, and showing it with a nav bar would imply otherwise.
      GoRoute(
        path: GalleryScreen.routePath,
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
}

/// The brand splash shown while the app decides where to send the user.
abstract final class SplashRoute {
  /// Route path.
  static const String path = '/splash';
}

/// The first-run introduction.
abstract final class OnboardingRoute {
  /// Route path.
  static const String path = '/onboarding';
}

/// Opens the add-transaction sheet.
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const AddTransactionSheet(),
  );
}
