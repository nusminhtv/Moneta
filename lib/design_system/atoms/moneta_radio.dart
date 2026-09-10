import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// A single radio control.
///
/// From Figma node `25:238` — selected × disabled, four variants, 22×22.
///
/// **Only one control.** "Exactly one of a group is selected" is a property of
/// a group, and a control that cannot see its siblings cannot enforce it. An
/// `assert` inside here would be a guard that never fires. `MonetaRadioRow`
/// carries the group rule, driven by a single selected value.
///
/// Colour roles here are **derived from `25:229`**, the `Checkbox` set beside
/// this one on the same Atoms page, not transcribed from `25:238`: a filled
/// `brand` control with a `textOnBrand` mark, `surfaceRaised` and
/// `borderStrong` when unselected, `borderSubtle` and `textDisabled` when
/// disabled. Recorded as derived in `docs/design-system/figma-map.md` and
/// queued for the `figma-fidelity` pass, because `25:238` itself could not be
/// read when this was written.
class MonetaRadio extends StatelessWidget {
  /// Creates a radio.
  const MonetaRadio({
    required this.selected,
    required this.semanticLabel,
    this.enabled = true,
    this.onSelected,
    super.key,
  });

  /// Whether this control is the selected one.
  final bool selected;

  /// What this radio stands for, announced to a screen reader.
  final String semanticLabel;

  /// Whether it responds.
  final bool enabled;

  /// Called when the control is activated.
  ///
  /// Never called with `false`: tapping the selected radio of a group is a
  /// no-op, because a group always has a selection. Deselecting is what a
  /// checkbox does.
  final VoidCallback? onSelected;

  /// Edge length of the drawn control, from `25:238`: 22.
  static const double controlSize = 22;

  /// Edge length of the interactive area.
  ///
  /// Larger than [controlSize] for the same reason as `MonetaCheckbox`: the
  /// drawn control is below the 44px minimum, so the hit area is padded out.
  static const double hitSize = MonetaLayout.minTouchTarget;

  /// Diameter of the inner dot. Derived, not transcribed — see the class doc.
  static const double dotSize = 8;

  /// Key on the inner dot, so tests can tell selected from unselected without
  /// relying on colour alone.
  static const Key dotKey = Key('MonetaRadio.dot');

  @override
  Widget build(BuildContext context) {
    final colors = context.moneta.colors;

    final background = selected && enabled
        ? colors.brand
        : colors.surfaceRaised;
    final border = !enabled
        ? colors.borderSubtle
        : (selected ? colors.brand : colors.borderStrong);
    final dot = enabled ? colors.textOnBrand : colors.textDisabled;

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled && onSelected != null && !selected ? onSelected : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: hitSize,
          child: Center(
            child: SizedBox.square(
              dimension: controlSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                ),
                // The dot is a second distinguishable signal, so selection does
                // not rest on the fill colour alone — the same reason
                // `25:229`'s three states differ by mark and not by tint.
                child: Center(
                  child: selected
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            key: dotKey,
                            dimension: dotSize,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
