import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/presentation/budgets_screen.dart';

/// Where the budget routes live.
///
/// Inside the shell, because annotation `04.01` says *"Bottom nav stays on Home
/// because Budgets is a Home sub-screen, not a tab."* `DestinationRoutes.of`
/// already falls back to Home for any location it does not own, so `/budgets`
/// keeps Home lit without a special case — a test pins that rather than
/// trusting it.
abstract final class BudgetRoutes {
  /// The overview.
  static const String overview = '/budgets';

  /// One budget's detail. `:id` is the budget's identifier.
  static const String detail = '/budgets/detail/:id';

  /// The detail path for [id].
  ///
  /// A function, not string concatenation at each call site: one place that
  /// knows the shape means one place to fix when it changes.
  static String detailFor(String id) => '/budgets/detail/$id';

  /// Create, step 1 — the category grid.
  static const String createCategory = '/budgets/new';

  /// Create, step 2 — amount, period and options.
  static const String createAmount = '/budgets/new/amount';
}

/// Hosts [BudgetsScreen] and supplies it with data.
class BudgetsRouteScreen extends ConsumerStatefulWidget {
  /// Creates the route wrapper.
  const BudgetsRouteScreen({super.key});

  @override
  ConsumerState<BudgetsRouteScreen> createState() => _BudgetsRouteScreenState();
}

class _BudgetsRouteScreenState extends ConsumerState<BudgetsRouteScreen> {
  BudgetPeriod _period = BudgetPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(walletCurrencyProvider);
    final progress = ref.watch(budgetProgressProvider);

    return progress.when(
      loading: _BudgetsLoading.new,
      // A read failure resolves to an empty list inside the provider, so this
      // arm is only reached by a genuine crash. The skeleton is still better
      // than a red error box.
      error: (_, _) => const _BudgetsLoading(),
      data: (all) => BudgetsScreen(
        progress: [
          for (final p in all)
            if (p.budget.period == _period) p,
        ],
        period: _period,
        currency: currency,
        onPeriodChanged: (period) => setState(() => _period = period),
        onAdd: () => context.go(BudgetRoutes.createCategory),
        onOpen: (id) => context.go(BudgetRoutes.detailFor(id)),
      ),
    );
  }
}

/// Skeletons in the shape of the content, so the layout does not jump.
class _BudgetsLoading extends StatelessWidget {
  const _BudgetsLoading();

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
          Skeleton(shape: SkeletonShape.row),
          SizedBox(height: MonetaSpacing.spaceSm),
          Skeleton(shape: SkeletonShape.row),
        ],
      ),
    );
  }
}
