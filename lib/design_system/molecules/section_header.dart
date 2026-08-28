import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// A compact heading for a list or dashboard section.
///
/// From Figma node `55:107`.
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Section title.
  final String title;

  /// Optional trailing action label.
  final String? actionLabel;

  /// Called when the trailing action is activated.
  final VoidCallback? onAction;

  /// Key on the optional action.
  static const Key actionKey = Key('SectionHeader.action');

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MonetaSpacing.spaceBase,
        vertical: MonetaSpacing.spaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.text.titleMd.copyWith(color: colors.textPrimary),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: MonetaSpacing.spaceMd),
            Flexible(
              child: GestureDetector(
                key: actionKey,
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MonetaSpacing.spaceXs,
                  ),
                  child: Text(
                    actionLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: theme.text.labelMd.copyWith(color: colors.brand),
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
