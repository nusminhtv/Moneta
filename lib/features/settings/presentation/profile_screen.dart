import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One of the three figures across the top of `08.01`.
///
/// Annotation `100:275` is emphatic about what this is **not**: *"The stat
/// tiles are local, not StatTile. StatTile is built around a delta with a
/// direction arrow, and 'days tracked' has no delta. Reuse that fights the
/// component's meaning is worse than a local frame."*
@immutable
class ProfileStat extends Equatable {
  /// Creates a stat.
  const ProfileStat({required this.value, required this.label});

  /// The figure, already formatted — these are counts and durations, not
  /// money, so there is no domain type to take.
  final String value;

  /// What it counts.
  final String label;

  @override
  List<Object?> get props => [value, label];
}

/// 08.01 — the fourth tab.
///
/// From Figma node `100:2`. Annotation `100:263`: *"The fourth tab. Identity on
/// top, three vanity stats that give a sense of history, then the menu that
/// everything else in this flow hangs off."*
///
/// Presentational: values and callbacks in, no provider read.
class ProfileScreen extends StatelessWidget {
  /// Creates the screen.
  const ProfileScreen({
    required this.name,
    required this.email,
    required this.stats,
    required this.rows,
    this.onEdit,
    this.onOpenSettings,
    super.key,
  });

  /// The display name. `MonetaAvatar` derives the initials from it.
  final String name;

  /// The address under it.
  final String email;

  /// The three figures, from `100:60`.
  final List<ProfileStat> stats;

  /// The menu, from `100:79`–`100:183`.
  final List<ListRow> rows;

  /// Opens `08.02`, from `100:47`'s ghost button.
  final VoidCallback? onEdit;

  /// Opens `08.03`, from the app bar's sliders action (`100:266`).
  final VoidCallback? onOpenSettings;

  /// Content inset, from `100:33`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Avatar size, from `100:35`: `Size=56`.
  static const MonetaAvatarSize avatarSize = MonetaAvatarSize.lg;

  /// Height of a stat tile, from `100:61`: 66.
  static const double statHeight = 66;

  /// Gap between the tiles, from `100:60`'s 112.33 columns in a 353 row: 8.
  static const double statGap = MonetaSpacing.spaceSm;

  /// How many figures the row shows, from `100:60`.
  static const int statCount = 3;

  @override
  Widget build(BuildContext context) {
    assert(
      stats.length == statCount,
      '`100:60` shows exactly $statCount figures, got ${stats.length}',
    );
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Profile',
            actions: [
              // Sliders, not a bell: `100:266` says the large-title action is
              // "swapped to sliders" on this screen.
              (
                icon: MonetaIconName.sliders,
                semanticLabel: 'Settings',
                onPressed: onOpenSettings,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: MonetaSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Identity(
                    name: name,
                    email: email,
                    onEdit: onEdit,
                  ),
                  const SizedBox(height: MonetaSpacing.spaceMd),
                  Row(
                    children: [
                      for (final stat in stats) ...[
                        Expanded(child: _StatCard(stat: stat)),
                        if (stat != stats.last) const SizedBox(width: statGap),
                      ],
                    ],
                  ),
                  const SizedBox(height: MonetaSpacing.spaceMd),
                  const SectionHeader(title: 'Account'),
                  ...rows,
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

/// `100:34`: avatar, names, and a ghost button.
class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.email, this.onEdit});

  final String name;
  final String email;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Row(
      children: [
        MonetaAvatar(
          type: MonetaAvatarType.initials,
          size: ProfileScreen.avatarSize,
          name: name,
        ),
        const SizedBox(width: MonetaSpacing.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.headingH3.copyWith(
                  color: theme.colors.textPrimary,
                ),
              ),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.captionMd.copyWith(
                  color: theme.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: MonetaSpacing.spaceSm),
        MonetaButton(
          label: 'Edit',
          style: MonetaButtonStyle.ghost,
          size: MonetaButtonSize.sm,
          onPressed: onEdit,
        ),
      ],
    );
  }
}

/// `100:61`: a figure over a label, on a raised card.
///
/// Named `_StatCard` rather than `_StatTile` deliberately: the design system's
/// `StatTile` is a different component with a different meaning, and a local
/// class one underscore away from its name invites exactly the reuse
/// annotation `100:275` warns against. See [ProfileStat].
class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return SizedBox(
      height: ProfileScreen.statHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surfaceRaised,
          borderRadius: theme.radii.borderLg,
          border: Border.all(color: theme.colors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MonetaSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.titleMd.copyWith(
                  color: theme.colors.textPrimary,
                ),
              ),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.captionMd.copyWith(
                  color: theme.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
