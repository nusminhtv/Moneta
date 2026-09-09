import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/app/notifications_route_screen.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/home/presentation/home_loading_screen.dart';
import 'package:moneta/features/home/presentation/home_screen.dart';

/// Hosts [HomeScreen] and supplies it with data.
///
/// The screen itself takes a [HomeSnapshot] and nothing else, so it can be
/// tested without a database. Everything that knows where the data comes from
/// lives here, in `lib/app`.
/// The app bar title on every Home state.
///
/// One constant, because annotation `52:630` requires the bar to be identical
/// while loading and once loaded. Two literals would be free to drift apart.
const String _greeting = 'Hi there';

class HomeRouteScreen extends ConsumerStatefulWidget {
  /// Creates the route wrapper.
  const HomeRouteScreen({super.key});

  /// Home's quick-actions row, as authored at `52:66`, `52:80`, `52:93` and
  /// `52:105`: Add, Transfer, Budgets, Goals.
  ///
  /// This replaces a shipped set of Add, History, Insights and Profile that
  /// matched no Figma node.
  ///
  /// **Transfer and Goals are deliberately dead.** Neither feature exists, so
  /// they render disabled rather than being dropped or pointed somewhere
  /// plausible. Dropping them would quietly redesign the frame's four-up row;
  /// wiring them would lie. It is the rule `onLinkAccount` already set: a
  /// control that goes nowhere is worse than one that plainly does not respond.
  ///
  /// **The glyphs are verified.** They were derived first, while Figma access
  /// was down, and read afterwards once it returned: `52:67` is `icon/plus`
  /// (`10:29`), `52:81` is `icon/repeat` (`10:63`), `52:94` is `icon/target`
  /// (`10:20`) and `52:106` is `icon/award` (`11:83`). All four guesses matched.
  ///
  /// Recording that they were *guesses that happened to be right* rather than
  /// quietly relabelling them as transcriptions: the process was wrong even
  /// though the answer was not, and the next set of four might not match.
  /// `Style=Tonal, Size=Md` (`20:54`, 44×44) and the `label/sm` +
  /// `text-secondary` caption were confirmed at the same time.
  ///
  /// A function rather than a literal inside `build` so the authored set is
  /// reachable from a test without pumping a router.
  static List<HomeQuickAction> quickActions({
    required VoidCallback onAdd,
    required VoidCallback onBudgets,
  }) => [
    (icon: MonetaIconName.plus, label: 'Add', onPressed: onAdd),
    (icon: MonetaIconName.repeat, label: 'Transfer', onPressed: null),
    (icon: MonetaIconName.target, label: 'Budgets', onPressed: onBudgets),
    (icon: MonetaIconName.award, label: 'Goals', onPressed: null),
  ];

  @override
  ConsumerState<HomeRouteScreen> createState() => _HomeRouteScreenState();
}

class _HomeRouteScreenState extends ConsumerState<HomeRouteScreen> {
  bool _masked = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(homeSnapshotProvider);

    return snapshot.when(
      loading: () => HomeLoadingScreen(
        greeting: _greeting,
        onOpenNotifications: () => context.go(NotificationRoutes.path),
      ),
      // A read failure resolves to an empty wallet inside the provider, so this
      // arm is only reached by a genuine crash. Showing the empty screen is
      // still better than a red error box on the app's first surface.
      error: (_, _) => HomeLoadingScreen(
        greeting: _greeting,
        onOpenNotifications: () => context.go(NotificationRoutes.path),
      ),
      data: (data) => HomeScreen(
        snapshot: data,
        greeting: _greeting,
        now: ref.watch(clockProvider).nowUtc(),
        // Accounts is still not built. A row that goes nowhere is worse than a
        // row that plainly does not respond, so it stays null until it exists.
        onLogFirstExpense: () => showAddTransactionSheet(context),
        onSetBudget: () => context.go(BudgetRoutes.overview),
        masked: _masked,
        onToggleMask: () => setState(() => _masked = !_masked),
        onSeeAllTransactions: () => context.go(
          DestinationRoutes.paths[MonetaDestination.transactions]!,
        ),
        onSeeAllBudgets: () => context.go(BudgetRoutes.overview),
        onOpenNotifications: () => context.go(NotificationRoutes.path),
        onOpenBudget: (id) => context.go(BudgetRoutes.detailFor(id)),
        quickActions: HomeRouteScreen.quickActions(
          onAdd: () => showAddTransactionSheet(context),
          onBudgets: () => context.go(BudgetRoutes.overview),
        ),
      ),
    );
  }
}
