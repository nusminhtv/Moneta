import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/budgets/presentation/budget_detail_screen.dart';

/// Hosts [BudgetDetailScreen] for one budget id.
class BudgetDetailRouteScreen extends ConsumerWidget {
  /// Creates the host.
  const BudgetDetailRouteScreen({required this.budgetId, super.key});

  /// Which budget to show.
  final String budgetId;

  /// The entries that make up [progress]'s spend, newest first.
  ///
  /// Filtered with the same four rules the domain applies, so the list and the
  /// total cannot disagree — the screen is handed the result rather than
  /// filtering again itself.
  static List<SpendEntry> contributingTo(
    BudgetProgress progress,
    List<SpendEntry> all,
  ) => [
    for (final entry in all)
      if (progress.counts(entry)) entry,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(budgetProgressProvider).value;
    final entries = ref.watch(spendEntriesProvider).value ?? const [];

    final progress = all?.where((p) => p.budget.id == budgetId).firstOrNull;

    if (progress == null) {
      // A deleted budget reached by a stale link. Saying so beats an empty
      // screen the user has to guess about.
      return _Missing(onBack: () => context.go(BudgetRoutes.overview));
    }

    return BudgetDetailScreen(
      progress: progress,
      contributing: contributingTo(progress, entries),
      onBack: () => context.go(BudgetRoutes.overview),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return ColoredBox(
      color: theme.colors.canvas,
      child: Padding(
        padding: const EdgeInsets.all(MonetaSpacing.spaceLg),
        child: Center(
          child: EmptyState(
            icon: MonetaIconName.target,
            title: 'That budget is gone',
            message: 'It was deleted, or the link is out of date.',
            actionLabel: 'Back to budgets',
            onAction: onBack,
          ),
        ),
      ),
    );
  }
}
