import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_providers.dart';

/// The brand splash, Figma `71:2`.
///
/// Hands over on its own; the design offers nothing to tap. It is also where the
/// first-run decision is made — a splash exists to cover startup work, and
/// reading one flag is exactly that. Doing it in a router redirect instead would
/// race with the write that finishes the introduction.
class SplashScreen extends ConsumerStatefulWidget {
  /// Creates the splash.
  const SplashScreen({
    required this.onDecided,
    this.minimumDuration = const Duration(milliseconds: 900),
    super.key,
  });

  /// Called with whether the introduction should be shown.
  ///
  /// Fires once, after both the flag has resolved and [minimumDuration] has
  /// elapsed — so a fast read does not make the splash flash.
  final void Function({required bool showOnboarding}) onDecided;

  /// Shortest time the splash stays on screen.
  final Duration minimumDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    unawaited(_decide());
  }

  Future<void> _decide() async {
    // Both must complete: the read, and the minimum display time.
    final results = await Future.wait([
      ref.read(shouldShowOnboardingProvider.future),
      Future<bool>.delayed(widget.minimumDuration, () => true),
    ]);
    if (!mounted || _decided) return;
    _decided = true;
    widget.onDecided(showOnboarding: results.first);
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
