import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_radio.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One option in a radio group: a value, a title and an optional second line.
@immutable
class MonetaRadioOption<T> {
  /// Creates an option.
  const MonetaRadioOption({
    required this.value,
    required this.title,
    this.supporting,
    this.enabled = true,
  });

  /// What selecting this option means. Compared by `==` against the group's
  /// selected value, so it must be a value type.
  final T value;

  /// The option's name.
  final String title;

  /// A second line under the title, or null for a single-line row.
  final String? supporting;

  /// Whether this option can be chosen.
  final bool enabled;
}

/// A tappable row carrying one [MonetaRadio], its title and a second line.
///
/// **The whole row is the tap target**, not the 22px control. A 22px control
/// meets no touch-target guidance on its own, and a row with a title beside it
/// that does not respond to a tap on the title is a row users tap twice.
///
/// Layout is **derived, not transcribed**: `07.05`'s sheet could not be read
/// when this was written. The radio, a `spaceMd` gap, then a `bodyMd` primary
/// title over a `captionMd` tertiary supporting line — the same arrangement
/// `ListRow` uses for the same shape. Recorded as derived in
/// `docs/design-system/figma-map.md` and queued for the `figma-fidelity` pass.
class MonetaRadioRow extends StatelessWidget {
  /// Creates a row.
  const MonetaRadioRow({
    required this.title,
    required this.selected,
    this.supporting,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  /// The option's name.
  final String title;

  /// Whether this row is the selected one.
  final bool selected;

  /// A second line, or null.
  final String? supporting;

  /// Whether the row responds.
  final bool enabled;

  /// Called when anywhere on the row is tapped.
  ///
  /// Reports **which row was tapped**, not a state change — unlike
  /// [MonetaRadio.onSelected], it fires for the already-selected row too. The
  /// group turns that into a selection, which is idempotent. A row that stayed
  /// silent when tapped would be a row a caller cannot distinguish from a dead
  /// one.
  final VoidCallback? onTap;

  /// Vertical padding. Derived — see the class doc.
  static const double verticalInset = MonetaSpacing.spaceMd;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final titleColor = enabled
        ? theme.colors.textPrimary
        : theme.colors.textDisabled;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: verticalInset),
        child: Row(
          children: [
            MonetaRadio(
              selected: selected,
              semanticLabel: title,
              enabled: enabled,
              onSelected: onTap,
            ),
            const SizedBox(width: MonetaSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text.bodyMd.copyWith(color: titleColor),
                  ),
                  if (supporting case final String line)
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text.captionMd.copyWith(
                        color: theme.colors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A radio group driven by **one** selected value.
///
/// This is where the group rule lives, because this is where the group is.
/// `MonetaRadio` renders one control and cannot see its siblings, so an assert
/// inside it would be a guard that never fires.
///
/// Each row's `selected` is computed as `option.value == selected`. Two rows
/// therefore cannot both read selected — not by convention, but because there
/// is one value and equality is a function. The alternative, a list of rows
/// each carrying its own `selected` flag, makes "two selected" and "none
/// selected" both expressible.
///
/// Considered and rejected (D8): a `RadioGroup<T>` inherited widget. More
/// machinery than five options on one sheet justify, and the gallery would then
/// need a fake group to render an atom.
class MonetaRadioGroup<T> extends StatelessWidget {
  /// Creates a group.
  const MonetaRadioGroup({
    required this.options,
    required this.selected,
    this.onChanged,
    super.key,
  }) : assert(options.length > 0, 'a radio group with no options is not one');

  /// The options, in the order they are shown.
  final List<MonetaRadioOption<T>> options;

  /// The one selected value. Not nullable: a radio group always has a
  /// selection, which is what distinguishes it from a set of checkboxes.
  final T selected;

  /// Called with the value of whichever row was tapped.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          MonetaRadioRow(
            title: option.title,
            supporting: option.supporting,
            selected: option.value == selected,
            enabled: option.enabled,
            onTap: onChanged == null ? null : () => onChanged!(option.value),
          ),
      ],
    );
  }
}
