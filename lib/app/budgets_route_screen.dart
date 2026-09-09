import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
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
  /// Which segment of `66:117` is selected, newest last.
  ///
  /// Starts on the newest, which is the period the user is living in.
  int _selected = budgetPeriodSegments - 1;

  /// How many periods back [_selected] means.
  int get _offset => budgetPeriodSegments - 1 - _selected;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(walletCurrencyProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final budgets = ref.watch(budgetListProvider);
    final entries = ref.watch(spendEntriesProvider);

    if (budgets case AsyncError()) return const _BudgetsLoading();
    if (entries case AsyncError()) return const _BudgetsLoading();
    final budgetList = budgets.value;
    final entryList = entries.value;
    if (budgetList == null || entryList == null) {
      return const _BudgetsLoading();
    }

    // The switcher chooses which period to look at, so progress is recomputed
    // at that offset rather than filtered. `budgetProgressProvider` still
    // serves the offset-zero case for Home and notifications.
    final progress = progressAtOffset(
      budgets: budgetList,
      entries: entryList,
      now: now,
      offset: _offset,
    );

    return BudgetsScreen(
      progress: progress,
      periodLabels: budgetPeriodLabels(budgets: budgetList, now: now),
      selectedPeriod: _selected,
      hasAnyBudget: budgetList.isNotEmpty,
      currency: currency,
      now: now,
      onPeriodChanged: (i) => setState(() => _selected = i),
      onAdd: () => context.go(BudgetRoutes.createCategory),
      onOpen: (id) => context.go(BudgetRoutes.detailFor(id)),
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
