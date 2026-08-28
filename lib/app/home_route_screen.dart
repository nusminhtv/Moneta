import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        // Accounts and Budgets are not built yet. A row that goes nowhere is
        // worse than a row that plainly does not respond, so these stay null
        // until those features exist.
        onLogFirstExpense: () => showAddTransactionSheet(context),
        masked: _masked,
        onToggleMask: () => setState(() => _masked = !_masked),
        onSeeAllTransactions: () => context.go(
          DestinationRoutes.paths[MonetaDestination.transactions]!,
        ),
        quickActions: [
          (
            icon: MonetaIconName.plus,
            label: 'Add',
            onPressed: () => showAddTransactionSheet(context),
          ),
          (
            icon: MonetaIconName.list,
            label: 'History',
            onPressed: () => context.go(
              DestinationRoutes.paths[MonetaDestination.transactions]!,
            ),
          ),
          (
            icon: MonetaIconName.pieChart,
            label: 'Insights',
            onPressed: () => context.go(
              DestinationRoutes.paths[MonetaDestination.insights]!,
            ),
          ),
          (
            icon: MonetaIconName.user,
            label: 'Profile',
            onPressed: () => context.go(
              DestinationRoutes.paths[MonetaDestination.profile]!,
            ),
          ),
        ],
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
