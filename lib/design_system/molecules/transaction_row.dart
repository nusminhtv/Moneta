import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/molecules/amount_slot.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// One transaction in a list.
///
/// **Designed, not transcribed.** Figma has no transaction row and no screen
/// frames, so this layout is a decision recorded in
/// `docs/adr/0003-transaction-row-layout.md` rather than a reading of the
/// canvas. Everything it draws still resolves through tokens and the shared
/// category binding, so it belongs to the same system as the rest.
class TransactionRow extends StatelessWidget {
  /// Creates a row.
  const TransactionRow({
    required this.title,
    required this.amount,
    required this.direction,
    required this.category,
    required this.occurredAt,
    this.onTap,
    super.key,
  });

  /// Primary line — the transaction's note, or its category name when it has
  /// none. Resolved by the caller, because only the domain knows the fallback.
  final String title;

  /// Positive magnitude. The row applies the sign from [direction].
  final Money amount;

  /// Whether this is money in or out.
  final TransactionDirection direction;

  /// Category, which determines the disc's tint and glyph.
  final SpendCategory category;

  /// When it happened, in UTC. Rendered in the device's local zone — the only
  /// place in the app that conversion happens.
  final DateTime occurredAt;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final isIncome = direction == TransactionDirection.income;
    final amountColor = isIncome ? colors.income : colors.expense;
    final signed = isIncome ? amount : -amount;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.x3l,
          vertical: theme.spacing.xl,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              CategoryIcon(
                category: category,
                size: CategoryIconSize.sm,
                // The title carries the meaning; announcing the category as well
                // would double up for a screen reader.
                showLabelForAccessibility: false,
              ),
              SizedBox(width: theme.spacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.text.titleMd.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xxs),
                    Text(
                      formatTimeOfDay(occurredAt),
                      maxLines: 1,
                      style: theme.text.captionMd.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.xl),
              AmountSlot(
                rowWidth: constraints.maxWidth,
                child: Text(
                  signed.format(showSign: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.text.amountMd.copyWith(color: amountColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats [instant] as a local time of day.
  ///
  /// Exposed so the grouping logic and tests use exactly the same formatting
  /// the row does.
  static String formatTimeOfDay(DateTime instant, {String? locale}) =>
      DateFormat.Hm(locale).format(instant.toLocal());
}
