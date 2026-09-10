import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Trailing treatment for [ListRow].
///
/// From Figma node `35:113`: Chevron, Value, Toggle, Badge and None.
enum ListRowAccessory {
  /// A right chevron for drill-in rows.
  chevron,

  /// A secondary value.
  value,

  /// A boolean switch.
  toggle,

  /// A compact status badge.
  badge,

  /// No trailing content.
  none,
}

/// A settings-style list row.
///
/// From Figma node `35:113`. The sibling annotation still needs live Figma
/// access; this widget implements the full authored variant set with token-only
/// layout so dependent screens can compose it.
class ListRow extends StatelessWidget {
  /// Creates a list row.
  const ListRow({
    required this.title,
    required this.accessory,
    this.subtitle,
    this.leadingIcon,
    this.value,
    this.badgeLabel,
    this.toggled = false,
    this.onTap,
    this.onToggle,
    this.destructive = false,
    super.key,
  });

  /// Primary row label.
  final String title;

  /// Optional supporting line.
  final String? subtitle;

  /// Optional leading glyph.
  final MonetaIconName? leadingIcon;

  /// Which trailing variant to render.
  final ListRowAccessory accessory;

  /// Text for [ListRowAccessory.value].
  final String? value;

  /// Text for [ListRowAccessory.badge].
  final String? badgeLabel;

  /// State for [ListRowAccessory.toggle].
  final bool toggled;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  /// Called with the next value when the toggle is activated.
  final ValueChanged<bool>? onToggle;

  /// Whether this row's action is destructive.
  ///
  /// Added for `08.01`, whose annotation `100:269` says: *"Sign out is the only
  /// destructive row and is the only label not on text/primary."* `35:113`
  /// authors no destructive variant — the screen overrides the label's colour
  /// on the instance — so this is a flag rather than a sixth accessory, and it
  /// changes **only** the title's colour. A row that also changed its
  /// background or its icon would be a variant, and the file does not author
  /// one.
  final bool destructive;

  /// Key on the toggle control.
  static const Key toggleKey = Key('ListRow.toggle');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return Semantics(
      button: onTap != null,
      toggled: accessory == ListRowAccessory.toggle ? toggled : null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MonetaSpacing.spaceBase,
              vertical: MonetaSpacing.spaceMd,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  MonetaIcon(
                    leadingIcon!,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: MonetaSpacing.spaceMd),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.text.titleMd.copyWith(
                          color: destructive
                              ? colors.expense
                              : colors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: MonetaSpacing.space2xs),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: theme.text.captionMd.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: MonetaSpacing.spaceMd),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Accessory(row: this),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Accessory extends StatelessWidget {
  const _Accessory({required this.row});

  final ListRow row;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return switch (row.accessory) {
      ListRowAccessory.chevron => MonetaIcon(
        MonetaIconName.chevronRight,
        color: colors.textTertiary,
        semanticLabel: 'Open',
      ),
      ListRowAccessory.value => Text(
        row.value ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.end,
        style: theme.text.labelMd.copyWith(color: colors.textSecondary),
      ),
      ListRowAccessory.toggle => _RowToggle(
        value: row.toggled,
        onChanged: row.onToggle,
      ),
      ListRowAccessory.badge => _RowBadge(label: row.badgeLabel ?? ''),
      ListRowAccessory.none => const SizedBox.shrink(),
    };
  }
}

class _RowBadge extends StatelessWidget {
  const _RowBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.infoSubtle,
        borderRadius: theme.radii.borderPill,
        border: Border.all(color: colors.info),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MonetaSpacing.spaceSm,
          vertical: MonetaSpacing.spaceXs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: theme.text.captionMd.copyWith(color: colors.info),
        ),
      ),
    );
  }
}

class _RowToggle extends StatelessWidget {
  const _RowToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    final trackColor = value ? colors.brand : colors.track;
    final knobAlignment = value ? Alignment.centerRight : Alignment.centerLeft;

    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        key: ListRow.toggleKey,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: MonetaLayout.minTouchTarget,
          height: MonetaLayout.minTouchTarget,
          child: Center(
            child: SizedBox(
              width: MonetaSpacing.space4xl,
              height: MonetaSpacing.spaceXl,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: theme.radii.borderPill,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(MonetaSpacing.space2xs),
                  child: Align(
                    alignment: knobAlignment,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.textOnBrand,
                        borderRadius: theme.radii.borderPill,
                      ),
                      child: const SizedBox.square(
                        dimension: MonetaSpacing.spaceLg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
