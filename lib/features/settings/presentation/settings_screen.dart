import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One row in the settings list.
///
/// The trailing accessory is **derived**, never passed: `100:728` says the
/// trailing variant is the whole information design of a settings list —
/// *"Chevron promises another screen, Toggle promises an immediate change,
/// Value shows state. Getting that mapping wrong is the most common
/// settings-screen mistake."*
///
/// So a row that navigates gets a chevron, a row that switches gets a toggle,
/// and a row with neither but a value gets a value. Deriving it means the
/// mistake is not expressible rather than merely discouraged.
@immutable
class SettingsRow extends Equatable {
  /// A row that pushes another screen.
  const SettingsRow.push({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.available = true,
  }) : value = null,
       toggled = null,
       onToggle = null;

  /// A row that changes something immediately, in place.
  const SettingsRow.toggle({
    required this.title,
    required bool this.toggled,
    required this.onToggle,
    this.subtitle,
    this.icon,
  }) : value = null,
       onTap = null,
       available = true;

  /// A row that shows its current state without being tapped.
  const SettingsRow.value({
    required this.title,
    required String this.value,
    this.subtitle,
    this.icon,
  }) : toggled = null,
       onToggle = null,
       onTap = null,
       available = true;

  /// The row's label.
  final String title;

  /// A second line, or null.
  final String? subtitle;

  /// A leading glyph, or null.
  final MonetaIconName? icon;

  /// The state a value row shows, or null.
  final String? value;

  /// A toggle row's state, or null.
  final bool? toggled;

  /// A toggle row's handler, or null.
  final ValueChanged<bool>? onToggle;

  /// A push row's handler, or null.
  final VoidCallback? onTap;

  /// Whether a push row's destination exists yet.
  ///
  /// `100:722` hides Face ID's row on a device *without biometrics* — an absent
  /// capability. A screen not yet built is a different fact: the capability
  /// exists and the screen does not. Such a row stays visible and unavailable,
  /// which tells the truth in a demo; hiding it would make the list look
  /// complete, and letting it navigate would land on a blank screen.
  final bool available;

  /// The accessory this row's behaviour implies.
  ListRowAccessory get accessory {
    if (onToggle != null) return ListRowAccessory.toggle;
    if (value != null) return ListRowAccessory.value;
    if (onTap != null) return ListRowAccessory.chevron;
    return ListRowAccessory.none;
  }

  @override
  List<Object?> get props => [title, subtitle, icon, value, toggled, available];
}

/// A labelled group of rows.
@immutable
class SettingsGroup extends Equatable {
  /// Creates a group.
  const SettingsGroup({required this.title, required this.rows});

  /// The group's heading.
  final String title;

  /// Its rows, in order.
  final List<SettingsRow> rows;

  @override
  List<Object?> get props => [title, rows];
}

/// 08.03 — the settings list.
///
/// From Figma node `100:428`. Annotation `100:716`: *"The router for the whole
/// flow. Grouped so that a user hunting for one switch scans four short lists
/// instead of one long one."*
///
/// Presentational: groups in, callbacks out, no provider read — a feature may
/// not import `lib/app`.
class SettingsScreen extends StatelessWidget {
  /// Creates the screen.
  const SettingsScreen({
    required this.groups,
    this.onBack,
    super.key,
  });

  /// The groups to render, in order.
  final List<SettingsGroup> groups;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// Content inset, from `100:451`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Settings',
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: MonetaSpacing.spaceXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in groups) ...[
                    SectionHeader(title: group.title),
                    for (final row in group.rows)
                      ListRow(
                        title: row.title,
                        subtitle: row.subtitle,
                        leadingIcon: row.icon,
                        accessory: row.accessory,
                        value: row.value,
                        toggled: row.toggled ?? false,
                        // An unavailable destination does not navigate. The row
                        // stays visible so the list keeps its authored shape.
                        onTap: row.available ? row.onTap : null,
                        onToggle: row.onToggle,
                      ),
                  ],
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
