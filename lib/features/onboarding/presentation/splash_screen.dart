import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The brand splash, Figma `71:2`.
///
/// Hands over on its own after [duration]; the design offers nothing to tap.
class SplashScreen extends StatefulWidget {
  /// Creates the splash.
  const SplashScreen({
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1200),
    super.key,
  });

  /// Called once [duration] has elapsed.
  final VoidCallback onComplete;

  /// How long the splash shows.
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.delayed(widget.duration, () {
        if (mounted) widget.onComplete();
      }),
    );
  }

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
            const SizedBox(height: MonetaSpacing.spaceBase),
            Text(
              'Personal finance, on your device',
              style: theme.text.bodyLg.copyWith(
                color: theme.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
