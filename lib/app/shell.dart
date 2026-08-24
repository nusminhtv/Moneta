import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Maps a destination to the route it owns, and back.
///
/// One table, in one direction each way. Figma is explicit that "getting the
/// active tab wrong for the screen is a real defect, not a nitpick", and two
/// separate mappings are how that goes wrong.
abstract final class DestinationRoutes {
  /// Route path for each destination.
  static const Map<MonetaDestination, String> paths = {
    MonetaDestination.home: '/',
    MonetaDestination.transactions: '/transactions',
    MonetaDestination.insights: '/insights',
    MonetaDestination.profile: '/profile',
  };

  /// The destination a location belongs to.
  ///
  /// Falls back to [MonetaDestination.home] only for the root; an unknown
  /// location keeps whichever destination its prefix matches, so a nested route
  /// under `/transactions/…` still highlights Transactions.
  static MonetaDestination of(String location) {
    for (final entry in paths.entries) {
      if (entry.key == MonetaDestination.home) continue;
      if (location == entry.value || location.startsWith('${entry.value}/')) {
        return entry.key;
      }
    }
    return MonetaDestination.home;
  }
}

/// The persistent frame: a screen plus the bottom navigation.
class MonetaShell extends StatelessWidget {
  /// Creates the shell.
  const MonetaShell({required this.child, required this.onAdd, super.key});

  /// The current screen.
  final Widget child;

  /// Called when the centre add action is used.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: theme.colors.canvas,
      body: child,
      // The FAB overhangs the bar, so the nav must sit somewhere unclipped.
      bottomNavigationBar: MonetaBottomNav(
        active: DestinationRoutes.of(location),
        onSelect: (destination) =>
            context.go(DestinationRoutes.paths[destination]!),
        onAdd: onAdd,
      ),
    );
  }
}

/// A destination that exists as a route but has no screen yet.
///
/// Explicit rather than a blank page: Insights and Profile are named non-goals
/// of this change, and a placeholder that says so is more honest than one that
/// looks broken.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder.
  const PlaceholderScreen({required this.title, super.key});

  /// Destination name.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.text.headingH1.copyWith(
              color: theme.colors.textPrimary,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          Text(
            'Not built yet.',
            style: theme.text.bodyMd.copyWith(color: theme.colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
