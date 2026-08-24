import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// The home hero card: total balance, safe-to-spend, and the period's income
/// and expenses, on the brand gradient.
///
/// From Figma node `40:161`. Two states, `Default` and `Masked`.
class BalanceCard extends StatelessWidget {
  /// Creates a balance card.
  const BalanceCard({
    required this.totalBalance,
    required this.safeToSpend,
    required this.income,
    required this.expenses,
    required this.safeToSpendUntil,
    this.masked = false,
    this.onToggleMask,
    super.key,
  });

  /// Balance across all accounts.
  final Money totalBalance;

  /// What is left to spend in the period.
  final Money safeToSpend;

  /// Money in during the period.
  final Money income;

  /// Money out during the period. Passed as a positive amount; the card renders
  /// the minus sign.
  final Money expenses;

  /// End of the safe-to-spend period, as already-formatted text (for example
  /// `31 Aug`). Formatting a date is a locale concern, not a card concern.
  final String safeToSpendUntil;

  /// Whether the figures are hidden.
  final bool masked;

  /// Called when the mask control is activated.
  ///
  /// The card reports the request and does not decide to persist it — whether
  /// masking survives a restart is a product decision, not a card's.
  final VoidCallback? onToggleMask;

  /// Key on the mask control, for tests and for callers that need to find it.
  static const Key maskToggleKey = Key('BalanceCard.maskToggle');

  /// Placeholder magnitude used to build the mask.
  ///
  /// The mask is a **fixed** width rather than one dot per real digit: the whole
  /// point of masking is shoulder-surfing resistance, and a mask that shrinks
  /// with the amount leaks its magnitude. Figma does the same thing, with
  /// dedicated masked text nodes rather than a blur.
  static const int _maskMagnitude = 88888888;

  static String _mask(Currency currency) {
    return Money(
      _maskMagnitude * currency.scale,
      currency,
    ).format().replaceAll(RegExp(r'\d'), '•');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final onBrand = colors.textOnBrand;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: MonetaColors.brandGradient,
        borderRadius: theme.radii.borderXl,
        boxShadow: theme.elevation.level3,
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.x4l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: 0.78,
                    child: Text(
                      'Total balance',
                      style: theme.text.labelMd.copyWith(color: onBrand),
                    ),
                  ),
                ),
                GestureDetector(
                  key: maskToggleKey,
                  onTap: onToggleMask,
                  behavior: HitTestBehavior.opaque,
                  child: MonetaIcon(
                    masked ? MonetaIconName.eyeOff : MonetaIconName.eye,
                    color: onBrand,
                    semanticLabel: masked ? 'Show balance' : 'Hide balance',
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.sm),
            Text(
              masked ? _mask(totalBalance.currency) : totalBalance.format(),
              style: theme.text.amountXl.copyWith(color: onBrand),
            ),
            SizedBox(height: theme.spacing.sm),
            Opacity(
              opacity: 0.8,
              child: Text(
                masked
                    ? 'Safe to spend ${_mask(safeToSpend.currency)}'
                    : 'Safe to spend ${safeToSpend.format()} '
                          'until $safeToSpendUntil',
                style: theme.text.captionMd.copyWith(color: onBrand),
              ),
            ),
            SizedBox(height: theme.spacing.x3l),
            // Figma marks the two stats shrink-0. They are Expanded here
            // instead: authored copy fits, but real balances vary in width and
            // an overflowing row is a rendering bug, not an overflow. Recorded
            // in docs/design-system/figma-map.md.
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: MonetaIconName.arrowUpRight,
                    label: 'Income',
                    value: masked
                        ? _mask(income.currency)
                        : income.format(showSign: true),
                  ),
                ),
                SizedBox(width: theme.spacing.x4l),
                Expanded(
                  child: _Stat(
                    icon: MonetaIconName.arrowDownLeft,
                    label: 'Expenses',
                    value: masked
                        ? _mask(expenses.currency)
                        : (-expenses.abs).format(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final MonetaIconName icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final onBrand = theme.colors.textOnBrand;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MonetaIcon(icon, color: onBrand),
        SizedBox(width: theme.spacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.72,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.captionMd.copyWith(color: onBrand),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: theme.text.labelMd.copyWith(color: onBrand),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
