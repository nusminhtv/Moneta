import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_list_controller.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// Validates the raw form input.
///
/// Pure, so the rules can be tested without pumping a widget, and so the same
/// rules are used by the form and by anything else that records a transaction.
final class AddTransactionForm {
  /// Creates a validator.
  const AddTransactionForm({
    required this.currency,
    required this.now,
  });

  /// Currency amounts are parsed in.
  final Currency currency;

  /// Current instant, injected so "in the future" is testable.
  final DateTime now;

  /// Validates [rawAmount], returning the parsed money or a validation failure.
  Result<Money> parseAmount(String rawAmount) {
    final trimmed = rawAmount.trim();
    if (trimmed.isEmpty) {
      return const Err(AppFailure.validation('Enter an amount'));
    }
    final Money parsed;
    try {
      parsed = Money.parse(trimmed, currency);
    } on FormatException {
      return Err(
        AppFailure.validation(
          currency.decimals == 0
              ? '${currency.code} amounts have no decimals'
              : 'Enter a number with at most ${currency.decimals} decimals',
        ),
      );
    }
    if (parsed.minorUnits <= 0) {
      return const Err(AppFailure.validation('Amount must be more than zero'));
    }
    return Ok(parsed);
  }

  /// Validates [occurredAt].
  Result<DateTime> validateInstant(DateTime occurredAt) {
    if (occurredAt.toUtc().isAfter(now.toUtc())) {
      // A balance that includes money not yet spent is wrong.
      return const Err(
        AppFailure.validation('Pick a date that is not in the future'),
      );
    }
    return Ok(occurredAt.toUtc());
  }

  /// Builds a transaction, or the first validation failure.
  Result<Transaction> build({
    required String id,
    required String rawAmount,
    required TransactionDirection direction,
    required SpendCategory category,
    required DateTime occurredAt,
    String? note,
  }) {
    final amount = parseAmount(rawAmount);
    if (amount is Err<Money>) return Err(amount.failure);

    final instant = validateInstant(occurredAt);
    if (instant is Err<DateTime>) return Err(instant.failure);

    return Transaction.create(
      id: id,
      amount: (amount as Ok<Money>).value,
      direction: direction,
      category: category,
      occurredAt: (instant as Ok<DateTime>).value,
      createdAt: now.toUtc(),
      note: note,
    );
  }
}

/// Sheet for recording a transaction.
class AddTransactionSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const AddTransactionSheet({super.key});

  /// Key on the amount field.
  static const Key amountFieldKey = Key('AddTransactionSheet.amount');

  /// Key on the note field.
  static const Key noteFieldKey = Key('AddTransactionSheet.note');

  /// Key on the submit button.
  static const Key submitKey = Key('AddTransactionSheet.submit');

  /// Key on the inline error message.
  static const Key errorKey = Key('AddTransactionSheet.error');

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionDirection _direction = TransactionDirection.expense;
  SpendCategory _category = SpendCategory.food;
  DateTime? _occurredAt;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final clock = ref.read(clockProvider);
    final currency = ref.read(walletCurrencyProvider);
    final ids = ref.read(idGeneratorProvider);

    final form = AddTransactionForm(currency: currency, now: clock.nowUtc());
    final built = form.build(
      id: ids.next(),
      rawAmount: _amountController.text,
      direction: _direction,
      category: _category,
      occurredAt: _occurredAt ?? clock.nowUtc(),
      note: _noteController.text,
    );

    if (built is Err<Transaction>) {
      setState(() => _error = built.failure.message);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final result = await ref
        .read(transactionListControllerProvider.notifier)
        .add((built as Ok<Transaction>).value);

    if (!mounted) return;
    result.when(
      ok: (_) => Navigator.of(context).maybePop(),
      err: (failure) => setState(() {
        _error = failure.message;
        _submitting = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: theme.spacing.x4l,
        right: theme.spacing.x4l,
        top: theme.spacing.x4l,
        bottom: MediaQuery.viewInsetsOf(context).bottom + theme.spacing.x4l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New transaction',
            style: theme.text.titleMd.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: theme.spacing.x3l),
          SegmentedButton<TransactionDirection>(
            segments: const [
              ButtonSegment(
                value: TransactionDirection.expense,
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: TransactionDirection.income,
                label: Text('Income'),
              ),
            ],
            selected: {_direction},
            onSelectionChanged: (selection) =>
                setState(() => _direction = selection.first),
          ),
          SizedBox(height: theme.spacing.x3l),
          TextField(
            key: AddTransactionSheet.amountFieldKey,
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.text.amountMd.copyWith(color: colors.textPrimary),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          SizedBox(height: theme.spacing.x3l),
          DropdownButtonFormField<SpendCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in SpendCategory.values)
                DropdownMenuItem(value: category, child: Text(category.label)),
            ],
            onChanged: (category) =>
                setState(() => _category = category ?? _category),
          ),
          SizedBox(height: theme.spacing.x3l),
          TextField(
            key: AddTransactionSheet.noteFieldKey,
            controller: _noteController,
            maxLength: Transaction.maxNoteLength,
            style: theme.text.bodyMd.copyWith(color: colors.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            SizedBox(height: theme.spacing.md),
            Text(
              _error!,
              key: AddTransactionSheet.errorKey,
              style: theme.text.captionMd.copyWith(color: colors.expense),
            ),
          ],
          SizedBox(height: theme.spacing.x4l),
          FilledButton(
            key: AddTransactionSheet.submitKey,
            onPressed: _submitting ? null : _submit,
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}
