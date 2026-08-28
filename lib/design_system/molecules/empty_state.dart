import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Empty content placeholder.
///
/// From Figma node `35:166`: `HasAction=true` and `HasAction=false`.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = MonetaIconName.fileText,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Main message.
  final String title;

  /// Supporting explanation.
  final String message;

  /// Decorative glyph.
  final MonetaIconName icon;

  /// Optional action label. Presence selects the `HasAction=true` variant.
  final String? actionLabel;

  /// Called when the optional action is activated.
  final VoidCallback? onAction;

  /// Whether this renders the action variant.
  bool get hasAction => actionLabel != null;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MonetaSpacing.spaceLg,
        vertical: MonetaSpacing.space4xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: theme.radii.borderPill,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MonetaSpacing.spaceBase),
              child: MonetaIcon(icon, color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: MonetaSpacing.spaceBase),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.text.titleMd.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: MonetaSpacing.spaceSm),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.text.bodyMd.copyWith(color: colors.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: MonetaSpacing.spaceXl),
            MonetaButton(
              label: actionLabel!,
              style: MonetaButtonStyle.secondary,
              leadingIcon: MonetaIconName.plus,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
