import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

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
  /// Creates a progress bar.
  const MonetaProgressBar({
    required this.fraction,
    this.size = MonetaProgressBarSize.md,
    this.semanticLabel,
    super.key,
  });

  /// Spend as a fraction of the limit.
  ///
  /// Passed **unclamped** on purpose: the fill is clamped for rendering, but the
  /// colour needs the raw value to tell "at the limit" from "over it".
  final double fraction;

  /// Track height.
  final MonetaProgressBarSize size;

  /// Accessibility label. Pass null for a bar that duplicates adjacent text.
  final String? semanticLabel;

  /// Key on the filled portion, so tests can measure it.
  static const Key fillKey = Key('MonetaProgressBar.fill');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final status = BudgetStatus.fromFraction(fraction);
    final fillColor = switch (status) {
      BudgetStatus.onTrack => theme.colors.income,
      BudgetStatus.nearLimit => theme.colors.warning,
      BudgetStatus.over => theme.colors.expense,
    };

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
