import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// The three kinds of chip, from Figma node `17:65`.
enum MonetaChipType {
  /// `Type=Filter` — narrows a list. `101:1002` on `08.08`.
  filter,

  /// `Type=Choice` — picks one of a set.
  choice,

  /// `Type=Input` — a value the user can remove. Always carries its close
  /// control, per `17:65`'s description.
  input;

  /// Whether this type shows the trailing close control.
  ///
  /// A property of the type, not a parameter: *"Input always shows the trailing
  /// close icon"*, so a caller cannot have an input chip without one.
  bool get hasClose => this == MonetaChipType.input;

  /// Figma's own name for this type.
  String get figmaName => switch (this) {
    MonetaChipType.filter => 'Filter',
    MonetaChipType.choice => 'Choice',
    MonetaChipType.input => 'Input',
  };
}

/// A filter, choice or input chip.
///
/// From Figma node `17:65` — 3 types × selected, all six implemented.
///
/// **The chip occupies 44px of height while painting a 34px pill.** `17:65`'s
/// description makes the touch target someone else's problem — *"36px tall —
/// must sit inside a >=44px scroll row to meet the touch target"* — and a rule
/// that depends on every caller reading a sentence is a rule that gets broken.
/// `MonetaCheckbox` and `MonetaRadio` already solve this by owning a `hitSize`
/// larger than the box they draw, and this does the same.
class MonetaChip extends StatelessWidget {
  /// Creates a chip.
  MonetaChip({
    required this.label,
    required this.type,
    this.selected = false,
    this.leadingIcon,
    this.onSelected,
    this.onClose,
    this.closeSemanticLabel,
    super.key,
  }) : assert(
         label.trim().isNotEmpty,
         'A chip is its label; an empty one is an invisible tap target.',
       ),
       // `Type=Input` means "a value the user can remove", and `17:65` draws
       // its close control unconditionally. A close control that cannot close
       // is the defect deviation 31 already named — *an accessory must not
       // promise what the row cannot deliver* — so an input chip must be
       // given the action its glyph advertises, and a label for it, since
       // `icon/x` carries no authored name.
       assert(
         type != MonetaChipType.input ||
             (onClose != null &&
                 (closeSemanticLabel?.trim().isNotEmpty ?? false)),
         'An input chip always draws a close control, so it needs an onClose '
         'and a closeSemanticLabel. Use Filter or Choice for a chip that '
         'cannot be removed.',
       );

  /// What the chip says.
  final String label;

  /// Which of the three authored types this is.
  final MonetaChipType type;

  /// Whether it reads as selected.
  final bool selected;

  /// An optional leading glyph, drawn at [leadingGlyphSize].
  ///
  /// A boolean component property in Figma (`leadingIcon`), not a variant axis,
  /// so it does not multiply the variant set.
  final MonetaIconName? leadingIcon;

  /// Called when the chip's body is tapped.
  final VoidCallback? onSelected;

  /// Called when the close control is tapped. Only reachable on
  /// [MonetaChipType.input].
  final VoidCallback? onClose;

  /// What the close control is announced as. The `icon/x` glyph carries no
  /// authored label, and "x" is not one.
  final String? closeSemanticLabel;

  /// Horizontal inset, from `17:65`: 14. Off the spacing scale, which holds 12
  /// and 16.
  static const double horizontalPadding = 14;

  /// Vertical inset, from `17:65`: 8.
  static const double verticalPadding = MonetaSpacing.spaceSm;

  /// Gap between the glyph, the label and the close control: 6.
  static const double gap = 6;

  /// The leading glyph's box, from `17:34`: 16.
  ///
  /// A literal, not `MonetaSpacing.spaceBase`, even though both are 16: a glyph
  /// is not spacing, and a change to the spacing scale must not resize an icon.
  /// `MonetaLayout.iconSize` is the icon token and it is 24, so 16 has none.
  static const double leadingGlyphSize = 16;

  /// The close glyph, from `17:56`: 14.
  static const double closeGlyphSize = 14;

  /// The height the chip **occupies**, so its tap target is legal on its own.
  static const double hitHeight = MonetaLayout.minTouchTarget;

  /// The close control's tap area: a [MonetaLayout.minTouchTarget] square at
  /// the trailing end of the occupied box.
  static const double closeHitSize = MonetaLayout.minTouchTarget;

  /// Narrowest an **input** chip may be.
  ///
  /// Two touch targets side by side. Not authored: it exists so that the close
  /// control taking its 44px square cannot squeeze the select area below 44 on
  /// a short label. No authored instance is affected — `08.08`'s two chips are
  /// `Type=Filter`, which has no close control and no minimum.
  static const double inputMinimumWidth = 2 * MonetaLayout.minTouchTarget;

  /// Key on the painted pill, so a test can measure it apart from the box.
  static const Key pillKey = Key('MonetaChip.pill');

  /// Key on the close control's tap area.
  static const Key closeHitKey = Key('MonetaChip.closeHit');

  /// Key on the body's tap area.
  static const Key selectHitKey = Key('MonetaChip.selectHit');

  /// The pill's painted height: 34, the line box plus padding either side.
  ///
  /// `17:65`'s description says 36 and the frame (`101:1002`) says 34. The
  /// stroke is drawn **inside** the frame, which `DecoratedBox` wrapping
  /// `Padding` reproduces exactly — the border adds nothing to the box, where
  /// `Container` with `padding:` would inflate it by 2. Recorded in
  /// `docs/design-system/figma-map.md`.
  ///
  /// Takes the platform's text [scaler], as `MonetaSearchField.heightIn` does.
  /// Without it the pill stayed 34 at every text size and the label was
  /// **clipped** at 2× — no overflow thrown, `didExceedMaxLines` false, the
  /// text simply squeezed into an 18px line box that wanted 36. Found by
  /// `change-verifier` probing the render tree, not by the overflow test,
  /// which only ever asserted that nothing threw.
  static double pillHeightIn(MonetaTypography text, TextScaler scaler) =>
      scaler.scale(text.labelMd.height! * text.labelMd.fontSize!) +
      verticalPadding * 2;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    // Three changes at once, never one: fill, border and label move together,
    // so selection survives a reader who cannot see one of them.
    final fill = selected ? colors.brandSubtle : colors.surfaceRaised;
    final border = selected ? colors.brand : colors.borderDefault;
    final labelColor = selected ? colors.brandOnSurface : colors.textSecondary;

    final pill = DecoratedBox(
      key: pillKey,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: theme.radii.borderPill,
        // The width is left to `Border.all`'s default, which equals
        // `MonetaLayout.borderWidthHairline` today. Passing the token
        // explicitly is what a reader would prefer, and the analyzer rejects
        // it as a redundant argument — silencing that would need a
        // `// ignore:` and prior agreement, which this does not have.
        //
        // The gap it leaves is **guarded**: the test asserts the rendered
        // width equals the token, so if the token moved to 1.5 the default
        // would no longer match and the test would fail. The widget does not
        // read the token; the gate notices if that stops being equivalent.
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              MonetaIcon(
                leadingIcon!,
                size: leadingGlyphSize,
                color: labelColor,
              ),
              const SizedBox(width: gap),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.text.labelMd.copyWith(color: labelColor),
              ),
            ),
            if (type.hasClose) ...[
              const SizedBox(width: gap),
              MonetaIcon(
                MonetaIconName.x,
                size: closeGlyphSize,
                color: labelColor,
              ),
            ],
          ],
        ),
      ),
    );

    return SizedBox(
      // The occupied box is the touch target, or the pill if a larger text
      // size has made the pill the taller of the two. A fixed 44 would clip
      // the pill it exists to contain.
      height: math.max(
        hitHeight,
        pillHeightIn(theme.text, MediaQuery.textScalerOf(context)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The only non-positioned child, so it gives the stack its width.
          //
          // **Excluded from semantics.** The pill's `Text` builds its own node,
          // and the hit layer below builds a button node with the same string,
          // so a reader met "Expenses" as static text and then "Expenses,
          // button". Measured with a semantics walk, not guessed. The pill is
          // decoration; the layer that responds is the one that means
          // something.
          ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: type.hasClose ? inputMinimumWidth : 0,
              ),
              child: SizedBox(
                height: pillHeightIn(
                  theme.text,
                  MediaQuery.textScalerOf(context),
                ),
                child: pill,
              ),
            ),
          ),
          // The hit layer, over the full 44 rather than the painted 34: a box
          // that is 44 tall while only its middle 34 responds would meet the
          // rule on paper and miss it in the hand.
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: selectHitKey,
                      onTap: onSelected,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                if (type.hasClose)
                  SizedBox(
                    width: closeHitSize,
                    child: Semantics(
                      button: true,
                      label: closeSemanticLabel,
                      child: GestureDetector(
                        key: closeHitKey,
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
