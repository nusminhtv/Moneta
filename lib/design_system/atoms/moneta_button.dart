import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// Visual weight, from Figma node `13:2`.
enum MonetaButtonStyle {
  /// Brand fill. The one primary action on a screen.
  primary,

  /// Raised surface fill. Secondary actions beside a primary.
  secondary,

  /// Outlined. Lower weight than [secondary].
  tertiary,

  /// No fill, no border. Toolbar and inline actions.
  ghost,

  /// Expense-coloured fill. Irreversible actions only.
  destructive,
}

/// Height, from Figma node `13:2`.
///
/// Figma: *"md (44px) meets the touch target on its own; Sm (36px) must sit
/// inside a >=44px row."*
enum MonetaButtonSize {
  /// 36 tall. Only inside a row that is itself at least 44 tall.
  sm(height: 36, horizontalPadding: 14, iconSize: 16),

  /// 44 tall. Meets the touch target unaided.
  md(height: 44, horizontalPadding: 20, iconSize: 20),

  /// 56 tall. Full-width primary actions.
  lg(height: 56, horizontalPadding: 24, iconSize: 24);

  const MonetaButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.iconSize,
  });

  /// Overall height in logical pixels.
  final double height;

  /// Padding either side of the content.
  final double horizontalPadding;

  /// Size of a leading or trailing icon.
  final double iconSize;

  /// Label style for this size.
  TextStyle labelStyle(MonetaTypography text) => switch (this) {
    MonetaButtonSize.sm => text.labelMd,
    MonetaButtonSize.md => text.labelMd,
    MonetaButtonSize.lg => text.titleMd,
  };
}

/// Interaction state, from Figma node `13:2`.
enum MonetaButtonState {
  /// Interactive.
  normal,

  /// Not interactive, and visibly so.
  disabled,

  /// Working. Figma: *"Loading keeps the button width stable by swapping the
  /// label for a spinner."*
  loading,
}

/// The system's highest-reach component — Figma's words.
///
/// From node `13:2`: 5 styles × 3 sizes × 3 states = 45 variants. They are
/// resolved through three small tables rather than forty-five code paths, so
/// completeness costs a table row rather than a widget.
class MonetaButton extends StatelessWidget {
  /// Creates a button.
  const MonetaButton({
    required this.label,
    this.onPressed,
    this.style = MonetaButtonStyle.primary,
    this.size = MonetaButtonSize.md,
    this.state = MonetaButtonState.normal,
    this.leadingIcon,
    this.trailingIcon,
    this.expand = false,
    super.key,
  });

  /// Text on the button. Kept even while loading — the spinner replaces it
  /// visually, but the width it reserved does not change.
  final String label;

  /// Called on tap. Ignored unless [state] is [MonetaButtonState.normal].
  final VoidCallback? onPressed;

  /// Visual weight.
  final MonetaButtonStyle style;

  /// Height and padding.
  final MonetaButtonSize size;

  /// Interaction state.
  final MonetaButtonState state;

  /// Optional icon before the label.
  final MonetaIconName? leadingIcon;

  /// Optional icon after the label.
  final MonetaIconName? trailingIcon;

  /// Whether to fill the available width.
  final bool expand;

  /// Key on the loading spinner.
  static const Key spinnerKey = Key('MonetaButton.spinner');

  /// Whether this button responds to a tap.
  bool get isInteractive =>
      state == MonetaButtonState.normal && onPressed != null;

  /// Background for a style and state, or `null` when the style has no fill.
  ///
  /// Null rather than a transparent colour: ghost and tertiary have *no* fill,
  /// which is a different statement from "a fill you cannot see", and the
  /// design-token gate is right to reject an invented transparent constant.
  static Color? backgroundFor(
    MonetaButtonStyle style,
    MonetaButtonState state,
    MonetaColors colors,
  ) {
    // Disabled collapses every filled style onto the raised surface, exactly as
    // IconButton does — a disabled brand button is not a dimmer brand button.
    if (state == MonetaButtonState.disabled) {
      return switch (style) {
        MonetaButtonStyle.primary ||
        MonetaButtonStyle.secondary ||
        MonetaButtonStyle.destructive => colors.surfaceRaised,
        MonetaButtonStyle.tertiary || MonetaButtonStyle.ghost => null,
      };
    }
    return switch (style) {
      MonetaButtonStyle.primary => colors.brand,
      MonetaButtonStyle.secondary => colors.surfaceRaised,
      MonetaButtonStyle.destructive => colors.expense,
      MonetaButtonStyle.tertiary || MonetaButtonStyle.ghost => null,
    };
  }

  /// Foreground for a style and state.
  static Color foregroundFor(
    MonetaButtonStyle style,
    MonetaButtonState state,
    MonetaColors colors,
  ) {
    if (state == MonetaButtonState.disabled) return colors.textTertiary;
    return switch (style) {
      MonetaButtonStyle.primary ||
      MonetaButtonStyle.destructive => colors.textOnBrand,
      MonetaButtonStyle.secondary ||
      MonetaButtonStyle.tertiary ||
      MonetaButtonStyle.ghost => colors.textPrimary,
    };
  }

  /// Border for a style and state, or null when the style has none.
  static Color? borderFor(
    MonetaButtonStyle style,
    MonetaButtonState state,
    MonetaColors colors,
  ) {
    if (style != MonetaButtonStyle.tertiary) return null;
    return state == MonetaButtonState.disabled
        ? colors.borderSubtle
        : colors.borderStrong;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    final background = backgroundFor(style, state, colors);
    final foreground = foregroundFor(style, state, colors);
    final border = borderFor(style, state, colors);
    final labelStyle = size.labelStyle(theme.text).copyWith(color: foreground);

    // The label is laid out even while loading, then hidden with Opacity, so the
    // button keeps the width the label gave it. Removing it would let the button
    // shrink to spinner width mid-action.
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          MonetaIcon(leadingIcon!, size: size.iconSize, color: foreground),
          const SizedBox(width: MonetaSpacing.spaceSm),
        ],
        Flexible(
          child: Opacity(
            opacity: state == MonetaButtonState.loading ? 0 : 1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: MonetaSpacing.spaceSm),
          MonetaIcon(trailingIcon!, size: size.iconSize, color: foreground),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: label,
      child: GestureDetector(
        onTap: isInteractive ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: size.height,
          width: expand ? double.infinity : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: theme.radii.borderPill,
              border: border == null ? null : Border.all(color: border),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.horizontalPadding,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  content,
                  if (state == MonetaButtonState.loading)
                    _Spinner(color: foreground, size: size.iconSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: MonetaButton.spinnerKey,
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // design-token-ignore: the ring's stroke weight. No border-width
          // token exists — Figma authors 13:2's loading indicator as a 2px
          // stroke and nothing else in the file uses a second value, so there
          // is nothing to promote to the token layer yet.
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
