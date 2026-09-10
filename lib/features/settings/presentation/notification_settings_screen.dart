import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/features/settings/presentation/settings_screen.dart';

/// Which pushes the user has left switched on.
///
/// A value type rather than four booleans threaded through the widget tree, so
/// "what is on" is one thing that can be compared, defaulted and stored.
@immutable
class NotificationPreferences extends Equatable {
  /// Creates a set of preferences.
  const NotificationPreferences({
    this.budgetNearLimit = false,
    this.budgetExceeded = true,
    this.periodEnding = true,
    this.income = true,
  });

  /// Warn at 80% of a budget — `101:651`.
  ///
  /// **Off** by default, which is a departure from the frame's on. Nothing in
  /// this app derives an 80% warning yet, so the switch currently silences
  /// nothing; shipping it on would claim a notification the app cannot send.
  ///
  /// It is also what keeps the screen's defaults *mixed*, which `101:856` asks
  /// for: *"a settings screen where every switch is on tells you nothing about
  /// how the off state reads."* The frame gets its off state from a goals
  /// feature this app does not have, so the honest off switch is the one with
  /// nothing behind it.
  final bool budgetNearLimit;

  /// A budget has gone over — `101:675`, on by default.
  final bool budgetExceeded;

  /// A budget period is ending — `101:702`, on by default.
  final bool periodEnding;

  /// Money came in — `57:688`'s notification, on by default.
  ///
  /// On, because it already shipped: `home-overview` derives income
  /// notifications and the notification centre shows them. An off default here
  /// would have silently removed a working feature behind a new switch — which
  /// is exactly what the first version of this screen did, and two existing
  /// tests failed and caught it.
  final bool income;

  /// This set with one flag changed.
  NotificationPreferences copyWith({
    bool? budgetNearLimit,
    bool? budgetExceeded,
    bool? periodEnding,
    bool? income,
  }) => NotificationPreferences(
    budgetNearLimit: budgetNearLimit ?? this.budgetNearLimit,
    budgetExceeded: budgetExceeded ?? this.budgetExceeded,
    periodEnding: periodEnding ?? this.periodEnding,
    income: income ?? this.income,
  );

  @override
  List<Object?> get props => [
    budgetNearLimit,
    budgetExceeded,
    periodEnding,
    income,
  ];
}

/// 08.06 — every push the app can send, grouped by what it is about.
///
/// From Figma node `101:618`. Annotation `101:850`: *"Every push the app can
/// send, grouped by what it is about, so a user can silence one category
/// without silencing everything."*
///
/// Built on [SettingsScreen]'s groups, because that is what it is: four
/// labelled groups of `ListRow`s. Its own screen rather than another set of
/// groups on `08.03` because `101:618` is its own route with its own back bar.
class NotificationSettingsScreen extends StatelessWidget {
  /// Creates the screen.
  const NotificationSettingsScreen({
    required this.preferences,
    required this.onChanged,
    this.quietHours = defaultQuietHours,
    this.weeklySummary = defaultWeeklySummary,
    this.onBack,
    super.key,
  });

  /// What is currently on.
  final NotificationPreferences preferences;

  /// Called with the whole set whenever one switch moves.
  final ValueChanged<NotificationPreferences> onChanged;

  /// `101:816`'s value, and the app's default.
  final String quietHours;

  /// `101:755`'s value, and the app's default.
  final String weeklySummary;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// From `101:859`: *"22:00 – 07:00 quiet hours and the Sunday 20:00 summary
  /// are the app's defaults."*
  static const String defaultQuietHours = '22:00 – 07:00';

  /// See [defaultQuietHours].
  static const String defaultWeeklySummary = 'Sunday 20:00';

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: 'Notifications',
      onBack: onBack,
      groups: [
        SettingsGroup(
          title: 'Budgets',
          rows: [
            SettingsRow.toggle(
              title: '80% of a budget used',
              subtitle: 'One warning per budget per month',
              icon: MonetaIconName.pieChart,
              toggled: preferences.budgetNearLimit,
              onToggle: (on) =>
                  onChanged(preferences.copyWith(budgetNearLimit: on)),
            ),
            SettingsRow.toggle(
              title: 'Budget exceeded',
              icon: MonetaIconName.alertTriangle,
              toggled: preferences.budgetExceeded,
              onToggle: (on) =>
                  onChanged(preferences.copyWith(budgetExceeded: on)),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Bills & goals',
          rows: [
            SettingsRow.toggle(
              title: 'Budget period ending',
              icon: MonetaIconName.calendar,
              toggled: preferences.periodEnding,
              onToggle: (on) =>
                  onChanged(preferences.copyWith(periodEnding: on)),
            ),
            SettingsRow.toggle(
              title: 'Money received',
              subtitle: 'When income lands in your wallet',
              icon: MonetaIconName.target,
              toggled: preferences.income,
              onToggle: (on) => onChanged(preferences.copyWith(income: on)),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Summaries',
          rows: [
            // **Value, not Toggle.** `101:862`: *"Two rows here are Value, not
            // Toggle, because they carry a time the user can change. A time is
            // not a boolean. This is the mapping mistake from 08.03 seen from
            // the other side."*
            SettingsRow.value(
              title: 'Weekly summary',
              value: weeklySummary,
              icon: MonetaIconName.fileText,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Quiet hours',
          rows: [
            SettingsRow.value(
              title: 'Do not disturb',
              subtitle: 'No push during these hours',
              value: quietHours,
              icon: MonetaIconName.eyeOff,
            ),
          ],
        ),
      ],
    );
  }
}
