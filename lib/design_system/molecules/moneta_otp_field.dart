import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// How much of the code has been entered, from Figma node `70:263`.
enum MonetaOtpFillState {
  /// Nothing entered.
  empty,

  /// Some but not all.
  partial,

  /// Every box filled.
  complete,
}

/// A six-box one-time-code field.
///
/// From Figma node `70:263` — 3 fill states, all implemented.
///
/// Fill state is **derived** from the code, never passed in: a caller cannot
/// render a complete field holding an incomplete code. The focus ring marks the
/// next empty box, which is Figma's own rule on `70:224` — *"the user always
/// knows where the caret is"*.
class MonetaOtpField extends StatelessWidget {
  /// Creates an OTP field.
  const MonetaOtpField({
    required this.code,
    this.length = defaultLength,
    super.key,
  }) : assert(code.length <= length, 'code is longer than the field');

  /// The digits entered so far.
  final String code;

  /// How many boxes there are.
  final int length;

  /// The length Figma draws.
  static const int defaultLength = 6;

  /// Height of one box. From `70:263`: 56, clearing the touch target.
  static const double boxHeight = 56;

  /// Gap between boxes.
  static const double gap = 9;

  /// Which fill state a code of this length puts the field in.
  static MonetaOtpFillState stateOf(String code, int length) {
    if (code.isEmpty) return MonetaOtpFillState.empty;
    if (code.length >= length) return MonetaOtpFillState.complete;
    return MonetaOtpFillState.partial;
  }

  /// This field's fill state.
  MonetaOtpFillState get state => stateOf(code, length);

  /// Index of the box carrying the focus ring, or null when the code is
  /// complete and there is no next box.
  int? get focusedIndex => code.length >= length ? null : code.length;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final focused = focusedIndex;

    return Semantics(
      container: true,
      label: 'One-time code, ${code.length} of $length digits entered',
      child: Row(
        children: [
          for (var index = 0; index < length; index++) ...[
            if (index > 0) const SizedBox(width: gap),
            Expanded(
              child: SizedBox(
                height: boxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: theme.radii.borderMd,
                    border: Border.all(
                      color: index == focused
                          ? colors.borderFocus
                          : colors.borderDefault,
                      width: index == focused
                          ? MonetaLayout.borderWidthFocus
                          : MonetaLayout.borderWidthHairline,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      index < code.length ? code[index] : '',
                      // display/amount-md, for tabular figures: Figma's note
                      // says a code that shifts width as you type feels broken.
                      style: theme.text.amountMd.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
