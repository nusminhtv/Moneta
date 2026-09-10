/// The startup gate: hydrates the demo flag, then shows the splash.
///
/// `SplashScreen` lives in `features/onboarding`, which may not import
/// `lib/app/demo`, so the hydration happens here — the composition root — and
/// the splash is left doing only what it did before.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/app/demo/demo_mode_controller.dart';
import 'package:moneta/features/onboarding/presentation/splash_screen.dart';

/// Wraps the splash so demo mode survives a restart.
///
/// Without this the stored `demoMode` preference was written and never read
/// back at launch: turning the switch on, closing the app and reopening it
/// landed on the real ledger with the switch showing off. The preference was
/// always durable; nothing asked for it.
class StartupRouteScreen extends ConsumerStatefulWidget {
  /// Creates the gate.
  const StartupRouteScreen({required this.onDecided, super.key});

  /// Called with whether the introduction should be shown.
  final void Function({required bool showOnboarding}) onDecided;

  @override
  ConsumerState<StartupRouteScreen> createState() => _StartupRouteScreenState();
}

class _StartupRouteScreenState extends ConsumerState<StartupRouteScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    // Deliberately not surfaced here. A failure to read the flag means demo
    // mode stays off, which is the safe direction — the real ledger — and the
    // splash must not become a screen that can fail to leave. The settings
    // list surfaces the failure when it reads the same value.
    await ref.read(demoModeControllerProvider).hydrate();
  }

  @override
  Widget build(BuildContext context) =>
      SplashScreen(onDecided: widget.onDecided);
}
