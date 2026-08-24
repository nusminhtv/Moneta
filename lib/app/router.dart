import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/gallery/gallery_screen.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// The application's routes.
///
/// Only the gallery exists so far: product screens arrive with the changes that
/// introduce them, and Figma contains no screen frames to build from yet.
GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _Placeholder(),
      ),
      GoRoute(
        path: GalleryScreen.routePath,
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Scaffold(
      backgroundColor: theme.colors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Moneta',
              style: theme.text.headingH1.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
            SizedBox(height: theme.spacing.xl),
            TextButton(
              onPressed: () => context.go(GalleryScreen.routePath),
              child: Text(
                'Design system gallery',
                style: theme.text.labelMd.copyWith(
                  color: theme.colors.brandOnSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
