/// Wires 08.03 Settings to the app's state.
///
/// The screen is presentational, so the groups — and the demo switch's
/// behaviour — are assembled here. Same split as the Insights and Home routes,
/// and the only one `check_architecture.dart` allows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/demo/demo_mode_controller.dart';
import 'package:moneta/app/notification_preferences.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';
import 'package:moneta/features/settings/presentation/notification_settings_screen.dart';
import 'package:moneta/features/settings/presentation/profile_screen.dart';
import 'package:moneta/features/settings/presentation/settings_screen.dart';

/// Where the profile screens live.
class SettingsRoutes {
  const SettingsRoutes._();

  /// `08.01` Profile — the tab's root.
  static const String profile = '/profile';

  /// `08.03` Settings — the list everything hangs off.
  static const String list = '/profile/settings';

  /// `08.06` Notifications.
  static const String notifications = '/profile/settings/notifications';

  /// `08.11` Help & FAQ.
  static const String help = '/profile/settings/help';
}

/// `08.01`, wired.
class ProfileRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const ProfileRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoActive = ref.watch(demoModeProvider);

    return ProfileScreen(
      // Placeholders, and named as such: there is no accounts or identity
      // feature, so `08.01`'s identity block has nothing real to show. The
      // demo ledger at least makes the figures honest about themselves.
      name: demoActive ? 'Minh Tran' : 'Moneta user',
      email: demoActive ? 'minh.tran@example.com' : 'Not signed in',
      stats: demoActive ? _demoStats : _emptyStats,
      onOpenSettings: () => context.push(SettingsRoutes.list),
      rows: [
        ListRow(
          title: 'Settings',
          leadingIcon: MonetaIconName.sliders,
          accessory: ListRowAccessory.chevron,
          onTap: () => context.push(SettingsRoutes.list),
        ),
        // `100:269`: "Premium shows a TRY FREE badge; once subscribed the row's
        // Trailing becomes Value with the renewal date." Unsubscribed is the
        // only state this build has, so it is the badge.
        const ListRow(
          title: 'Premium',
          subtitle: 'Unlimited goals, export, widgets',
          leadingIcon: MonetaIconName.award,
          accessory: ListRowAccessory.badge,
          badgeLabel: 'TRY FREE',
        ),
        ListRow(
          title: 'Help & FAQ',
          subtitle: 'Answers, and a way to reach a person',
          leadingIcon: MonetaIconName.helpCircle,
          accessory: ListRowAccessory.chevron,
          onTap: () => context.push(SettingsRoutes.help),
        ),
        // The only destructive row, and the only label off text/primary.
        const ListRow(
          title: 'Sign out',
          leadingIcon: MonetaIconName.lock,
          accessory: ListRowAccessory.none,
          destructive: true,
        ),
      ],
    );
  }
}

/// `100:272`'s own figures: *"214 days, 1,842 transactions, 4 active goals."*
///
/// Reproduced as authored while demo mode is on. Goals do not exist as a
/// feature, so that third figure is the annotation's number rather than a
/// count of anything — recorded here rather than silently invented.
const List<ProfileStat> _demoStats = [
  ProfileStat(value: '214', label: 'Days tracked'),
  ProfileStat(value: '1,842', label: 'Transactions'),
  ProfileStat(value: '4', label: 'Active goals'),
];

const List<ProfileStat> _emptyStats = [
  ProfileStat(value: '0', label: 'Days tracked'),
  ProfileStat(value: '0', label: 'Transactions'),
  ProfileStat(value: '0', label: 'Active goals'),
];

/// 08.03, wired.
class SettingsRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const SettingsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoActive = ref.watch(demoModeProvider);

    return SettingsScreen(
      onBack: () => context.pop(),
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
        SettingsGroup(
          title: 'About',
          rows: [
            const SettingsRow.value(
              title: 'Version',
              value: '0.1.0',
              icon: MonetaIconName.info,
            ),
            SettingsRow.push(
              title: 'Help & FAQ',
              icon: MonetaIconName.helpCircle,
              onTap: () => context.push(SettingsRoutes.help),
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

/// `08.06`, wired.
class NotificationSettingsRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const NotificationSettingsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      NotificationSettingsScreen(
        preferences: ref.watch(notificationPreferencesProvider),
        onBack: () => context.pop(),
        onChanged: (next) async {
          final result = await ref
              .read(notificationPreferencesProvider.notifier)
              .update(next);
          if (!context.mounted) return;
          result.when(
            ok: (_) {},
            err: (failure) => ScaffoldMessenger.maybeOf(
              context,
            )?.showSnackBar(SnackBar(content: Text(failure.message))),
          );
        },
      );
}

/// `08.11`, wired.
///
/// Stateless and provider-free: the questions are constants and the search is
/// the screen's own state, so there is nothing for a provider to hold.
class HelpRouteScreen extends StatelessWidget {
  /// Creates the route screen.
  const HelpRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      onBack: context.pop,
      // No mail client is opened: `url_launcher` is not a dependency, and a
      // button that silently fails is worse than one that says what it cannot
      // do. The address is shown instead, which is a thing the user can act on.
      onContactSupport: () => _showSupportAddress(context),
    );
  }

  void _showSupportAddress(BuildContext context) {
    final theme = context.moneta;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        backgroundColor: theme.colors.surfaceRaised,
        content: Text(
          'Email support@moneta.app',
          style: theme.text.bodyMd.copyWith(color: theme.colors.textPrimary),
        ),
      ),
    );
  }
}
