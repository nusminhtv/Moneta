/// Derives the notification centre from what the app already knows.
///
/// This lives in `lib/app` for the same reason `home_providers.dart` does:
/// `features/notifications` may not import `features/budgets` or
/// `features/transactions`, and the composition root is the only layer allowed
/// to see all three.
///
/// **Nothing here is stored.** `home-overview`'s D3 keeps persistence out of
/// this change, so notifications are computed from budgets and the ledger on
/// every read. That has a real consequence worth stating: there is no read or
/// unread state, and a notification disappears when the fact behind it stops
/// being true — a budget brought back under its limit stops being reported.
/// That is a defensible reading of a derived feed and it is *not* what a stored
/// feed would do.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/core/relative_time.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';

/// Every notification the app can currently justify, newest first.
///
/// Three of the five kinds authored on `57:622` are produced here. The other
/// two — a failed account sync (`57:718`) and a goal's funding progress
/// (`57:740`) — have no feature behind them, and are left out rather than
/// seeded. See [HomeNotification] for why that is the choice.
List<HomeNotification> deriveNotifications({
  required List<BudgetProgress> budgets,
  required List<Transaction> transactions,
  required DateTime now,
  String? locale,
}) {
  final notifications = <HomeNotification>[
    ...budgets.expand((progress) => _overLimit(progress, now)),
    ...transactions.expand((transaction) => _income(transaction, now)),
    ..._periodEnding(budgets, now, locale),
  ];

  // Newest first, which the screen then splits into Today and Earlier.
  return notifications..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
}

/// `57:662` — "Shopping is over budget" / "740,000 ₫ over · 2 hours ago".
Iterable<HomeNotification> _overLimit(BudgetProgress progress, DateTime now) {
  if (progress.status != BudgetStatus.over) return const [];

  // `passedLimitOn` is the instant the budget actually tipped over, computed by
  // walking the window in occurrence order. Without it there is no honest
  // timestamp, and a notification dated "now" would climb back to the top of
  // the list every time the screen opened, so it is skipped instead.
  final crossed = progress.passedLimitOn;
  if (crossed == null) return const [];

  return [
    HomeNotification(
      id: 'budget-over-${progress.budget.id}',
      kind: NotificationKind.budgetOverLimit,
      title: '${progress.budget.category.label} is over budget',
      detail:
          '${progress.overBy.format()} over · ${relativeTime(crossed, now)}',
      icon: MonetaIconName.alertTriangle,
      occurredAt: crossed,
      targetId: progress.budget.id,
    ),
  ];
}

/// `57:688` — "Salary received" / "+32,000,000 ₫ from NUS Technology · 8 hours ago".
///
/// One per income transaction. **No threshold**: "notify above X" would be a
/// rule the design never states, and a made-up threshold silently decides which
/// of the user's own income is worth mentioning.
///
/// The glyph comes from the transaction's category, not from the kind. `57:688`
/// uses `icon/briefcase`, which is exactly what `SpendCategory.salary` already
/// names — so the design derives it from the category too, and hard-coding a
/// briefcase would put the wrong glyph on a gift or a refund.
Iterable<HomeNotification> _income(Transaction transaction, DateTime now) {
  if (transaction.direction != TransactionDirection.income) return const [];

  final note = transaction.note?.trim();
  final from = note != null && note.isNotEmpty ? ' from $note' : '';

  return [
    HomeNotification(
      id: 'income-${transaction.id}',
      kind: NotificationKind.incomeReceived,
      title: '${transaction.category.label} received',
      detail:
          '${transaction.amount.format(showSign: true)}$from · '
          '${relativeTime(transaction.occurredAt, now)}',
      icon:
          MonetaIconName.tryParse(transaction.category.iconName) ??
          MonetaIconName.briefcase,
      occurredAt: transaction.occurredAt,
    ),
  ];
}

/// `57:773` — "Budgets reset in 13 days" / "September budgets will start fresh".
///
/// One notice, not one per budget: the authored title says "Budgets", plural.
/// It uses the **soonest** window to end, because that is the next reset the
/// user will actually experience when periods differ.
///
/// `BudgetWindow.end` is exclusive, so it already *is* the next period's first
/// instant — the month name is read straight off it rather than by adding a
/// month and hoping.
///
/// Dated at the window's **start**. A derived notice has no creation moment of
/// its own, and the start is the only instant that belongs to it; it also makes
/// the entry age naturally through the period instead of sitting at "just now"
/// forever.
Iterable<HomeNotification> _periodEnding(
  List<BudgetProgress> budgets,
  DateTime now,
  String? locale,
) {
  if (budgets.isEmpty) return const [];

  final soonest = budgets
      .map((progress) => progress.window)
      .reduce((a, b) => a.end.isBefore(b.end) ? a : b);

  final days = soonest.daysRemainingFrom(now);
  final month = DateFormat.MMMM(locale).format(soonest.end.toLocal());

  return [
    HomeNotification(
      id: 'budget-reset-${soonest.end.toIso8601String()}',
      kind: NotificationKind.budgetPeriodEnding,
      title: 'Budgets reset in $days day${days == 1 ? '' : 's'}',
      detail:
          '$month budgets will start fresh · '
          '${relativeTime(soonest.start, now)}',
      icon: MonetaIconName.calendar,
      occurredAt: soonest.start,
    ),
  ];
}

/// The notification centre's contents.
final notificationsProvider = Provider<AsyncValue<List<HomeNotification>>>((
  ref,
) {
  final now = ref.watch(clockProvider).nowUtc();
  final progress = ref.watch(budgetProgressProvider);
  final list = ref.watch(transactionListControllerProvider);

  if (progress case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  final budgets = progress.value;
  if (budgets == null) return const AsyncLoading();

  return list.whenData(
    (state) => deriveNotifications(
      budgets: budgets,
      transactions: [
        for (final day in state.days) ...day.transactions,
      ],
      now: now,
    ),
  );
});
