import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/home/presentation/home_screen.dart';

/// Hosts [HomeScreen] and supplies it with data.
///
/// The screen itself takes a [HomeSnapshot] and nothing else, so it can be
/// tested without a database. Everything that knows where the data comes from
/// lives here, in `lib/app`.
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
  /// **The glyphs are derived, not observed.** The labels are transcribed from
  /// the frame names read on 2026-09-09, but the icons inside `52:67`, `52:81`,
  /// `52:94` and `52:106` were never read — Figma access began returning an
  /// access error mid-task, on nodes that had answered minutes earlier. `plus`
  /// carries over from the previous implementation; `repeat`, `target` and
  /// `award` are this set's nearest matches and are listed as unverified in
  /// `docs/design-system/figma-map.md`. Re-read those four nodes before
  /// treating them as transcribed.
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
      loading: () => const _HomeLoading(),
      // A read failure resolves to an empty wallet inside the provider, so this
      // arm is only reached by a genuine crash. Showing the empty screen is
      // still better than a red error box on the app's first surface.
      error: (_, _) => const _HomeLoading(),
      data: (data) => HomeScreen(
        snapshot: data,
        greeting: 'Hi there',
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
        onOpenBudget: (id) => context.go(BudgetRoutes.detailFor(id)),
        quickActions: HomeRouteScreen.quickActions(
          onAdd: () => showAddTransactionSheet(context),
          onBudgets: () => context.go(BudgetRoutes.overview),
        ),
      ),
    );
  }
}

/// Home's loading state, from Figma `52:547`.
///
/// Skeletons in the shape of the content, not a spinner: the layout does not
/// jump when the data lands.
class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return ColoredBox(
      color: theme.colors.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          MonetaSpacing.spaceLg,
          MonetaSpacing.space5xl,
          MonetaSpacing.spaceLg,
          MonetaSpacing.spaceBase,
        ),
        children: const [
          Skeleton(shape: SkeletonShape.card),
          SizedBox(height: MonetaSpacing.spaceXl),
          Skeleton(shape: SkeletonShape.line),
          SizedBox(height: MonetaSpacing.spaceBase),
          Skeleton(shape: SkeletonShape.row),
          SizedBox(height: MonetaSpacing.spaceSm),
          Skeleton(shape: SkeletonShape.row),
          SizedBox(height: MonetaSpacing.spaceSm),
          Skeleton(shape: SkeletonShape.row),
        ],
      ),
    );
  }
}
