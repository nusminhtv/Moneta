/// Wires 08.03 Settings to the app's state.
///
/// The screen is presentational, so the groups — and the demo switch's
/// behaviour — are assembled here. Same split as the Insights and Home routes,
/// and the only one `check_architecture.dart` allows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/app/demo/demo_mode_controller.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/features/settings/presentation/settings_screen.dart';

/// Where Settings lives.
class SettingsRoutes {
  const SettingsRoutes._();

  /// The settings list, `08.03`.
  static const String list = '/profile';
}

/// 08.03, wired.
class SettingsRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const SettingsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoActive = ref.watch(demoModeProvider);

    return SettingsScreen(
      groups: [
        const SettingsGroup(
          title: 'Account',
          rows: [
            // Present and unavailable: `08.02` is not built. Hiding it would
            // make the list look complete; letting it navigate would land on a
            // blank screen.
            SettingsRow.push(
              title: 'Edit profile',
              subtitle: 'Not built yet',
              icon: MonetaIconName.user,
              onTap: null,
              available: false,
            ),
            SettingsRow.value(
              title: 'Main currency',
              value: 'VND',
              icon: MonetaIconName.creditCard,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Data',
          rows: [
            SettingsRow.toggle(
              title: 'Demo data',
              subtitle: demoActive
                  ? 'Showing generated data. Your real ledger is untouched.'
                  : 'Fill the app with 15 months of generated data to try it.',
              icon: MonetaIconName.zap,
              toggled: demoActive,
              onToggle: (wanted) => _setDemoMode(context, ref, active: wanted),
            ),
            if (demoActive)
              SettingsRow.push(
                title: 'Reset demo data',
                subtitle: 'Regenerate the demo ledger from scratch',
                icon: MonetaIconName.repeat,
                onTap: () => _confirmReset(context, ref),
              ),
          ],
        ),
        const SettingsGroup(
          title: 'Security',
          rows: [
            SettingsRow.push(
              title: 'Security',
              subtitle: 'Not built yet',
              icon: MonetaIconName.lock,
              onTap: null,
              available: false,
            ),
          ],
        ),
        const SettingsGroup(
          title: 'About',
          rows: [
            SettingsRow.value(
              title: 'Version',
              value: '0.1.0',
              icon: MonetaIconName.info,
            ),
            SettingsRow.push(
              title: 'Help & FAQ',
              subtitle: 'Not built yet',
              icon: MonetaIconName.helpCircle,
              onTap: null,
              available: false,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setDemoMode(
    BuildContext context,
    WidgetRef ref, {
    required bool active,
  }) async {
    final result = await ref
        .read(demoModeControllerProvider)
        .setDemoMode(active: active);

    if (!context.mounted) return;
    // Surfaced, not swallowed: a toggle that silently fails to move is how a
    // storage failure looks like a UI bug.
    result.when(
      ok: (_) {},
      err: (failure) => _tell(context, failure.message),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'The demo ledger is deleted and generated again. Your real data is '
          'not touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    // Declining leaves the demo ledger exactly as it was.
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(demoModeControllerProvider).resetDemoLedger();
    if (!context.mounted) return;
    result.when(
      ok: (_) => _tell(context, 'Demo data regenerated.'),
      err: (failure) => _tell(context, failure.message),
    );
  }

  void _tell(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }
}
