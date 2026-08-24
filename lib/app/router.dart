import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:moneta/features/transactions/presentation/transactions_screen.dart';

/// Builds the application's routes.
///
/// The four destinations live inside a shell so the bottom navigation persists
/// across them and its active tab is derived from the current location rather
/// than tracked separately.
GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MonetaShell(
          onAdd: () => showAddTransactionSheet(context),
          child: child,
        ),
        routes: [
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.home]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Moneta'),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.transactions]!,
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.insights]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Insights'),
          ),
          GoRoute(
            path: DestinationRoutes.paths[MonetaDestination.profile]!,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),
      // Outside the shell: the gallery is a development surface, not a
      // destination, and showing it with a nav bar would imply otherwise.
      GoRoute(
        path: GalleryScreen.routePath,
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
}

/// Opens the add-transaction sheet.
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const AddTransactionSheet(),
  );
}
