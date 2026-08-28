import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Tone variants for [MonetaBanner].
///
/// From Figma node `42:329`: Warning, Danger, Info and Success.
enum BannerTone {
  /// Cautionary message.
  warning,

  /// Problem or destructive consequence.
  danger,

  /// Neutral information.
  info,

  /// Successful outcome.
  success,
}

/// Inline notice banner.
///
/// From Figma node `42:329`.
class MonetaBanner extends StatelessWidget {
  /// Creates a banner.
  const MonetaBanner({
    required this.tone,
    required this.title,
    required this.message,
    this.onTap,
    super.key,
  });

  /// Visual and semantic tone.
  final BannerTone tone;

  /// Primary message.
  final String title;

  /// Supporting message.
  final String message;

  /// Optional tap handler.
  final VoidCallback? onTap;

  MonetaIconName get _icon => switch (tone) {
    BannerTone.warning => MonetaIconName.alertTriangle,
    BannerTone.danger => MonetaIconName.x,
    BannerTone.info => MonetaIconName.info,
    BannerTone.success => MonetaIconName.check,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final scheme = switch (tone) {
      BannerTone.warning => (colors.warning, colors.warningSubtle),
      BannerTone.danger => (colors.expense, colors.expenseSubtle),
      BannerTone.info => (colors.info, colors.infoSubtle),
      BannerTone.success => (colors.income, colors.incomeSubtle),
    };
    final (accent, background) = scheme;

    return Semantics(
      container: true,
      button: onTap != null,
      label: '${tone.name}: $title. $message',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: theme.radii.borderMd,
            border: Border.all(color: accent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MonetaSpacing.spaceBase),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonetaIcon(_icon, color: accent),
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
                        softWrap: false,
                        style: theme.text.titleMd.copyWith(color: accent),
                      ),
                      const SizedBox(height: MonetaSpacing.spaceXs),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.bodyMd.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
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
