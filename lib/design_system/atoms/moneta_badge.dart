import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// The five tones a [MonetaBadge] can carry, from Figma node `17:32`.
///
/// A tone owns **both** of its colours. Four of them pair a `*Subtle` fill with
/// the matching text colour; [neutral] is not such a pair and is the reason the
/// mapping is written out per tone rather than derived from a naming
/// convention — a convention with one exception is one nobody can rely on.
enum MonetaBadgeTone {
  /// `Tone=Success` — `17:2` / `17:5`.
  success,

  /// `Tone=Warning` — `17:8` / `17:11`.
  warning,

  /// `Tone=Danger` — `17:14` / `17:17`.
  danger,

  /// `Tone=Info` — `17:20` / `17:23`.
  info,

  /// `Tone=Neutral` — `17:26` / `17:29`. Fills with `surfaceRaised`, not a
  /// subtle tone, because there is no neutral semantic family.
  neutral;

  /// The pill's fill.
  Color fillIn(MonetaColors colors) => switch (this) {
    MonetaBadgeTone.success => colors.incomeSubtle,
    MonetaBadgeTone.warning => colors.warningSubtle,
    MonetaBadgeTone.danger => colors.expenseSubtle,
    MonetaBadgeTone.info => colors.infoSubtle,
    MonetaBadgeTone.neutral => colors.surfaceRaised,
  };

  /// The label's colour, which the dot also takes.
  Color labelIn(MonetaColors colors) => switch (this) {
    MonetaBadgeTone.success => colors.income,
    MonetaBadgeTone.warning => colors.warning,
    MonetaBadgeTone.danger => colors.expense,
    MonetaBadgeTone.info => colors.info,
    MonetaBadgeTone.neutral => colors.textSecondary,
  };

  /// Figma's own name for this tone, for the gallery's labels.
  String get figmaName => switch (this) {
    MonetaBadgeTone.success => 'Success',
    MonetaBadgeTone.warning => 'Warning',
    MonetaBadgeTone.danger => 'Danger',
    MonetaBadgeTone.info => 'Info',
    MonetaBadgeTone.neutral => 'Neutral',
  };
}

/// The two sizes a [MonetaBadge] can be, from Figma node `17:32`.
///
/// Per-size tables rather than a formula: the four metrics move by 2, 2, 1 and
/// 1 between the sizes, which no single ratio produces.
enum MonetaBadgeSize {
  /// `Size=Sm` — 8/3 padding, a 4 gap and a 5px dot.
  sm(
    horizontalPadding: MonetaSpacing.spaceSm,
    verticalPadding: 3,
    gap: MonetaSpacing.spaceXs,
    dotSize: 5,
  ),

  /// `Size=Md` — 10/5 padding, a 5 gap and a 6px dot.
  md(horizontalPadding: 10, verticalPadding: 5, gap: 5, dotSize: 6);

  const MonetaBadgeSize({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gap,
    required this.dotSize,
  });

  /// Inset either side of the content.
  final double horizontalPadding;

  /// Inset above and below the content.
  final double verticalPadding;

  /// Space between the dot and the label.
  final double gap;

  /// Diameter of the dot.
  final double dotSize;

  /// Figma's own name for this size.
  String get figmaName => switch (this) {
    MonetaBadgeSize.sm => 'Size=Sm',
    MonetaBadgeSize.md => 'Size=Md',
  };

  /// Total height: the label's line box plus padding either side.
  ///
  /// 22 at [sm] and 26 at [md]. Derived rather than transcribed so it stays
  /// true if the type token moves.
  double heightIn(MonetaTypography text) =>
      (text.labelSm.height! * text.labelSm.fontSize!) + verticalPadding * 2;
}

/// A status pill.
///
/// From Figma node `17:32` — 5 tones × 2 sizes, all ten implemented.
///
/// **The label is required and may not be empty.** `17:32`'s own description:
/// *"Never rely on tone alone — pair with the dot or with text."* The dot is
/// drawn in the label's colour, so it carries nothing a colour-blind reader can
/// use; the text is what actually discharges that rule. An empty string would
/// satisfy "has a label" while defeating its purpose, so it asserts.
class MonetaBadge extends StatelessWidget {
  /// Creates a badge.
  MonetaBadge({
    required this.label,
    required this.tone,
    this.size = MonetaBadgeSize.sm,
    this.dot = true,
    super.key,
  }) : assert(
         label.trim().isNotEmpty,
         'A badge must carry text: the tone alone is not a cue, and the dot '
         'takes the label colour so it adds no second channel either.',
       );

  /// What the badge says.
  final String label;

  /// Which meaning it carries.
  final MonetaBadgeTone tone;

  /// Which of the two authored sizes to draw.
  final MonetaBadgeSize size;

  /// Whether the leading dot is drawn.
  ///
  /// Defaults to true, matching the Figma property's own default. Both values
  /// are authored — `dot` is a boolean component property, not a variant axis,
  /// so no node exists for "Success/Sm without its dot".
  final bool dot;

  /// Key on the dot, so a test can find and measure it.
  static const Key dotKey = Key('MonetaBadge.dot');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final labelColor = tone.labelIn(theme.colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.fillIn(theme.colors),
        borderRadius: theme.radii.borderPill,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding,
          vertical: size.verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: labelColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(key: dotKey, dimension: size.dotSize),
              ),
              SizedBox(width: size.gap),
            ],
            // One line, truncated rather than wrapped: a pill with two lines of
            // text is not a pill. `Flexible`, so a label too long for the space
            // shrinks the text instead of overflowing the row.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.text.labelSm.copyWith(color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
