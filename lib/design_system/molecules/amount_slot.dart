import 'package:flutter/widgets.dart';

/// Caps a trailing amount at a share of its row.
///
/// A money figure inside a `Row` has no natural upper bound: it grows with the
/// number, and a wide enough one overflows the row. Three fixes were tried
/// before this one:
///
/// - Leaving it unbounded, as Figma's `shrink-0` implies. Overflows.
/// - `Flexible`, which fixes the overflow but splits the row evenly with the
///   label, truncating a short label for nothing.
/// - `TextAlign.end` inside the cap, which silently defeats it: a
///   `RenderParagraph` reports the full available width so it can align inside
///   it, so the slot always claims the whole share.
///
/// So: an explicit cap, no `textAlign`, and alignment left to the parent's
/// cross-axis alignment. The amount takes what it needs up to [share] of
/// [rowWidth], and the label takes the rest.
///
/// [rowWidth] is passed in rather than measured here because a non-flexible
/// child of a `Row` is laid out with unbounded main-axis constraints — a
/// `LayoutBuilder` in this position would see infinity. Wrap the row in the
/// `LayoutBuilder` and thread its width through.
class AmountSlot extends StatelessWidget {
  /// Creates a capped slot.
  const AmountSlot({
    required this.rowWidth,
    required this.child,
    this.share = defaultShare,
    super.key,
  });

  /// Total width available to the row this slot sits in.
  final double rowWidth;

  /// Largest fraction of [rowWidth] the slot may occupy.
  final double share;

  /// The amount to render.
  final Widget child;

  /// Chosen so a realistic amount never truncates while a pathological one
  /// cannot squeeze its label to nothing.
  static const double defaultShare = 0.55;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: rowWidth * share),
      child: child,
    );
  }
}
