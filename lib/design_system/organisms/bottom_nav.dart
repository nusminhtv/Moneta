import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The four navigation destinations.
///
/// The centre add action is **not** a destination — Figma is explicit that the
/// FAB "is not a fifth tab", and activating it must not change which destination
/// is active.
enum MonetaDestination {
  /// Home overview.
  home('Home', MonetaIconName.home),

  /// Transaction list.
  transactions('Transactions', MonetaIconName.list),

  /// Charts and analysis.
  insights('Insights', MonetaIconName.pieChart),

  /// Settings and account.
  profile('Profile', MonetaIconName.user);

  const MonetaDestination(this.label, this.icon);

  /// Tab label.
  final String label;

  /// Tab glyph.
  final MonetaIconName icon;
}

/// Bottom navigation with a floating centre action.
///
/// From Figma node `39:243`. The FAB overhangs the bar by
/// [MonetaLayout.fabOverlap], so this widget must be placed somewhere that does
/// not clip its children — a `Stack` in the screen scaffold rather than inside a
/// `ClipRect`.
class MonetaBottomNav extends StatelessWidget {
  /// Creates the bottom navigation bar.
  const MonetaBottomNav({
    required this.active,
    this.onSelect,
    this.onAdd,
    super.key,
  });

  /// The destination currently on screen.
  ///
  /// Figma: *"Getting the active tab wrong for the screen is a real defect, not
  /// a nitpick."*
  final MonetaDestination active;

  /// Called with the destination the user picked. The bar reports; it does not
  /// navigate.
  final ValueChanged<MonetaDestination>? onSelect;

  /// Called when the centre add action is used.
  final VoidCallback? onAdd;

  /// Key on the floating action button.
  static const Key fabKey = Key('MonetaBottomNav.fab');

  /// Key on a destination's tab, by destination.
  static Key tabKey(MonetaDestination destination) =>
      Key('MonetaBottomNav.tab.${destination.name}');

  /// Icon size inside a tab. 23, not 24 — as authored in Figma.
  static const double tabIconSize = 23;

  /// Icon size inside the floating action button.
  static const double fabIconSize = 26;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      // The FAB deliberately overflows the top edge.
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
                child: Row(
                  children: [
                    _Tab(
                      destination: MonetaDestination.home,
                      active: active,
                      onSelect: onSelect,
                    ),
                    _Tab(
                      destination: MonetaDestination.transactions,
                      active: active,
                      onSelect: onSelect,
                    ),
                    // Space the FAB floats over. Not a tab.
                    const SizedBox(width: MonetaLayout.fabSlotWidth),
                    _Tab(
                      destination: MonetaDestination.insights,
                      active: active,
                      onSelect: onSelect,
                    ),
                    _Tab(
                      destination: MonetaDestination.profile,
                      active: active,
                      onSelect: onSelect,
                    ),
                  ],
                ),
              ),
              // The bar's background extends through the device inset; the tab
              // row above it does not.
              SizedBox(height: bottomInset),
            ],
          ),
        ),
        Positioned(
          top: -MonetaLayout.fabOverlap,
          child: GestureDetector(
            key: fabKey,
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: SizedBox.square(
              dimension: MonetaLayout.fabSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.brand,
                  shape: BoxShape.circle,
                  boxShadow: theme.elevation.brandGlow,
                ),
                child: Center(
                  child: MonetaIcon(
                    MonetaIconName.plus,
                    size: fabIconSize,
                    color: colors.textOnBrand,
                    semanticLabel: 'Add transaction',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.active,
    required this.onSelect,
  });

  final MonetaDestination destination;
  final MonetaDestination active;
  final ValueChanged<MonetaDestination>? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final isActive = destination == active;
    final color = isActive
        ? theme.colors.brandOnSurface
        : theme.colors.textTertiary;

    // Semantics wraps the gesture detector, not the other way round: nested the
    // other way it becomes a sibling node and the selected flag never reaches
    // the tab's own node, so assistive tech cannot tell which tab is current.
    return Expanded(
      child: Semantics(
        container: true,
        selected: isActive,
        button: true,
        child: GestureDetector(
          key: MonetaBottomNav.tabKey(destination),
          onTap: onSelect == null ? null : () => onSelect!(destination),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonetaIcon(
                destination.icon,
                size: MonetaBottomNav.tabIconSize,
                color: color,
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.labelSm.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
