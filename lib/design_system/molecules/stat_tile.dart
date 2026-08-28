import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Which way a stat moved, from Figma node `35:137`.
///
/// `35:114`'s description: *"The delta uses colour AND an arrow direction so it
/// is readable without colour."*
enum StatDelta {
  /// Rose. Income colour and an up-right arrow.
  up(MonetaIconName.arrowUpRight),

  /// Fell. Expense colour and a down-left arrow.
  down(MonetaIconName.arrowDownLeft),

  /// Unchanged. No arrow, tertiary text — a third distinguishable state, not
  /// the absence of one.
  flat(null);

  const StatDelta(this.arrow);

  /// The glyph, or null for [flat].
  final MonetaIconName? arrow;

  /// The colour this direction reads in.
  Color colorIn(MonetaColors colors) => switch (this) {
    StatDelta.up => colors.income,
    StatDelta.down => colors.expense,
    StatDelta.flat => colors.textTertiary,
  };
}

/// A small KPI tile: a label, an amount, and how it moved.
///
/// From Figma node `35:137` — three delta directions. `35:137`'s description
/// says 170px wide "so two fit side by side inside the 353px content column
/// with a 13px gap", while the screens that use it place two 170.5 tiles 12
/// apart. The tile therefore takes the width it is given rather than pinning
/// one, and the screen decides the gap.
///
/// **Direction is the caller's, not the tile's.** Figma's own sample reads
/// "Spent this month / +12.4% vs last month" in income green — spending more,
/// coloured as good news. The mapping stays as authored because a tile is not
/// only ever about spending; it is the screen's job to pass [StatDelta.down]
/// for spending that rose.
class StatTile extends StatelessWidget {
  /// Creates a tile.
  const StatTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
    super.key,
  });

  /// What the figure measures.
  final String label;

  /// The figure itself. A domain type, not a formatted string.
  final Money value;

  /// Which way it moved.
  final StatDelta delta;

  /// How it moved, in words — "+12.4% vs last month".
  final String deltaLabel;

  /// Padding inside the tile, from `35:114`: 14.
  ///
  /// Off the 4px spacing scale, and named here rather than dressed up as
  /// `spaceMd + 2`, which would hide that. Same precedent as
  /// `MonetaTextField.fieldHeight`: a measurement belonging to one component
  /// lives on that component, with the node it came from.
  static const double inset = 14;

  /// Vertical gap between the three lines, from `35:114`: 6. Also off-scale.
  static const double lineGap = 6;

  /// Gap between the arrow and its label, from `35:117`: 3. Also off-scale.
  static const double arrowGap = 3;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final deltaColor = delta.colorIn(theme.colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surfaceRaised,
        borderRadius: theme.radii.borderLg,
        border: Border.all(color: theme.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text.captionMd.copyWith(
                color: theme.colors.textTertiary,
              ),
            ),
            const SizedBox(height: lineGap),
            Text(
              value.format(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text.amountMd.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
            const SizedBox(height: lineGap),
            Row(
              children: [
                if (delta.arrow case final arrow?) ...[
                  MonetaIcon(
                    arrow,
                    size: MonetaSpacing.spaceBase,
                    color: deltaColor,
                  ),
                  const SizedBox(width: arrowGap),
                ],
                Flexible(
                  child: Text(
                    deltaLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.labelSm.copyWith(color: deltaColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
