import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/day_grouping.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';

/// The transaction list.
class TransactionsScreen extends ConsumerWidget {
  /// Creates the screen.
  const TransactionsScreen({super.key});

  /// Route path.
  static const String routePath = '/transactions';

  /// Key on the empty state.
  static const Key emptyStateKey = Key('TransactionsScreen.empty');

  /// Key on the error state.
  static const Key errorStateKey = Key('TransactionsScreen.error');

  /// Key on the retry action inside the error state.
  static const Key retryKey = Key('TransactionsScreen.retry');

  /// Key on the loading indicator.
  static const Key loadingKey = Key('TransactionsScreen.loading');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.moneta;
    final async = ref.watch(transactionListControllerProvider);

    return Scaffold(
      backgroundColor: theme.colors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.x4l,
                theme.spacing.x4l,
                theme.spacing.x4l,
                theme.spacing.xl,
              ),
              child: Text(
                'Transactions',
                style: theme.text.headingH1.copyWith(
                  color: theme.colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: switch (async) {
                AsyncLoading<TransactionListState>() => const Center(
                  key: loadingKey,
                  child: CircularProgressIndicator(),
                ),
                // Error and empty are rendered as different things on purpose:
                // "nothing here" and "we could not look" mean different things
                // and only one of them is the user's fault to fix.
                AsyncError<TransactionListState>(:final error) => _ErrorState(
                  message: error is TransactionListFailure
                      ? error.failure.message
                      : 'Something went wrong reading your transactions',
                  onRetry: () => ref
                      .read(transactionListControllerProvider.notifier)
                      .refresh(),
                ),
                AsyncValue<TransactionListState>(:final value?)
                    when value.isEmpty =>
                  const _EmptyState(),
                AsyncValue<TransactionListState>(:final value?) => _DayList(
                  days: value.days,
                  onDelete: (transaction) => _delete(context, ref, transaction),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final controller = ref.read(transactionListControllerProvider.notifier);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await controller.delete(transaction);

    if (messenger == null) return;
    result.when(
      ok: (_) => messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted ${transaction.displayTitle}'),
          duration: TransactionListController.undoWindow,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: controller.undoDelete,
          ),
        ),
      ),
      err: (failure) =>
          messenger.showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Center(
      key: TransactionsScreen.emptyStateKey,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.x4l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonetaIcon(
              MonetaIconName.list,
              size: 48,
              color: theme.colors.textTertiary,
            ),
            SizedBox(height: theme.spacing.x3l),
            Text(
              'No transactions yet',
              textAlign: TextAlign.center,
              style: theme.text.titleMd.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              'Tap the + button to record your first one.',
              textAlign: TextAlign.center,
              style: theme.text.bodyMd.copyWith(
                color: theme.colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Center(
      key: TransactionsScreen.errorStateKey,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.x4l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonetaIcon(
              MonetaIconName.alertTriangle,
              size: 48,
              color: theme.colors.expense,
            ),
            SizedBox(height: theme.spacing.x3l),
            Text(
              'Could not load your transactions',
              textAlign: TextAlign.center,
              style: theme.text.titleMd.copyWith(
                color: theme.colors.textPrimary,
              ),
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.text.bodyMd.copyWith(
                color: theme.colors.textTertiary,
              ),
            ),
            SizedBox(height: theme.spacing.x3l),
            TextButton(
              key: TransactionsScreen.retryKey,
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: theme.text.labelMd.copyWith(
                  color: theme.colors.brandOnSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.days, required this.onDelete});

  final List<TransactionDay> days;
  final ValueChanged<Transaction> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DayHeading(day: day),
            for (final transaction in day.transactions)
              Dismissible(
                key: ValueKey(transaction.id),
                direction: DismissDirection.endToStart,
                background: ColoredBox(
                  color: theme.colors.expenseSubtle,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: theme.spacing.x4l),
                      child: MonetaIcon(
                        MonetaIconName.trash,
                        color: theme.colors.expense,
                      ),
                    ),
                  ),
                ),
                onDismissed: (_) => onDelete(transaction),
                child: TransactionRow(
                  title: transaction.displayTitle,
                  amount: transaction.amount,
                  direction: transaction.direction,
                  category: transaction.category,
                  occurredAt: transaction.occurredAt,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.day});

  final TransactionDay day;

  /// Formats a day heading, e.g. `Mon 24 Aug`.
  static String formatDate(DateTime date, {String? locale}) =>
      DateFormat('EEE d MMM', locale).format(date);

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final net = day.net;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.x3l,
        theme.spacing.x3l,
        theme.spacing.x3l,
        theme.spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDate(day.date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text.labelMd.copyWith(
                color: theme.colors.textTertiary,
              ),
            ),
          ),
          Text(
            net.format(showSign: true),
            maxLines: 1,
            style: theme.text.labelMd.copyWith(
              color: net.isNegative
                  ? theme.colors.textTertiary
                  : theme.colors.income,
            ),
          ),
        ],
      ),
    );
  }
}
