import 'package:flutter/material.dart' show InputDecoration, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The visual state of a [MonetaTextField], from Figma node `27:44`.
///
/// **Derived, never passed in.** A caller cannot render an error border on a
/// field with no error, or a filled field holding no text — the same reasoning
/// that keeps `state` off `BudgetCard`.
enum MonetaTextFieldState {
  /// Empty, unfocused, enabled. Shows the placeholder.
  normal,

  /// Has focus.
  focused,

  /// Holds text and does not have focus.
  filled,

  /// Carries an error message.
  error,

  /// Not accepting input.
  disabled;

  /// Works out which state a field is in.
  static MonetaTextFieldState of({
    required bool enabled,
    required bool focused,
    required bool hasText,
    required bool hasError,
  }) {
    // Order matters and is the design's: a disabled field is disabled even if
    // it holds an error, and an error outranks focus so the message is never
    // hidden by a focus ring.
    if (!enabled) return MonetaTextFieldState.disabled;
    if (hasError) return MonetaTextFieldState.error;
    if (focused) return MonetaTextFieldState.focused;
    if (hasText) return MonetaTextFieldState.filled;
    return MonetaTextFieldState.normal;
  }
}

/// A single-line text input.
///
/// From Figma node `27:44` — five states, all derived from the inputs.
///
/// Figma's note on `27:3`: *"Error state colours the border and the helper text
/// together — never colour alone."* Implemented as a width change too, so the
/// state survives greyscale.
class MonetaTextField extends StatefulWidget {
  /// Creates a text field.
  const MonetaTextField({
    this.controller,
    this.label,
    this.placeholder,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  /// The text being edited.
  final TextEditingController? controller;

  /// Label above the field. Omitted entirely when null — no reserved space.
  final String? label;

  /// Shown while the field is empty.
  final String? placeholder;

  /// Supporting line below the field.
  final String? helper;

  /// When non-null the field is in its error state and this replaces [helper].
  final String? errorText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether to hide the text, for a password.
  final bool obscureText;

  /// Keyboard to show.
  final TextInputType? keyboardType;

  /// What the keyboard's action key does.
  final TextInputAction? textInputAction;

  /// Optional glyph at the start of the field.
  final MonetaIconName? leadingIcon;

  /// Optional glyph at the end of the field.
  final MonetaIconName? trailingIcon;

  /// Called when the trailing glyph is activated — a password reveal, a clear.
  final VoidCallback? onTrailingIconPressed;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is used.
  final ValueChanged<String>? onSubmitted;

  /// Focus, so a screen can move between fields.
  final FocusNode? focusNode;

  /// Height of the field body. From `27:44`: 52, which clears the 44px touch
  /// target unaided.
  static const double fieldHeight = 52;

  /// Border colour for a state.
  static Color borderColorFor(
    MonetaTextFieldState state,
    MonetaColors colors,
  ) => switch (state) {
    MonetaTextFieldState.error => colors.expense,
    MonetaTextFieldState.focused => colors.borderFocus,
    MonetaTextFieldState.disabled => colors.borderSubtle,
    MonetaTextFieldState.normal ||
    MonetaTextFieldState.filled => colors.borderDefault,
  };

  /// Border width for a state.
  ///
  /// Three distinct widths, so error and focus are legible without colour.
  static double borderWidthFor(MonetaTextFieldState state) => switch (state) {
    MonetaTextFieldState.error => MonetaLayout.borderWidthEmphasis,
    MonetaTextFieldState.focused => MonetaLayout.borderWidthFocus,
    MonetaTextFieldState.normal ||
    MonetaTextFieldState.filled ||
    MonetaTextFieldState.disabled => MonetaLayout.borderWidthHairline,
  };

  /// Background for a state.
  static Color backgroundFor(MonetaTextFieldState state, MonetaColors colors) =>
      state == MonetaTextFieldState.disabled
      ? colors.surface
      : colors.surfaceRaised;

  /// Colour of the helper line for a state.
  static Color helperColorFor(
    MonetaTextFieldState state,
    MonetaColors colors,
  ) => switch (state) {
    MonetaTextFieldState.error => colors.expense,
    MonetaTextFieldState.disabled => colors.textDisabled,
    _ => colors.textTertiary,
  };

  @override
  State<MonetaTextField> createState() => _MonetaTextFieldState();
}

class _MonetaTextFieldState extends State<MonetaTextField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final state = MonetaTextFieldState.of(
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      hasText: _controller.text.isNotEmpty,
      hasError: widget.errorText != null,
    );

    final helperText = widget.errorText ?? widget.helper;
    final glyphColor = widget.enabled
        ? colors.textTertiary
        : colors.textDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text.labelMd.copyWith(
              color: widget.enabled
                  ? colors.textSecondary
                  : colors.textDisabled,
            ),
          ),
          const SizedBox(height: MonetaSpacing.spaceXs),
        ],
        SizedBox(
          height: MonetaTextField.fieldHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MonetaTextField.backgroundFor(state, colors),
              borderRadius: theme.radii.borderMd,
              border: Border.all(
                color: MonetaTextField.borderColorFor(state, colors),
                width: MonetaTextField.borderWidthFor(state),
              ),
              boxShadow: state == MonetaTextFieldState.focused
                  ? theme.elevation.brandGlow
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MonetaSpacing.spaceBase,
              ),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    MonetaIcon(
                      widget.leadingIcon!,
                      size: MonetaSpacing.spaceXl,
                      color: glyphColor,
                    ),
                    const SizedBox(width: MonetaSpacing.spaceMd),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      cursorColor: colors.brand,
                      style: theme.text.bodyLg.copyWith(
                        color: widget.enabled
                            ? colors.textPrimary
                            : colors.textDisabled,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.placeholder,
                        hintStyle: theme.text.bodyLg.copyWith(
                          color: widget.enabled
                              ? colors.textTertiary
                              : colors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: MonetaSpacing.spaceMd),
                    GestureDetector(
                      onTap: widget.enabled
                          ? widget.onTrailingIconPressed
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: MonetaIcon(
                        widget.trailingIcon!,
                        size: MonetaSpacing.spaceXl,
                        color: glyphColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: MonetaSpacing.spaceXs),
          Text(
            helperText,
            style: theme.text.captionMd.copyWith(
              color: MonetaTextField.helperColorFor(state, colors),
            ),
          ),
        ],
      ],
    );
  }
}
