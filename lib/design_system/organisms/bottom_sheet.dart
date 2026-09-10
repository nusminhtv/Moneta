import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// A bottom sheet: grab handle, header, caller-supplied content, safe inset.
///
/// From Figma node `59:211`.
///
/// **A widget, not a `showModalBottomSheet` wrapper** (D7). The scrim on
/// `07.05` is drawn by the screen and the sheet is a sibling of it in the
/// frame, so presentation belongs to the screen. A component that shows itself
/// also cannot be rendered in the gallery, which every component in this change
/// must be.
///
/// **Its height follows its content.** Annotation `81:644`: *"the sheet height
/// is computed from its slot content, not guessed."* Content taller than the
/// space available scrolls; the handle and header do not, so the close control
/// stays reachable.
///
/// Colour roles and the corner radius are **derived, not transcribed**:
/// `59:211` could not be read when this was written, and what `proposal.md`
/// recorded while access was live is the geometry — 393 wide, a 20px handle
/// area with a 40×4 grab handle, a 60px header with a 44×44 close, and the
/// bottom safe inset. Recorded as derived in `docs/design-system/figma-map.md`
/// and queued for the `figma-fidelity` pass.
class MonetaBottomSheet extends StatelessWidget {
  /// Creates a sheet.
  const MonetaBottomSheet({
    required this.title,
    required this.child,
    this.closeSemanticLabel = 'Close',
    this.onClose,
    super.key,
  });

  /// The header's title.
  final String title;

  /// The content. Sized by its own intrinsic height, up to the space available.
  final Widget child;

  /// What the close control does, for a screen reader.
  final String closeSemanticLabel;

  /// Called when the close control is activated.
  final VoidCallback? onClose;

  /// Height of the handle area, from `59:211`: 20.
  static const double handleAreaHeight = MonetaSpacing.spaceLg;

  /// Grab handle, from `59:211`: 40 × 4.
  static const double handleWidth = 40;

  /// Grab handle height.
  static const double handleHeight = MonetaSpacing.spaceXs;

  /// Height of the header, from `59:211`: 60.
  static const double headerHeight = 60;

  /// Horizontal inset: 393 frame less the 353 content column, halved.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Key on the grab handle.
  static const Key handleKey = Key('MonetaBottomSheet.handle');

  /// Key on the bottom safe inset, so a test can measure what the device gave.
  static const Key safeInsetKey = Key('MonetaBottomSheet.safeInset');

  /// Key on the scrolling content area.
  static const Key contentKey = Key('MonetaBottomSheet.content');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    // From the device, not the authored 34. `59:211` describes one handset;
    // the same refusal to paint a fake system inset as `MonetaAppBar`.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surfaceRaised,
        borderRadius: BorderRadius.vertical(top: theme.radii.borderXl.topLeft),
      ),
      child: Column(
        // The whole point of `81:644`: the sheet is as tall as its parts need.
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: handleAreaHeight,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colors.borderStrong,
                  borderRadius: theme.radii.borderPill,
                ),
                child: const SizedBox(
                  key: handleKey,
                  width: handleWidth,
                  height: handleHeight,
                ),
              ),
            ),
          ),
          SizedBox(
            height: headerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalInset,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text.titleMd.copyWith(
                        color: theme.colors.textPrimary,
                      ),
                    ),
                  ),
                  MonetaIconButton(
                    icon: MonetaIconName.x,
                    semanticLabel: closeSemanticLabel,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
          // `Flexible`, not `Expanded`: short content keeps its own height, so
          // the sheet stays short. Tall content scrolls inside the space that
          // is left, which is what keeps the header above it reachable.
          Flexible(
            child: SingleChildScrollView(
              key: contentKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                ),
                child: child,
              ),
            ),
          ),
          SizedBox(key: safeInsetKey, height: bottomInset),
        ],
      ),
    );
  }
}
