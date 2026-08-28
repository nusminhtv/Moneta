import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The hero amount display, from Figma node `36:76`.
///
/// Two states. Figma's own description of the set says the error variant
/// *"differs by colour only"* — a defect stated in the source. This does not
/// reproduce it: [AmountInput.error] requires a message, so the type makes
/// "error with no message" unrepresentable and the state always carries a
/// signal that survives greyscale.
///
/// `36:64` requires tabular figures so the number does not shift width as
/// digits are typed.
class AmountInput extends StatelessWidget {
  /// The resting state, with optional guidance below the figure.
  const AmountInput({required this.amount, this.helper, super.key})
    : errorText = null;

  /// The error state. [message] is required — that is the whole point.
  const AmountInput.error({
    required this.amount,
    required String message,
    super.key,
  }) : errorText = message,
       helper = null;

  /// The figure being entered.
  final Money amount;

  /// Guidance below the figure, in the resting state.
  final String? helper;

  /// The error message. Non-null exactly when this is the error state.
  final String? errorText;

  /// Whether this is the error state.
  bool get hasError => errorText != null;

  /// Key on the caret, so a test can measure it without guessing at the box
  /// tree around it.
  static const Key caretKey = Key('AmountInput.caret');

  /// The caret's drawn width, from `36:68`: 2.
  static const double caretWidth = 2;

  /// The caret's drawn height, from `36:68`: 40.
  static const double caretHeight = 40;

  /// The caret's corner radius, from `36:68`: 1.
  ///
  /// A literal on the node, not a bound variable, so there is no token to read
  /// and inventing `radius-caret` would put a value in the token set the design
  /// file has never named. Named here with its node instead, the same way
  /// `StatTile.inset` is.
  static const double caretRadius = 1;

  /// Vertical padding around the block, from `36:64`: 24.
  static const double verticalPadding = MonetaSpacing.spaceXl;

  /// Gap between the figure and the line below it, from `36:64`: 8.
  static const double lineGap = MonetaSpacing.spaceSm;

  /// Gap between the digits, the currency glyph and the caret: 6. Off the 4px
  /// scale, so it is named here with its node rather than rounded to fit.
  static const double glyphGap = 6;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final figureColor = hasError
        ? theme.colors.expense
        : theme.colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  amount.digits(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.amountXl.copyWith(
                    color: figureColor,
                    // Tabular figures: every digit the same advance, so 111,111
                    // and 888,888 occupy the same width and the caret does not
                    // jitter as the user types.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: glyphGap),
              Text(
                amount.currency.symbol,
                style: theme.text.headingH2.copyWith(
                  color: theme.colors.textTertiary,
                ),
              ),
              const SizedBox(width: glyphGap),
              // Decorative. It says nothing a screen reader needs, and reading
              // it out would interrupt the figure.
              ExcludeSemantics(
                child: SizedBox(
                  key: caretKey,
                  width: caretWidth,
                  height: caretHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colors.brand,
                      borderRadius: BorderRadius.circular(caretRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText ?? helper case final line?) ...[
            const SizedBox(height: lineGap),
            Text(
              line,
              textAlign: TextAlign.center,
              style: theme.text.captionMd.copyWith(
                color: hasError
                    ? theme.colors.expense
                    : theme.colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
