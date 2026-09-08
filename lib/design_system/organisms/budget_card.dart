import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/amount_slot.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// One category's spend against its limit.
///
/// From Figma node `40:256`. There is deliberately **no `state` parameter**: the
/// card derives its own state from [spent] and [limit], so a caller cannot show
/// a green card for an over-budget category.
class BudgetCard extends StatelessWidget {
  /// Creates a budget card.
  const BudgetCard({
    required this.category,
    required this.spent,
    required this.limit,
    required this.note,
    this.nearLimitThreshold = BudgetStatus.defaultNearLimitThreshold,
    this.onTap,
    super.key,
  });

  /// Which category this budget covers.
  final SpendCategory category;

  /// Spent so far in the period.
  final Money spent;

  /// The budget limit.
  final Money limit;

  /// Supporting line, e.g. `61% used · 9 days left`.
  ///
  /// Passed in rather than computed: the day count depends on the period the
  /// screen is showing, which the card does not know.
  final String note;

  /// Where the warning colour begins, from the budget's own "Alert me at"
  /// setting. Defaults to 0.8, which is what `04.04` shows.
  final double nearLimitThreshold;

  /// Called when the card is activated.
  final VoidCallback? onTap;

  /// The card's derived status. Exposed so a screen can group or sort by it
  /// without re-deriving the rule.
  BudgetStatus get status => BudgetStatus.fromSpend(
    spent,
    limit,
    nearLimitThreshold: nearLimitThreshold,
  );

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final currentStatus = status;

    final statusColor = switch (currentStatus) {
      BudgetStatus.onTrack => colors.income,
      BudgetStatus.nearLimit => colors.warning,
      BudgetStatus.over => colors.expense,
    };

    // Over budget also changes the border, so the state survives greyscale —
    // colour alone is not an accessible signal.
    final borderColor = currentStatus == BudgetStatus.over
        ? colors.expense
        : colors.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: theme.radii.borderLg,
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.x3l),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowWidth = constraints.maxWidth;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CategoryIcon(
                        category: category,
                        // The name is rendered next to it, so announcing the
                        // category again would double up for a screen reader.
                        showLabelForAccessibility: false,
                      ),
                      SizedBox(width: theme.spacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: theme.text.titleMd.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: theme.spacing.xxs),
                            Text(
                              note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: theme.text.captionMd.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: theme.spacing.xl),
                      // Figma marks this column shrink-0, which overflows the
                      // row as soon as an amount is wide enough. AmountSlot
                      // documents the fix and the three attempts before it.
                      AmountSlot(
                        rowWidth: rowWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              spent.format(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: theme.text.amountMd.copyWith(
                                color: statusColor,
                              ),
                            ),
                            Text(
                              'of ${limit.format()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: theme.text.captionMd.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: theme.spacing.lg),
                  MonetaProgressBar(
                    fraction: BudgetStatus.fractionOf(spent, limit),
                    nearLimitThreshold: nearLimitThreshold,
                    semanticLabel: '${category.label} budget',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
