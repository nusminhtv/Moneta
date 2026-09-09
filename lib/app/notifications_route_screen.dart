import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/notification_providers.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/notifications/presentation/notifications_screen.dart';

/// Where the notification centre lives.
abstract final class NotificationRoutes {
  /// The notification centre, reached from Home's app bar.
  static const String path = '/notifications';
}

/// Hosts [NotificationsScreen] and supplies it with data.
///
/// The screen takes a list and a clock and nothing else, so it can be tested
/// without a database; everything that knows where notifications come from
/// lives in [notificationsProvider].
class NotificationsRouteScreen extends ConsumerWidget {
  /// Creates the route wrapper.
  const NotificationsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final now = ref.watch(clockProvider).nowUtc();

    return NotificationsScreen(
      // An empty list is the legitimate empty state (`57:840`), so a failed or
      // pending read renders as empty rather than as an error box. There is
      // nothing durable behind these; a retry is the next frame.
      notifications: notifications.value ?? const [],
      now: now,
      onBack: () =>
          context.go(DestinationRoutes.paths[MonetaDestination.home]!),
      onOpen: (notification) => _open(context, notification),
    );
  }

  void _open(BuildContext context, HomeNotification notification) {
    switch (notification.kind) {
      case NotificationKind.budgetOverLimit:
        final id = notification.targetId;
        if (id != null) context.go(BudgetRoutes.detailFor(id));
      case NotificationKind.incomeReceived:
        context.go(DestinationRoutes.paths[MonetaDestination.transactions]!);
      // Informational, so the screen never offers a tap and this is
      // unreachable. Named rather than defaulted so that adding an actionable
      // kind fails to compile until its destination is decided.
      case NotificationKind.budgetPeriodEnding:
        break;
    }
  }
}
