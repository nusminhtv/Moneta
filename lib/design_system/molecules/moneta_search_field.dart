import 'package:flutter/material.dart' show InputDecoration, TextField;
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// A search input.
///
/// From Figma node `35:38` — `State=Empty` and `State=Filled`, both
/// implemented.
///
/// **There is no `state` parameter.** `Filled` is a fact about the text, not a
/// choice: a field that could be told it was filled while holding nothing would
/// offer a clear control that clears nothing, and one told it was empty while
/// holding text would hide the only way out of a filter.
///
/// Deliberately **not** built on `MonetaTextField`: `27:44` is a `radius/md`
/// rectangle with label, helper and error slots and a 52px height, and `35:38`
/// is a pill with none of those at 50. Composing them would mean adding a shape
/// parameter to a shipped component to serve one caller.
class MonetaSearchField extends StatefulWidget {
  /// Creates a search field.
  const MonetaSearchField({
    required this.placeholder,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.clearSemanticLabel,
    super.key,
  });

  /// What the field says when it holds nothing — `35:25`'s "Search
  /// transactions".
  final String placeholder;

  /// The text this field edits.
  ///
  /// Optional. When absent the field creates one and disposes it; when supplied
  /// the field never disposes it, because the caller may still be using it.
  final TextEditingController? controller;

  /// Focus for the input. Owned and disposed on the same terms as [controller].
  final FocusNode? focusNode;

  /// Whether the field accepts input. A disabled field also offers no clear.
  final bool enabled;

  /// Called on every change, including the one the clear control causes — a
  /// screen filtering a list on this text has to hear that the filter is gone.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// What the clear control is announced as. The `icon/x` glyph has no authored
  /// label, and "x" is not one.
  final String? clearSemanticLabel;

  /// Horizontal inset, from `35:20`: 16.
  static const double horizontalPadding = MonetaSpacing.spaceBase;

  /// Vertical inset, from `35:20`: **13**.
  ///
  /// Off the spacing scale, which holds 12 and 16. It is authored, not rounded:
  /// `13 + 24 + 13` is the 50 that `102:1213` measures, where 12 would give
  /// the 48 the component's description claims. Recorded in
  /// `docs/design-system/figma-map.md`.
  static const double verticalPadding = 13;

  /// Gap between the glyph, the input and the clear control, from `35:20`: 10.
  /// Also off the scale, which holds 8 and 12.
  static const double gap = 10;

  /// The leading search glyph, from `35:21`: 20.
  static const double searchGlyphSize = 20;

  /// The clear glyph, from `35:35`: 18.
  static const double clearGlyphSize = 18;

  /// The clear control's tap area.
  ///
  /// Larger than [clearGlyphSize] deliberately: an 18px glyph is not a target,
  /// which is the same reason `BottomSheet`'s close control is padded out.
  static const double clearHitSize = MonetaLayout.minTouchTarget;

  /// Key on the field's painted box.
  static const Key fieldKey = Key('MonetaSearchField.field');

  /// Key on the clear control's tap area.
  static const Key clearKey = Key('MonetaSearchField.clear');

  /// The field's height: 50 — the line box plus [verticalPadding] either side.
  ///
  /// Takes the platform's text [scaler] rather than assuming 1.0, so a larger
  /// text size makes the field taller instead of overflowing it.
  ///
  /// The height is **fixed** rather than driven by the content, and that is
  /// what lets the clear control be a legal target: its 44px box is taller
  /// than the 24px line it sits beside, so a content-driven row would be
  /// `13 + 44 + 13 = 70` and the authored 50 would be gone. Measured, not
  /// assumed — the first version of this component was 70 tall and a test said
  /// so.
  static double heightIn(MonetaTypography text, TextScaler scaler) =>
      scaler.scale(text.bodyLg.height! * text.bodyLg.fontSize!) +
      verticalPadding * 2;

  @override
  State<MonetaSearchField> createState() => _MonetaSearchFieldState();
}

class _MonetaSearchFieldState extends State<MonetaSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(MonetaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replacement, which `MonetaTextField`'s `late final _controller` cannot
    // do: a field rebuilt with a different controller must read the new one,
    // and must not dispose a controller it never owned.
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  /// Rebuilds so the clear control appears and disappears with the text.
  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    // `State=Filled` is derived here and nowhere else.
    final hasText = _controller.text.isNotEmpty;
    final glyphColor = widget.enabled
        ? colors.textTertiary
        : colors.textDisabled;

    return SizedBox(
      height: MonetaSearchField.heightIn(
        theme.text,
        MediaQuery.textScalerOf(context),
      ),
      child: DecoratedBox(
        key: MonetaSearchField.fieldKey,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: theme.radii.borderPill,
          border: Border.all(color: colors.borderDefault),
        ),
        child: Padding(
          // Horizontal only: the vertical inset is inside the fixed height
          // above, so the clear control's 44px box can exceed the line box
          // without pushing the field taller than the authored 50.
          padding: const EdgeInsets.symmetric(
            horizontal: MonetaSearchField.horizontalPadding,
          ),
          child: Row(
            children: [
              // Decorative: the field itself is announced as a text field with
              // its placeholder, and a second "search" node adds nothing.
              ExcludeSemantics(
                child: MonetaIcon(
                  MonetaIconName.search,
                  size: MonetaSearchField.searchGlyphSize,
                  color: glyphColor,
                ),
              ),
              const SizedBox(width: MonetaSearchField.gap),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
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
                    hintStyle: theme.text.bodyLg.copyWith(color: glyphColor),
                  ),
                ),
              ),
              // Present exactly when there is something to clear.
              if (hasText && widget.enabled) ...[
                const SizedBox(width: MonetaSearchField.gap),
                Semantics(
                  button: true,
                  label: widget.clearSemanticLabel,
                  child: GestureDetector(
                    key: MonetaSearchField.clearKey,
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    // The glyph keeps its authored 18 inside a 44 target: the
                    // box grows, the drawing does not.
                    child: SizedBox.square(
                      dimension: MonetaSearchField.clearHitSize,
                      child: Center(
                        child: MonetaIcon(
                          MonetaIconName.x,
                          size: MonetaSearchField.clearGlyphSize,
                          color: glyphColor,
                        ),
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
