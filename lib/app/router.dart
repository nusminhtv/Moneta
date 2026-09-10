import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/auth_routes.dart';
import 'package:moneta/app/budget_detail_route_screen.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/create_budget_route_screens.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/app/home_route_screen.dart';
import 'package:moneta/app/insights_route_screens.dart';
import 'package:moneta/app/notifications_route_screen.dart';
import 'package:moneta/app/settings_route_screens.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/app/startup_route_screen.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_providers.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_screen.dart';
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
            builder: (context, state) => const HomeRouteScreen(),
          ),
          // Inside the shell and not a destination: `04.01` says the bottom
          // nav stays on Home because Budgets is a Home sub-screen.
          GoRoute(
            path: BudgetRoutes.overview,
            builder: (context, state) => const BudgetsRouteScreen(),
          ),
          GoRoute(
            path: BudgetRoutes.detail,
            builder: (context, state) => BudgetDetailRouteScreen(
              budgetId: state.pathParameters['id']!,
            ),
          ),
          // Also inside the shell and not a destination. Annotation `57:830`:
          // *"The bottom nav stays on Home because this is a Home sub-screen —
          // a wrong active tab here is a real defect, not a nitpick."*
          //
          // **Deliberately not in the `HOME` marker block below.** That block
          // sits outside the `ShellRoute`, so a route added there renders with
          // no bottom navigation at all — which is the precise defect the
          // annotation names. The marker exists to keep parallel agents out of
          // each other's files, not to override the design; Budgets resolved
          // the same conflict the same way, two routes up.
          GoRoute(
            path: NotificationRoutes.path,
            builder: (context, state) => const NotificationsRouteScreen(),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.transactions]!,
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.insights]!,
            builder: (context, state) => const InsightsOverviewRouteScreen(),
          ),
          GoRoute(
            path: InsightsRoutes.cashFlow,
            builder: (context, state) => const CashFlowRouteScreen(),
          ),
          GoRoute(
            path: InsightsRoutes.categories,
            builder: (context, state) => const CategoryBreakdownRouteScreen(),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.profile]!,
            builder: (context, state) => const ProfileRouteScreen(),
          ),
          GoRoute(
            path: SettingsRoutes.list,
            builder: (context, state) => const SettingsRouteScreen(),
          ),
          GoRoute(
            path: SettingsRoutes.notifications,
            builder: (context, state) =>
                const NotificationSettingsRouteScreen(),
          ),
        ],
      ),
      // First run lives outside the shell: it has no navigation bar, and
      // showing one would imply the user is already in the app.
      // Outside the shell: `66:378` and `66:488` draw a bottom safe area and no
      // bottom navigation. A wizard with a tab bar invites the user to leave
      // halfway through.
      GoRoute(
        path: BudgetRoutes.createCategory,
        builder: (context, state) => const CreateBudgetCategoryRouteScreen(),
      ),
      GoRoute(
        path: BudgetRoutes.createAmount,
        builder: (context, state) => const CreateBudgetAmountRouteScreen(),
      ),
      GoRoute(
        path: SplashRoute.path,
        builder: (context, state) => StartupRouteScreen(
          onDecided: ({required showOnboarding}) => context.go(
            showOnboarding
                ? OnboardingRoute.path
                : DestinationRoutes.paths[MonetaDestination.home]!,
          ),
        ),
      ),
      GoRoute(
        path: OnboardingRoute.path,
        builder: (context, state) => const OnboardingRouteScreen(),
      ),

      // Outside the shell: the gallery is a development surface, not a
      // destination, and showing it with a nav bar would imply otherwise.
      // --- AUTH: 01.05 – 01.12 ---
      GoRoute(
        path: AuthRoutes.signUp,
        builder: (context, state) => const SignUpRoute(),
      ),
      GoRoute(
        path: AuthRoutes.logIn,
        builder: (context, state) => const LogInRoute(),
      ),
      GoRoute(
        path: AuthRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordRoute(),
      ),
      GoRoute(
        path: AuthRoutes.verify,
        builder: (context, state) => VerifyCodeRoute(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AuthRoutes.resetDone,
        builder: (context, state) => const ResetSuccessRoute(),
      ),
      GoRoute(
        path: AuthRoutes.setupCurrency,
        builder: (context, state) => const SetupCurrencyRoute(),
      ),
      GoRoute(
        path: AuthRoutes.setupBiometric,
        builder: (context, state) => const SetupBiometricRoute(),
      ),
      GoRoute(
        path: AuthRoutes.setupAccount,
        builder: (context, state) => SetupLinkAccountRoute(
          onFinished: () =>
              context.go(DestinationRoutes.paths[MonetaDestination.home]!),
        ),
      ),
      // --- AUTH: end ---

      // --- HOME: add routes below (owner: the home agent) ---
      // --- HOME: end ---
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

/// Hosts [OnboardingScreen] and records completion before leaving it.
class OnboardingRouteScreen extends ConsumerWidget {
  /// Creates the route wrapper.
  const OnboardingRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScreen(
      onFinished: () async {
        await ref.read(completeOnboardingProvider)();
        if (context.mounted) {
          context.go(DestinationRoutes.paths[MonetaDestination.home]!);
        }
      },
    );
  }
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
