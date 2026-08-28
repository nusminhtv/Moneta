import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The three states a [MonetaCheckbox] can be in, from Figma node `25:229`.
enum MonetaCheckboxState {
  /// Nothing selected.
  unchecked,

  /// Selected.
  checked,

  /// Some of a group selected — a real state, not a checked variant.
  indeterminate,
}

/// A checkbox.
///
/// From Figma node `25:229` — 3 states × enabled/disabled, all six implemented.
///
/// The three states differ by **mark**, not by tint: a check glyph, a horizontal
/// bar, and nothing. Colour alone would not survive greyscale.
class MonetaCheckbox extends StatelessWidget {
  /// Creates a checkbox.
  const MonetaCheckbox({
    required this.state,
    required this.semanticLabel,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// Which state to draw.
  final MonetaCheckboxState state;

  /// What this checkbox is for, announced to a screen reader.
  final String semanticLabel;

  /// Whether it responds.
  final bool enabled;

  /// Called with the state the box should move to when activated.
  ///
  /// Indeterminate resolves to checked, which is what a partially selected
  /// group does when you tap it.
  final ValueChanged<MonetaCheckboxState>? onChanged;

  /// Edge length of the drawn box. From `25:229`.
  static const double boxSize = 22;

  /// Edge length of the interactive area.
  ///
  /// Larger than [boxSize] deliberately: the drawn box is below the 44px
  /// minimum, so the hit area is padded out to meet it.
  static const double hitSize = MonetaLayout.minTouchTarget;

  /// Width of the bar drawn for the indeterminate state.
  static const double indeterminateBarWidth = 10;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final filled = state != MonetaCheckboxState.unchecked;

    final background = !enabled
        ? colors.surfaceRaised
        : (filled ? colors.brand : colors.surfaceRaised);
    final border = !enabled ? colors.borderSubtle : colors.borderStrong;
    final markColor = enabled ? colors.textOnBrand : colors.textDisabled;

    return Semantics(
      container: true,
      checked: state == MonetaCheckboxState.checked,
      mixed: state == MonetaCheckboxState.indeterminate,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled && onChanged != null
            ? () => onChanged!(
                state == MonetaCheckboxState.checked
                    ? MonetaCheckboxState.unchecked
                    : MonetaCheckboxState.checked,
              )
            : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: hitSize,
          child: Center(
            child: SizedBox.square(
              dimension: boxSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: theme.radii.borderXs,
                  border: Border.all(
                    color: filled && enabled ? colors.brand : border,
                  ),
                ),
                child: Center(child: _mark(markColor)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark(Color color) => switch (state) {
    MonetaCheckboxState.unchecked => const SizedBox.shrink(),
    MonetaCheckboxState.checked => MonetaIcon(
      MonetaIconName.check,
      size: MonetaSpacing.spaceBase,
      color: color,
    ),
    // Drawn natively rather than instanced from the icon set: there is no
    // `minus` glyph, and adding one would change the count
    // `moneta_icon_test.dart` pins at 50 — a gate change needing prior
    // agreement, for a 10×2 rectangle.
    MonetaCheckboxState.indeterminate => SizedBox(
      width: indeterminateBarWidth,
      height: MonetaLayout.borderWidthFocus,
      child: ColoredBox(color: color),
    ),
  };
}
