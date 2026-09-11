import 'package:flutter/widgets.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/atoms/moneta_chip.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/settings/domain/category_usage.dart';

/// 08.08 — how much each category is actually used.
///
/// From Figma node `101:978`. Annotation `101:1107`: *"Categories are the spine
/// of every chart in the app, so they get an editing screen: rename, reorder,
/// and see how much each one is actually used."*
///
/// **This is the seeing half.** Rename, reorder and archive need a per-category
/// override layer that `CategoryIcon`, the donut and every chart would have to
/// read, and `SpendCategory` is a fixed enum in `lib/core`. So the rows carry
/// real counts and totals, and they are **not tappable** and have **no drag
/// handle**: a row that looks tappable and is not, and a handle that does not
/// drag, each promise what this screen cannot deliver. Recorded as a deviation
/// in `docs/design-system/figma-map.md`.
class ManageCategoriesScreen extends StatelessWidget {
  /// Creates the screen.
  const ManageCategoriesScreen({
    required this.usage,
    required this.direction,
    required this.onDirectionChanged,
    this.onBack,
    super.key,
  });

  /// One row per category, already sorted.
  final List<CategoryUsage> usage;

  /// Which filter chip reads selected.
  final TransactionDirection direction;

  /// Called with the direction the user picked.
  final ValueChanged<TransactionDirection> onDirectionChanged;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// Content inset, from `101:1001`'s x within `101:1000`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Gap between the two chips, from `101:1014`'s x less `101:1002`'s right.
  static const double chipGap = MonetaSpacing.spaceSm;

  /// A row's height, from `101:1027`: 56.
  static const double rowHeight = 56;

  /// Gap between the icon and the text, from `101:1032`'s x.
  static const double rowGap = MonetaSpacing.spaceMd;

  /// Key on the filter row, so a test can measure its height.
  static const Key filterRowKey = Key('ManageCategoriesScreen.filters');

  /// Key on the list, so a test can look only at the rows.
  static const Key listKey = Key('ManageCategoriesScreen.list');

  /// The chip for [direction].
  static Key chipKey(TransactionDirection direction) =>
      ValueKey('ManageCategoriesScreen.chip.${direction.name}');

  /// What the chip for [direction] says.
  static String chipLabel(TransactionDirection direction) =>
      switch (direction) {
        TransactionDirection.expense => 'Expenses',
        TransactionDirection.income => 'Income',
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Categories',
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
            // `101:1110` swaps the action to a plus. There is no screen to add
            // a category on — `08.09` is not built — so no action is drawn
            // rather than one that opens nothing.
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: MonetaSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    key: filterRowKey,
                    children: [
                      for (final option in TransactionDirection.values) ...[
                        if (option != TransactionDirection.values.first)
                          const SizedBox(width: chipGap),
                        MonetaChip(
                          key: chipKey(option),
                          label: chipLabel(option),
                          type: MonetaChipType.filter,
                          selected: option == direction,
                          onSelected: () => onDirectionChanged(option),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: MonetaSpacing.spaceSm),
                  Text(
                    'Counts and totals are for this month. Renaming and '
                    'reordering are not built yet.',
                    style: theme.text.captionMd.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceSm),
                  Column(
                    key: listKey,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final row in usage) _UsageRow(usage: row),
                    ],
                  ),
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One category, with what it was used for.
///
/// No `GestureDetector`, no `onTap`, no drag handle — see the screen's own
/// doc. The row is information, not a control.
class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.usage});

  final CategoryUsage usage;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final count = usage.count;

    return SizedBox(
      height: ManageCategoriesScreen.rowHeight,
      child: Row(
        children: [
          CategoryIcon(category: usage.category, size: CategoryIconSize.sm),
          const SizedBox(width: ManageCategoriesScreen.rowGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usage.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.titleMd.copyWith(
                    color: theme.colors.textPrimary,
                  ),
                ),
                Text(
                  count == 0
                      ? 'Not used this month'
                      : '$count ${count == 1 ? 'transaction' : 'transactions'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.captionMd.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MonetaSpacing.spaceSm),
          Text(
            usage.total.format(),
            maxLines: 1,
            style: theme.text.labelMd.copyWith(
              color: count == 0
                  ? theme.colors.textTertiary
                  : theme.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
