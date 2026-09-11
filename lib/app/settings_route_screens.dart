/// Wires 08.03 Settings to the app's state.
///
/// The screen is presentational, so the groups — and the demo switch's
/// behaviour — are assembled here. Same split as the Insights and Home routes,
/// and the only one `check_architecture.dart` allows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/category_usage_providers.dart';
import 'package:moneta/app/demo/demo_mode_controller.dart';
import 'package:moneta/app/notification_preferences.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:moneta/features/settings/presentation/edit_profile_screen.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';
import 'package:moneta/features/settings/presentation/manage_categories_screen.dart';
import 'package:moneta/features/settings/presentation/notification_settings_screen.dart';
import 'package:moneta/features/settings/presentation/premium_screen.dart';
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

  /// `08.02` Edit profile.
  static const String editProfile = '/profile/edit';

  /// `08.10` Premium.
  static const String premium = '/profile/premium';

  /// `08.08` Manage categories.
  static const String categories = '/profile/settings/categories';
}

/// `08.01`, wired.
class ProfileRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const ProfileRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoActive = ref.watch(demoModeProvider);
    // The stored profile, which `08.02` writes. Until one is saved the screen
    // says so rather than showing a name nobody entered — the placeholders
    // this screen shipped with are gone.
    final profile = ref.watch(profileProvider).value;

    return ProfileScreen(
      name: profile?.name ?? 'Add your name',
      email: profile?.email ?? '',
      stats: demoActive ? _demoStats : _emptyStats,
      onEdit: () => context.push(SettingsRoutes.editProfile),
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
        ListRow(
          title: 'Premium',
          subtitle: 'Unlimited goals, export, widgets',
          leadingIcon: MonetaIconName.award,
          accessory: ListRowAccessory.badge,
          badgeLabel: 'TRY FREE',
          onTap: () => context.push(SettingsRoutes.premium),
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
        SettingsGroup(
          title: 'Account',
          rows: [
            SettingsRow.push(
              title: 'Edit profile',
              icon: MonetaIconName.user,
              onTap: () => context.push(SettingsRoutes.editProfile),
            ),
            SettingsRow.push(
              title: 'Categories',
              subtitle: 'How much each one is used',
              icon: MonetaIconName.list,
              onTap: () => context.push(SettingsRoutes.categories),
            ),
            SettingsRow.value(
              title: 'Main currency',
              // The stored one, not a hard-coded `VND`. `08.02` writes it.
              value:
                  (ref.watch(profileProvider).value?.currency ?? Currency.vnd)
                      .code,
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

/// `08.02`, wired.
///
/// Holds the last failure so the screen can render it: a validation failure
/// lands on the email field and a storage failure above the footer, and in
/// both cases the typed values stay on screen.
class EditProfileRouteScreen extends ConsumerStatefulWidget {
  /// Creates the route screen.
  const EditProfileRouteScreen({super.key});

  @override
  ConsumerState<EditProfileRouteScreen> createState() =>
      _EditProfileRouteScreenState();
}

class _EditProfileRouteScreenState
    extends ConsumerState<EditProfileRouteScreen> {
  AppFailure? _failure;

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(profileProvider).value;

    return EditProfileScreen(
      profile: stored ?? const Profile(name: ''),
      failure: _failure,
      onBack: context.pop,
      onSave: (edited) async {
        final failure = await saveProfile(ref, edited);
        if (!mounted) return;
        setState(() => _failure = failure);
        // Only a successful save leaves the screen. A failed one stays, with
        // the reason and the typed values both still there.
        if (failure == null && context.mounted) context.pop();
      },
      // No currency picker: `08.07` is the screen that chooses one and it is
      // not built, so the control opens nothing. `onPickCurrency` defaults to
      // null, which is that.
    );
  }
}

/// `08.10`, wired.
///
/// The purchase attempt is reported and nothing else happens: there is no
/// purchase plumbing in this app, and the footer already says so. This is the
/// part that makes the button honest rather than inert.
class PremiumRouteScreen extends StatelessWidget {
  /// Creates the route screen.
  const PremiumRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return PremiumScreen(
      onClose: context.pop,
      onPurchaseAttempt: (plan) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            backgroundColor: theme.colors.surfaceRaised,
            content: Text(
              'Purchases are not available in this build.',
              style: theme.text.bodyMd.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `08.08`, wired.
///
/// The counts come from the ledger through `categoryUsageProvider`; the screen
/// itself is pure, which is what lets `features/settings` show transaction data
/// without importing `features/transactions`.
class ManageCategoriesRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const ManageCategoriesRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(categoryUsageProvider);

    return usage.when(
      data: (rows) => ManageCategoriesScreen(
        usage: rows,
        direction: ref.watch(categoryFilterProvider),
        onDirectionChanged: (direction) =>
            ref.read(categoryFilterProvider.notifier).direction = direction,
        onBack: context.pop,
      ),
      loading: () => const _CategoriesPlaceholder(message: 'Counting…'),
      // "We could not look" is not "there is nothing here".
      error: (error, _) =>
          const _CategoriesPlaceholder(message: 'Could not read the ledger'),
    );
  }
}

class _CategoriesPlaceholder extends StatelessWidget {
  const _CategoriesPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return ColoredBox(
      color: theme.colors.canvas,
      child: Center(
        child: Text(
          message,
          style: theme.text.bodyMd.copyWith(color: theme.colors.textSecondary),
        ),
      ),
    );
  }
}
