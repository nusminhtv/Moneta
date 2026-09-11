import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The two kinds of key, from Figma node `36:91`.
///
/// **Two, not four.** `36:91`'s description claims *"2 types x 2 states"* and
/// `docs/design-system/figma-map.md` recorded four variants, but the variant
/// set contains `Type=Digit, State=Default` and `Type=Action, State=Default`
/// and nothing else. Implemented as authored; the discrepancy is recorded in
/// the map rather than resolved by inventing a state. A candidate for the
/// file's twelve deliberate mistakes.
enum NumpadKeyType {
  /// `Type=Digit` (`36:77`) — draws a label.
  digit,

  /// `Type=Action` (`36:85`) — draws a glyph instead.
  action;

  /// Figma's own name for this type.
  String get figmaName => switch (this) {
    NumpadKeyType.digit => 'Digit',
    NumpadKeyType.action => 'Action',
  };
}

/// One key of a [Numpad].
///
/// From Figma node `36:91`. Public rather than private because an authored
/// component set must appear in the gallery, the way
/// `MonetaSegmentedItem`/`MonetaSegmentedControl` already are.
class NumpadKey extends StatelessWidget {
  /// Creates a key.
  const NumpadKey({
    required this.type,
    this.label,
    this.glyph,
    this.onTap,
    this.semanticLabel,
    super.key,
  }) : assert(
         type == NumpadKeyType.action || label != null,
         'A digit key is its label.',
       ),
       assert(
         type == NumpadKeyType.digit || glyph != null,
         'An action key is its glyph.',
       );

  /// Which of the two authored types this is.
  final NumpadKeyType type;

  /// What a [NumpadKeyType.digit] key draws.
  final String? label;

  /// What a [NumpadKeyType.action] key draws instead.
  final MonetaIconName? glyph;

  /// Called when the key is pressed. A key without one is inert and silent.
  final VoidCallback? onTap;

  /// What the key is announced as. Defaults to [label] for a digit.
  final String? semanticLabel;

  /// Key height, from `36:77`: 56.
  ///
  /// Its own description explains the number: *"comfortably above the 44px
  /// minimum because this is the most-tapped control in the app."*
  static const double height = 56;

  /// The action key's glyph size, from `36:87`: 22.
  static const double glyphSize = 22;

  // `36:77` also carries `radius/md`, and this component does not use it. The
  // key has no fill and the set has no pressed state, so there is nothing for
  // a rounded box to clip or paint — a constant here would be dead in the
  // render tree, and a test asserting it would assert the implementation back
  // to itself, which CLAUDE.md rules out. The authored value is recorded in
  // `docs/design-system/figma-map.md` instead, which is where a number with no
  // rendered consequence belongs.

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height,
          child: Center(
            child: switch (type) {
              NumpadKeyType.digit => Text(
                label!,
                maxLines: 1,
                style: theme.text.headingH2.copyWith(
                  color: theme.colors.textPrimary,
                ),
              ),
              NumpadKeyType.action => MonetaIcon(
                glyph!,
                size: glyphSize,
                color: theme.colors.textPrimary,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// What occupies the pad's third-last cell.
///
/// `36:92` is authored **for amount entry** and puts a decimal key there.
/// `08.05` reuses the pad for a six-digit PIN, where a decimal cannot be typed,
/// so the cell is the caller's choice and has **no default** — a caller must
/// say which it means.
enum NumpadTrailing {
  /// The authored decimal key.
  decimalPoint,

  /// Nothing. An empty cell, not a key that looks live and does nothing.
  empty,
}

/// A numeric keypad.
///
/// From Figma node `36:92` — one variant: three columns by four rows.
///
/// The rows **fill** the width they are given rather than assuming one:
/// `36:92`'s description says *"Rows are FILL so the pad always spans the 353px
/// content column"*, and `08.05` places it across the full 393 instead.
class Numpad extends StatelessWidget {
  /// Creates a pad.
  const Numpad({
    required this.trailing,
    this.onDigit,
    this.onDecimal,
    this.onBackspace,
    super.key,
  });

  /// What the third-last cell holds. Required: see [NumpadTrailing].
  final NumpadTrailing trailing;

  /// Called with the digit pressed, as written on the key.
  final ValueChanged<String>? onDigit;

  /// Called when the decimal key is pressed. Unreachable when [trailing] is
  /// [NumpadTrailing.empty].
  final VoidCallback? onDecimal;

  /// Called when the action key is pressed.
  final VoidCallback? onBackspace;

  /// Gap between keys and between rows, from `36:93`: 8.
  static const double gap = MonetaSpacing.spaceSm;

  /// Inset above and below the grid, from `36:92`: 12.
  static const double verticalPadding = MonetaSpacing.spaceMd;

  /// The action key's glyph.
  ///
  /// `icon/chevron-left` (`10:39`), as authored. **The 50-icon set contains no
  /// backspace or delete glyph**, which is why a delete key wears a chevron;
  /// recorded in `figma-map.md` as an observation, not corrected.
  static const MonetaIconName actionGlyph = MonetaIconName.chevronLeft;

  /// The digits, in the reading order `36:92` lays them out.
  static const List<List<String>> digitRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  /// The key carrying [digit], so a test can address one key.
  static Key keyFor(String digit) => ValueKey('Numpad.$digit');

  /// The decimal key.
  static const Key decimalKey = Key('Numpad.decimal');

  /// The action key.
  static const Key actionKey = Key('Numpad.action');

  /// The empty cell that replaces the decimal key for a PIN.
  static const Key emptyCellKey = Key('Numpad.empty');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: verticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in digitRows) ...[
              _row([for (final digit in row) _digit(digit)]),
              const SizedBox(height: gap),
            ],
            _row([
              switch (trailing) {
                NumpadTrailing.decimalPoint => NumpadKey(
                  key: decimalKey,
                  type: NumpadKeyType.digit,
                  label: '.',
                  onTap: onDecimal,
                ),
                // A cell, not a key: nine keys and a tenth that does nothing
                // would look identical, and the first bug report would be
                // "the dot key is broken".
                NumpadTrailing.empty => const SizedBox(
                  key: emptyCellKey,
                  height: NumpadKey.height,
                ),
              },
              _digit('0'),
              NumpadKey(
                key: actionKey,
                type: NumpadKeyType.action,
                glyph: actionGlyph,
                onTap: onBackspace,
                semanticLabel: 'Delete',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _digit(String digit) => NumpadKey(
    key: keyFor(digit),
    type: NumpadKeyType.digit,
    label: digit,
    onTap: onDigit == null ? null : () => onDigit!(digit),
  );

  /// One row of three equal cells.
  ///
  /// `Expanded`, so the row spans whatever width it is given — 353 in the
  /// component, 393 on `08.05` — and so three keys never overflow a narrow
  /// one.
  ///
  /// **The direction is pinned to LTR.** A plain `Row` mirrors under
  /// `TextDirection.rtl`, which would put `1` at the top right and `3` at the
  /// top left. A keypad's digits are positional, not text: every phone dialer
  /// and system keypad keeps 1 at the top left in right-to-left locales, and
  /// mirroring them would make a memorised PIN wrong. Found by the RTL test,
  /// which failed against the naive row.
  Widget _row(List<Widget> cells) => Row(
    textDirection: TextDirection.ltr,
    children: [
      for (var i = 0; i < cells.length; i++) ...[
        if (i > 0) const SizedBox(width: gap),
        Expanded(child: cells[i]),
      ],
    ],
  );
}
