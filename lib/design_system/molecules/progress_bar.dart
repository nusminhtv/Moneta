import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// Height variants from Figma node `21:139`.
enum MonetaProgressBarSize {
  /// 6px — inline, inside dense rows.
  sm(6),

  /// 10px — the default, used by the budget card.
  md(10);

  const MonetaProgressBarSize(this.height);

  /// Track height in logical pixels.
  final double height;

  /// Corner radius of the fill: half the height, as authored in Figma
  /// (3 for `sm`, 5 for `md`).
  double get fillRadius => height / 2;
}

/// A linear progress track whose fill colour is derived from the fraction.
///
/// Also serves as the horizontal bar mark in a ranked category chart, which is
/// why it takes a bare fraction rather than a budget.
class MonetaProgressBar extends StatelessWidget {
  /// Creates a progress bar whose colour is derived from [fraction].
  const MonetaProgressBar({
    required this.fraction,
    this.size = MonetaProgressBarSize.md,
    this.nearLimitThreshold = BudgetStatus.defaultNearLimitThreshold,
    this.semanticLabel,
    super.key,
  }) : slot = null;

  /// Creates a bar mark for a **single-series** chart, in one fixed slot.
  ///
  /// Added for `07.03`, where annotation `77:587` says both halves of a rule
  /// that the derived-colour constructor cannot satisfy at once:
  ///
  /// > *"ProgressBar is reused as the bar mark rather than adding a
  /// > HorizontalBarChart component; one series means one hue, so every bar is
  /// > the same colour and rank is carried by length and order."*
  ///
  /// Reusing the bar is the instruction; one hue is the constraint. But the
  /// default constructor derives its colour from the fraction, so the *longest*
  /// bar — which is full by construction on that screen — would come out in the
  /// near-limit warning colour while shorter bars came out green. `80:407`
  /// settles it: every bar on `77:440` is filled `chart/1`.
  ///
  /// A [ChartSlot] rather than a `Color`, for the reason `ChartLegendItem`
  /// takes one: the eight-slot palette was validated as a set, and a caller
  /// choosing a colour can leave it.
  const MonetaProgressBar.series({
    required this.fraction,
    this.slot = ChartSlot.slot1,
    this.size = MonetaProgressBarSize.md,
    this.semanticLabel,
    super.key,
  }) : nearLimitThreshold = BudgetStatus.defaultNearLimitThreshold;

  /// Spend as a fraction of the limit.
  ///
  /// Passed **unclamped** on purpose: the fill is clamped for rendering, but the
  /// colour needs the raw value to tell "at the limit" from "over it".
  final double fraction;

  /// Track height.
  final MonetaProgressBarSize size;

  /// Where the warning colour begins, from the budget's own "Alert me at"
  /// setting. Defaults to 0.8, which is what `04.04` shows.
  final double nearLimitThreshold;

  /// Accessibility label. Pass null for a bar that duplicates adjacent text.
  final String? semanticLabel;

  /// A fixed chart slot, for a single-series bar mark, or null to derive the
  /// colour from [fraction]. See [MonetaProgressBar.series].
  final ChartSlot? slot;

  /// Key on the filled portion, so tests can measure it.
  static const Key fillKey = Key('MonetaProgressBar.fill');

  /// The fill colour for a fraction.
  ///
  /// Exposed so the ring can be tested against it: two widgets showing one
  /// budget must not disagree about whether it is over.
  static Color fillColorFor(
    double fraction,
    MonetaColors colors, {
    double nearLimitThreshold = BudgetStatus.defaultNearLimitThreshold,
  }) => BudgetStatus.fromFraction(
    fraction,
    nearLimitThreshold: nearLimitThreshold,
  ).colorIn(colors);

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final fillColor =
        slot?.colorIn(theme.colors) ??
        fillColorFor(
          fraction,
          theme.colors,
          nearLimitThreshold: nearLimitThreshold,
        );

    final clamped = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        // Clipping, not just rounding: an over-budget fill must stop at the
        // track edge rather than painting past it.
        borderRadius: BorderRadius.circular(size.height),
        child: SizedBox(
          height: size.height,
          width: double.infinity,
          child: ColoredBox(
            color: theme.colors.track,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: DecoratedBox(
                  key: fillKey,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(size.fillRadius),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
