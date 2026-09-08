import 'package:flutter/widgets.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/presentation/budget_step_indicator.dart';

/// Why a category cannot be budgeted.
///
/// Modelled rather than left as a bool, because `04.03` requires the reason to
/// be *written down*: *"The disabled reason is stated in copy under the grid,
/// not left to be inferred from the dimming."* A bool cannot carry a reason.
enum CategoryUnavailable {
  /// Money coming in. A budget caps spending, so this makes no sense.
  income('Income categories cannot be budgeted.'),

  /// Already has a budget for the period being created.
  alreadyBudgeted('Categories with a budget for this period are dimmed.');

  const CategoryUnavailable(this.explanation);

  /// The sentence shown below the grid.
  final String explanation;
}

/// Step 1 of the budget wizard — Figma `66:378`.
///
/// Annotation `04.03`: *"Income categories are visibly disabled rather than
/// hidden, so the user is not left wondering where Salary went."*
class CreateBudgetCategoryScreen extends StatelessWidget {
  /// Creates step 1.
  const CreateBudgetCategoryScreen({
    required this.selected,
    required this.unavailable,
    this.onSelect,
    this.onContinue,
    this.onBack,
    super.key,
  });

  /// The chosen category, or null before anything is chosen.
  final SpendCategory? selected;

  /// Why each unavailable category cannot be picked.
  final Map<SpendCategory, CategoryUnavailable> unavailable;

  /// Called with a category when it is chosen.
  final ValueChanged<SpendCategory>? onSelect;

  /// Called when the user moves to step 2. Null disables the action.
  final VoidCallback? onContinue;

  /// Called from the app bar's back affordance.
  final VoidCallback? onBack;

  /// Categories per row, from `66:405`: 4.
  static const int columns = 4;

  /// The sentences to print below the grid, in a stable order and without
  /// repeats.
  static List<String> reasonsFor(
    Map<SpendCategory, CategoryUnavailable> unavailable,
  ) => [
    for (final reason in CategoryUnavailable.values)
      if (unavailable.containsValue(reason)) reason.explanation,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final reasons = reasonsFor(unavailable);

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(
            title: 'New budget',
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: [
                const BudgetStepIndicator(step: 1),
                const SizedBox(height: MonetaSpacing.spaceBase),
                Text(
                  'Step 1 of 2',
                  style: theme.text.labelSm.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: MonetaSpacing.spaceMd),
                Text(
                  'What are you budgeting?',
                  style: theme.text.headingH1.copyWith(
                    color: theme.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: MonetaSpacing.spaceBase),
                _CategoryGrid(
                  selected: selected,
                  unavailable: unavailable,
                  onSelect: onSelect,
                ),
                if (reasons.isNotEmpty) ...[
                  const SizedBox(height: MonetaSpacing.spaceMd),
                  for (final reason in reasons)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: MonetaSpacing.space2xs,
                      ),
                      child: Text(
                        reason,
                        style: theme.text.captionMd.copyWith(
                          color: theme.colors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MonetaSpacing.spaceLg,
              MonetaSpacing.space0,
              MonetaSpacing.spaceLg,
              MonetaSpacing.spaceBase,
            ),
            child: MonetaButton(
              label: 'Continue',
              size: MonetaButtonSize.lg,
              expand: true,
              onPressed: selected == null ? null : onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selected,
    required this.unavailable,
    required this.onSelect,
  });

  final SpendCategory? selected;
  final Map<SpendCategory, CategoryUnavailable> unavailable;
  final ValueChanged<SpendCategory>? onSelect;

  @override
  Widget build(BuildContext context) {
    const all = SpendCategory.values;
    final rows = <Widget>[];
    for (var i = 0; i < all.length; i += CreateBudgetCategoryScreen.columns) {
      final slice = all.skip(i).take(CreateBudgetCategoryScreen.columns);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in slice)
              Expanded(
                child: _CategoryCell(
                  category: category,
                  selected: category == selected,
                  unavailable: unavailable[category],
                  onSelect: onSelect,
                ),
              ),
          ],
        ),
      );
      if (i + CreateBudgetCategoryScreen.columns < all.length) {
        rows.add(const SizedBox(height: MonetaSpacing.spaceBase));
      }
    }
    return Column(children: rows);
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.unavailable,
    required this.onSelect,
  });

  final SpendCategory category;
  final bool selected;
  final CategoryUnavailable? unavailable;
  final ValueChanged<SpendCategory>? onSelect;

  /// The dimming Figma applies to a disabled disc, from `04.03`: 35%.
  static const double disabledOpacity = 0.35;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final disabled = unavailable != null;

    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: category.label,
      hint: unavailable?.explanation,
      child: GestureDetector(
        onTap: disabled || onSelect == null ? null : () => onSelect!(category),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: disabled ? disabledOpacity : 1,
              // Selection is a ring. Every cell carries one; the unselected
              // ring is painted in the canvas colour, so it is invisible and
              // still occupies its 2px — choosing a category must not nudge the
              // grid. A transparent Color literal would do the same job and is
              // a raw design value the token gate rightly refuses.
              child: Container(
                padding: const EdgeInsets.all(MonetaSpacing.space2xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? theme.colors.brand : theme.colors.canvas,
                    width: MonetaLayout.borderWidthFocus,
                  ),
                ),
                child: CategoryIcon(
                  category: category,
                  size: CategoryIconSize.lg,
                  showLabelForAccessibility: false,
                ),
              ),
            ),
            const SizedBox(height: MonetaSpacing.spaceSm),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.text.labelSm.copyWith(
                color: disabled
                    ? theme.colors.textDisabled
                    : theme.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
