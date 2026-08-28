import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// Visual weight of an icon button, from Figma node `20:114`.
enum MonetaIconButtonStyle {
  /// Brand fill. The primary action in a bar.
  filled,

  /// Raised surface fill. A secondary action that still reads as a button.
  tonal,

  /// No fill at all.
  ghost,
}

/// Size of an icon button, from Figma node `20:114`.
///
/// Figma's own note on `20:6`: *"Md is 44x44 and meets the touch target on its
/// own. Sm is 36x36 and must sit inside a >=44px row."*
enum MonetaIconButtonSize {
  /// 36×36 with a 16px glyph. Below the 44px minimum — only inside a row that
  /// is itself at least 44 tall.
  sm(box: 36, iconSize: 16),

  /// 44×44 with a 20px glyph. Meets the touch target unaided.
  md(box: 44, iconSize: 20),

  /// 52×52 with a 24px glyph.
  lg(box: 52, iconSize: 24);

  const MonetaIconButtonSize({required this.box, required this.iconSize});

  /// Width and height of the button.
  final double box;

  /// Edge length of the glyph inside it.
  final double iconSize;
}

/// Interaction state, from Figma node `20:114`.
enum MonetaIconButtonState {
  /// Interactive.
  normal,

  /// Inert and visibly unavailable.
  disabled,
}

/// An icon-only button.
///
/// From Figma node `20:114` — 3 styles × 3 sizes × 2 states, all 18 implemented.
///
/// The glyph is a [MonetaIconName], never a widget: Figma's note says *"Swap the
/// glyph via the Icon property — never detach"*, and taking a `Widget` would let
/// a caller draw anything and bypass the icon set entirely.
class MonetaIconButton extends StatelessWidget {
  /// Creates an icon button.
  const MonetaIconButton({
    required this.icon,
    required this.semanticLabel,
    this.style = MonetaIconButtonStyle.ghost,
    this.size = MonetaIconButtonSize.md,
    this.state = MonetaIconButtonState.normal,
    this.onPressed,
    super.key,
  });

  /// The glyph to draw.
  final MonetaIconName icon;

  /// What activating this button does, for a screen reader.
  ///
  /// Required, and describes the **action** — "Search transactions", not
  /// "search". An icon-only control has no visible text, so without this it is
  /// announced as an unlabelled button.
  final String semanticLabel;

  /// Visual weight.
  final MonetaIconButtonStyle style;

  /// Size, which also sets the glyph size.
  final MonetaIconButtonSize size;

  /// Interaction state.
  final MonetaIconButtonState state;

  /// Called when the button is activated. Ignored while [state] is disabled.
  final VoidCallback? onPressed;

  /// Background for a style and state, or null when the style has none.
  ///
  /// Read from `20:114`'s bound variables rather than inferred from
  /// `MonetaButton`'s mapping — which would have been wrong: this component's
  /// disabled glyph is `text-disabled`, where the button's is `text-tertiary`.
  static Color? backgroundFor(
    MonetaIconButtonStyle style,
    MonetaIconButtonState state,
    MonetaColors colors,
  ) => switch (style) {
    MonetaIconButtonStyle.ghost => null,
    MonetaIconButtonStyle.tonal => colors.surfaceRaised,
    MonetaIconButtonStyle.filled =>
      state == MonetaIconButtonState.disabled
          ? colors.surfaceRaised
          : colors.brand,
  };

  /// Glyph colour for a style and state.
  static Color foregroundFor(
    MonetaIconButtonStyle style,
    MonetaIconButtonState state,
    MonetaColors colors,
  ) {
    if (state == MonetaIconButtonState.disabled) return colors.textDisabled;
    return switch (style) {
      MonetaIconButtonStyle.filled => colors.textOnBrand,
      MonetaIconButtonStyle.tonal => colors.textPrimary,
      MonetaIconButtonStyle.ghost => colors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final background = backgroundFor(style, state, colors);
    final foreground = foregroundFor(style, state, colors);
    final enabled = state == MonetaIconButtonState.normal && onPressed != null;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: size.box,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: theme.radii.borderPill,
            ),
            child: Center(
              child: MonetaIcon(
                icon,
                size: size.iconSize,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
