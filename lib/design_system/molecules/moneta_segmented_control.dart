import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One segment of a [MonetaSegmentedControl], from Figma node `36:167`.
///
/// Exposed so the gallery can show both variants on their own, and so a caller
/// cannot accidentally build a lookalike. Screens use the control, not this.
class MonetaSegmentedItem extends StatelessWidget {
  /// Creates a segment.
  const MonetaSegmentedItem({
    required this.label,
    required this.selected,
    super.key,
  });

  /// The segment's text.
  final String label;

  /// Whether this is the active segment.
  ///
  /// Selection is a filled surface, not only a text colour: a fill is a
  /// luminance difference, so it survives greyscale and a red-green viewer.
  final bool selected;

  /// The drawn height of a segment, from `36:167`: 9px padding around an 18px
  /// line box.
  ///
  /// This is the **drawn** height. It is below the 44px touch minimum on
  /// purpose — the control gives each segment the full track as its hit area
  /// rather than growing the drawing, so the design is unchanged and the target
  /// is still reachable.
  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? theme.colors.surfaceRaised : null,
          borderRadius: theme.radii.borderSm,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text.labelMd.copyWith(
              color: selected
                  ? theme.colors.textPrimary
                  : theme.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of two to four mutually exclusive segments, from Figma node `36:168`.
///
/// Figma's note on `36:161` is explicit that composing items beats a variant
/// per segment-count × active-index, because "that combination explodes fast".
/// So segment count is a parameter, not a variant.
///
/// **Widths are equal, and that is inferred rather than read.** The design's
/// instances are 112.33 wide inside a 353 track — not a number anyone types.
/// It is what an equal division looks like once Figma writes it down.
class MonetaSegmentedControl extends StatelessWidget {
  /// Creates a segmented control.
  const MonetaSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    this.onChanged,
    super.key,
  }) : assert(
         labels.length >= 2 && labels.length <= 4,
         'A segmented control holds 2 to 4 segments. One segment is not a '
         'choice, and five stop fitting the 353px content column.',
       );

  /// The segments, in order.
  final List<String> labels;

  /// Which segment is active.
  final int selectedIndex;

  /// Called with the tapped segment's index.
  ///
  /// Fires for the already-selected segment too, so a caller may treat a second
  /// tap as a refresh rather than having to guess.
  final ValueChanged<int>? onChanged;

  /// Track height, from `04.01`'s period switcher: a 36px segment inside 4px of
  /// padding. Also the minimum touch target, which is why the hit area is the
  /// track rather than the segment.
  static const double trackHeight = 44;

  /// Padding around the segments, and the gap between them.
  static const double gap = MonetaSpacing.spaceXs;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return SizedBox(
      height: trackHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: theme.radii.borderMd,
        ),
        child: Padding(
          // Horizontal only. The vertical inset lives inside each segment's hit
          // area, so tapping the 4px above a segment still selects it — that
          // strip is the difference between a 36px target and a 44px one.
          padding: const EdgeInsets.symmetric(horizontal: gap),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: GestureDetector(
                    onTap: onChanged == null ? null : () => onChanged!(i),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: MonetaSegmentedItem(
                        label: labels[i],
                        selected: i == selectedIndex,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
