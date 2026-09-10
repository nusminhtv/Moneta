import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The card `77:41`, `77:336`, `77:470` and `77:382` all wrap their content in.
class InsightsCard extends StatelessWidget {
  /// Creates a card.
  const InsightsCard({required this.child, super.key});

  /// The content.
  final Widget child;

  /// Inset inside the card, from `77:41`: 12.
  static const double inset = MonetaSpacing.spaceMd;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: theme.radii.borderLg,
        border: Border.all(color: theme.colors.borderSubtle),
      ),
      child: Padding(padding: const EdgeInsets.all(inset), child: child),
    );
  }
}
