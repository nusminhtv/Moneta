import 'package:flutter/material.dart'
    show showDatePicker, showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/create_budget_controller.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/presentation/create_budget_amount_screen.dart';
import 'package:moneta/features/budgets/presentation/create_budget_category_screen.dart';

/// Step 1 host — the category grid.
class CreateBudgetCategoryRouteScreen extends ConsumerWidget {
  /// Creates the host.
  const CreateBudgetCategoryRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(createBudgetControllerProvider);
    final budgets = ref.watch(budgetListProvider).value ?? const [];

    return CreateBudgetCategoryScreen(
      selected: draft.category,
      unavailable: unavailableCategories(
        budgets: budgets,
        period: draft.period,
      ),
      onSelect: ref
          .read(createBudgetControllerProvider.notifier)
          .chooseCategory,
      onContinue: () => context.go(BudgetRoutes.createAmount),
      onBack: () {
        // Leaving step 1 abandons the draft. Nothing was written, so there is
        // nothing to undo — but a stale category would greet the user next time
        // they start the flow.
        ref.read(createBudgetControllerProvider.notifier).reset();
        context.go(BudgetRoutes.overview);
      },
    );
  }
}

/// Step 2 host — amount, period and options.
class CreateBudgetAmountRouteScreen extends ConsumerWidget {
  /// Creates the host.
  const CreateBudgetAmountRouteScreen({super.key});

  /// The alert percentages offered.
  ///
  /// 80 is the design's default; 100 means "only tell me when I actually reach
  /// the limit", which the domain accepts.
  static const List<int> thresholdChoices = [50, 60, 70, 80, 90, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(createBudgetControllerProvider);
    final controller = ref.read(createBudgetControllerProvider.notifier);
    final category = draft.category;

    // Reaching step 2 without a category means a deep link, or a back-forward
    // through a reset draft. Sending the user to step 1 is the only honest
    // answer; rendering a form that cannot be submitted is not.
    if (category == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(BudgetRoutes.createCategory);
      });
      return const SizedBox.shrink();
    }

    return CreateBudgetAmountScreen(
      category: category,
      amount: draft.limit,
      period: draft.period,
      startsOn: draft.startsOn,
      rollsOver: draft.rollsOver,
      alertThreshold: draft.alertThreshold,
      // The failure message lands on the amount itself rather than in a
      // transient snackbar: it is a problem with that field, and a message that
      // disappears on a timer is one the user has to remember.
      errorText: draft.errorText,
      onAmountChanged: controller.setLimit,
      onPeriodChanged: controller.setPeriod,
      onEditStart: () => _pickStart(context, ref),
      onToggleRollover: controller.toggleRollover,
      onEditThreshold: () => _pickThreshold(context, ref),
      onBack: () => context.go(BudgetRoutes.createCategory),
      // Disabled rather than hidden, so the user can see the action they are
      // working towards.
      onSubmit: draft.canSubmit ? () => _submit(context, ref) : null,
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(createBudgetControllerProvider.notifier)
        .submit();
    if (!context.mounted || failure != null) return;
    ref.read(createBudgetControllerProvider.notifier).reset();
    context.go(BudgetRoutes.overview);
  }

  Future<void> _pickStart(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(createBudgetControllerProvider.notifier);
    final draft = ref.read(createBudgetControllerProvider);
    final now = ref.read(clockProvider).nowUtc().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: draft.startsOn.toLocal(),
      // A budget may start today or later. Back-dating one creates a window
      // whose spend is already fixed, which is not a budget.
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) controller.setStartsOn(picked);
  }

  Future<void> _pickThreshold(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(createBudgetControllerProvider.notifier);
    final current = ref.read(createBudgetControllerProvider).alertThreshold;

    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: context.moneta.colors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MonetaSpacing.spaceBase,
            vertical: MonetaSpacing.spaceSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final percent in thresholdChoices)
                ListRow(
                  title: '$percent%',
                  accessory: ListRowAccessory.value,
                  value: (percent / 100 - current).abs() < 0.001
                      ? 'Current'
                      : null,
                  onTap: () => Navigator.of(context).pop(percent / 100),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) controller.setAlertThreshold(picked);
  }
}
