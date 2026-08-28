import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// A closed dropdown.
///
/// From Figma node `38:131` — 2 states, both implemented. 52px tall to match
/// [MonetaTextField], which is what the node's own description asks for.
///
/// **It renders the closed state and delegates activation.** Figma's note on
/// `38:131`: *"Opening it presents a BottomSheet — mobile never uses an inline
/// dropdown menu here."* `BottomSheet` (`59:211`) is unimplemented, and how a
/// screen presents its options is a screen decision, so this fires [onTap] and
/// presents nothing itself.
class MonetaSelect<T> extends StatelessWidget {
  /// Creates a select.
  const MonetaSelect({
    required this.value,
    required this.labelOf,
    required this.placeholder,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  /// The chosen item, or null for the placeholder state.
  final T? value;

  /// Turns the chosen item into its display text.
  ///
  /// A function rather than a pre-formatted string, so the caller passes a
  /// domain value and formatting cannot diverge between two screens.
  final String Function(T value) labelOf;

  /// Shown while nothing is chosen.
  final String placeholder;

  /// Whether it responds.
  final bool enabled;

  /// Called when the control is activated. Presenting the options is the
  /// caller's job.
  final VoidCallback? onTap;

  /// Whether a value has been chosen.
  bool get hasValue => value != null;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    final textColor = !enabled
        ? colors.textDisabled
        : (hasValue ? colors.textPrimary : colors.textTertiary);

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: hasValue ? labelOf(value as T) : placeholder,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: MonetaTextField.fieldHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? colors.surfaceRaised : colors.surface,
              borderRadius: theme.radii.borderMd,
              border: Border.all(
                color: enabled ? colors.borderDefault : colors.borderSubtle,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MonetaSpacing.spaceBase,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? labelOf(value as T) : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.text.bodyLg.copyWith(color: textColor),
                    ),
                  ),
                  const SizedBox(width: MonetaSpacing.spaceMd),
                  MonetaIcon(
                    MonetaIconName.chevronDown,
                    size: MonetaSpacing.spaceXl,
                    color: enabled ? colors.textTertiary : colors.textDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
