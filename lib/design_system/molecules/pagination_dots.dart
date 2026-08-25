import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Position indicator for a short paged sequence.
///
/// From Figma node `70:223`. Its description states the rule this component
/// exists to enforce: *"Active dot differs in WIDTH and colour — never colour
/// alone."* Position must be readable in greyscale and by anyone who cannot
/// distinguish the brand violet from a dim white.
class MonetaPaginationDots extends StatelessWidget {
  /// Creates a position indicator.
  const MonetaPaginationDots({
    required this.count,
    required this.activeIndex,
    this.semanticLabel,
    super.key,
  });

  /// How many positions there are.
  final int count;

  /// Which position is current, zero-based.
  final int activeIndex;

  /// Accessibility label. The position itself is announced automatically.
  final String? semanticLabel;

  /// Height of every dot, and the diameter of an inactive one.
  static const double dotSize = 7;

  /// Width of the active dot — deliberately more than [dotSize].
  static const double activeDotWidth = 22;

  /// Gap between dots.
  static const double gap = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;
    assert(count > 0, 'PaginationDots needs at least one position');
    assert(
      activeIndex >= 0 && activeIndex < count,
      'activeIndex $activeIndex is outside 0..${count - 1}',
    );

    return Semantics(
      label: semanticLabel,
      value: '${activeIndex + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            SizedBox(
              width: i == activeIndex ? activeDotWidth : dotSize,
              height: dotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i == activeIndex ? colors.brand : colors.borderStrong,
                  borderRadius: BorderRadius.circular(dotSize / 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
