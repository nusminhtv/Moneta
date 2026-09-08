import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// The two-segment progress bar at the top of the create flow.
///
/// A local frame on `66:399`, not a component — it appears on these two screens
/// and nowhere else in the file, so promoting it to the design system would put
/// something in `design_system/` that Figma never authored as a component.
class BudgetStepIndicator extends StatelessWidget {
  /// Creates the indicator.
  const BudgetStepIndicator({required this.step, super.key});

  /// Which step is current, 1-based.
  final int step;

  /// Bar height, from `66:400`: 3.
  static const double height = 3;

  /// Gap between the two segments, from `66:401`: 4.
  static const double gap = 4;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Row(
      children: [
        for (var i = 1; i <= 2; i++) ...[
          if (i > 1) const SizedBox(width: gap),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i <= step ? theme.colors.brand : theme.colors.track,
                borderRadius: theme.radii.borderPill,
              ),
              child: const SizedBox(height: height),
            ),
          ),
        ],
      ],
    );
  }
}
