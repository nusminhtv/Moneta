import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One legend row: a colour swatch, a category, its share and its amount.
///
/// From Figma node `47:47`, nine variants — `Slot=1`…`Slot=8` and `Slot=Other`.
///
/// `47:47`'s description: *"One row per slot plus a neutral Other. Text wears
/// text tokens; only the swatch carries identity."* Each variant repeats it:
/// *"A legend is mandatory for two or more series — identity must never be
/// colour-alone."*
///
/// That is why the row takes a [ChartSlot] and not a `Color`. The eight-slot
/// palette was validated as a set; a caller choosing colours could put two
/// adjacent series outside the validated contrast band, and `Slot=Other` could
/// become a ninth hue. Only the swatch varies between the nine variants — the
/// three text roles are identical in all of them, transcribed from `47:4`,
/// `47:5` and `47:6`.
class ChartLegendItem extends StatelessWidget {
  /// Creates a legend row.
  const ChartLegendItem({
    required this.label,
    required this.fraction,
    required this.amount,
    required this.slot,
    super.key,
  });

  /// Creates a legend row for [series], with its share of a total.
  ChartLegendItem.forSeries(
    ChartSeries series, {
    required this.fraction,
    super.key,
  }) : label = series.label,
       amount = series.amount,
       slot = series.slot;

  /// The category name. Truncates when the row is too narrow for it.
  final String label;

  /// This row's share of the whole, `0.0`–`1.0`. Formatted here, not by the
  /// caller: a legend whose percentages were rounded two different ways by two
  /// callers would not add up in either.
  final double fraction;

  /// The amount. A domain type — the row formats it.
  final Money amount;

  /// Which slot's colour the swatch carries.
  final ChartSlot slot;

  /// Swatch diameter, from `47:3`: 10. Off the 4px spacing scale, and named
  /// here rather than written as `spaceSm + 2`, which would hide that.
  static const double swatchSize = 10;

  /// Vertical padding, from `47:2`: 5. Also off-scale. With the 20px line
  /// height of `body/md` this is what makes the authored row 30 tall.
  static const double verticalInset = 5;

  /// Key on the swatch, so tests can read the colour that carries identity.
  static const Key swatchKey = Key('ChartLegendItem.swatch');

  /// [fraction] as Figma writes it — `26%`.
  ///
  /// Rounded to whole percent because `47:5` is authored that way. A share
  /// below half a percent reads `0%` rather than being hidden: the row exists,
  /// so the reader is owed the amount, and the amount is beside it.
  String get percentLabel => '${(fraction * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: verticalInset),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: slot.colorIn(theme.colors),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              key: swatchKey,
              width: swatchSize,
              height: swatchSize,
            ),
          ),
          const SizedBox(width: MonetaSpacing.spaceSm),
          // `Expanded`, so the label is the only part that gives way. `47:4` is
          // the sole `flex-[1_0_0]` child; the figures are `shrink-0`. A
          // clipped amount is a lost amount.
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.text.bodyMd.copyWith(
                color: theme.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: MonetaSpacing.spaceSm),
          Text(
            percentLabel,
            maxLines: 1,
            style: theme.text.labelMd.copyWith(
              color: theme.colors.textPrimary,
            ),
          ),
          const SizedBox(width: MonetaSpacing.spaceSm),
          Text(
            amount.format(),
            maxLines: 1,
            style: theme.text.captionMd.copyWith(
              color: theme.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
