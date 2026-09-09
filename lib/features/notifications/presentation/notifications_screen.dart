import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';

/// The notification centre, from Figma node `57:622`.
///
/// **The bottom navigation stays on Home.** Annotation `57:830` is blunt about
/// it — this is a Home sub-screen, and *"a wrong active tab here is a real
/// defect, not a nitpick"*. The shell owns the bar and unknown locations fall
/// back to Home, which is the same mechanism that keeps Budgets lit correctly.
///
/// The app bar is `TitleBack`, not `LargeTitle`: this screen is reached *from*
/// Home's app bar, so it needs a way back.
class NotificationsScreen extends StatelessWidget {
  /// Creates the notification centre.
  const NotificationsScreen({
    required this.notifications,
    required this.now,
    this.onBack,
    this.onOpen,
    super.key,
  });

  /// What to show, newest first. Grouping happens here.
  final List<HomeNotification> notifications;

  /// Now, in UTC, from the injected clock.
  final DateTime now;

  /// Called by the app bar's back control.
  final VoidCallback? onBack;

  /// Called when an actionable notification is tapped.
  final void Function(HomeNotification notification)? onOpen;

  /// Splits [notifications] into today's and everything older.
  ///
  /// By **local** calendar day, not by elapsed hours. A notification at 23:30
  /// local is stored as 16:30 UTC the same day, and grouping on the UTC date
  /// would file it under the wrong heading. The gate pins
  /// `TZ=Asia/Ho_Chi_Minh`, so a test of this can actually fail.
  ///
  /// This deliberately disagrees with the "… ago" tail in a row's subtitle:
  /// something at 23:00 last night groups under `Earlier` while reading
  /// "13 hours ago". Grouping answers "which day", the tail answers "how long" —
  /// two different questions, and forcing them to agree would make one of them
  /// wrong.
  static ({List<HomeNotification> today, List<HomeNotification> earlier})
  groupByRecency(List<HomeNotification> notifications, DateTime now) {
    final localNow = now.toLocal();
    final startOfToday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    );

    final today = <HomeNotification>[];
    final earlier = <HomeNotification>[];
    for (final notification in notifications) {
      final local = notification.occurredAt.toLocal();
      if (local.isBefore(startOfToday)) {
        earlier.add(notification);
      } else {
        today.add(notification);
      }
    }
    return (today: today, earlier: earlier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final groups = groupByRecency(notifications, now);

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(
            title: 'Notifications',
            variant: MonetaAppBarVariant.titleBack,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: [
                // A heading appears only when its group has rows. An empty
                // "Today" above nothing reads as a failed load.
                ..._group('Today', groups.today),
                ..._group('Earlier', groups.earlier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _group(String title, List<HomeNotification> entries) {
    if (entries.isEmpty) return const [];
    return [
      // `showAction=false` on both headings, per annotation `57:830`.
      SectionHeader(title: title),
      for (final entry in entries)
        _NotificationRow(entry: entry, onOpen: onOpen),
    ];
  }
}

/// One notification row, from `57:662` and its siblings.
///
/// The accessory is **derived** from the notification, never chosen here:
/// annotation `57:830` says *"actionable notifications get a chevron;
/// informational ones do not"*, and `HomeNotification.isActionable` comes from
/// the kind. A chevron over nothing is therefore not expressible, which is the
/// same rule the first-run checklist follows.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.entry, this.onOpen});

  final HomeNotification entry;
  final void Function(HomeNotification notification)? onOpen;

  @override
  Widget build(BuildContext context) {
    final tappable = entry.isActionable && onOpen != null;
    return ListRow(
      key: ValueKey(entry.id),
      title: entry.title,
      subtitle: entry.detail,
      leadingIcon: entry.icon,
      accessory: entry.isActionable
          ? ListRowAccessory.chevron
          : ListRowAccessory.none,
      onTap: tappable ? () => onOpen!(entry) : null,
    );
  }
}
