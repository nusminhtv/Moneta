import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);
  AddTransactionForm vndForm({DateTime? at}) =>
      AddTransactionForm(currency: Currency.vnd, now: at ?? now);

  AppFailure failureOf(Result<Object?> result) => result.when(
    ok: (v) => fail('expected a failure, got $v'),
    err: (f) => f,
  );

  group('amount', () {
    test('accepts a plain number', () {
      final result = vndForm().parseAmount('45000');
      expect(result.valueOrNull!.minorUnits, 45000);
    });

    test('accepts thousands separators', () {
      expect(
        vndForm().parseAmount('1,250,000').valueOrNull!.minorUnits,
        1250000,
      );
    });

    test('trims surrounding whitespace', () {
      expect(vndForm().parseAmount('  500  ').valueOrNull!.minorUnits, 500);
    });

    test('rejects an empty amount', () {
      final failure = failureOf(vndForm().parseAmount(''));
      expect(failure.kind, FailureKind.validation);
      expect(failure.message, 'Enter an amount');
    });

    test('rejects whitespace only', () {
      expect(
        failureOf(vndForm().parseAmount('   ')).kind,
        FailureKind.validation,
      );
    });

    test('rejects zero', () {
      final failure = failureOf(vndForm().parseAmount('0'));
      expect(failure.message, contains('more than zero'));
    });

    test('rejects a negative amount', () {
      // Direction carries the sign; a minus in the field is a different bug.
      expect(
        failureOf(vndForm().parseAmount('-100')).kind,
        FailureKind.validation,
      );
    });

    test('rejects text', () {
      expect(
        failureOf(vndForm().parseAmount('abc')).kind,
        FailureKind.validation,
      );
      expect(
        failureOf(vndForm().parseAmount('12abc')).kind,
        FailureKind.validation,
      );
    });

    test('rejects more decimals than the currency allows', () {
      final vnd = failureOf(vndForm().parseAmount('1.5'));
      expect(vnd.kind, FailureKind.validation);
      expect(vnd.message, contains('no decimals'));

      final usdForm = AddTransactionForm(currency: Currency.usd, now: now);
      final usd = failureOf(usdForm.parseAmount('12.345'));
      expect(usd.message, contains('at most 2 decimals'));
    });

    test("accepts the currency's own precision", () {
      final usdForm = AddTransactionForm(currency: Currency.usd, now: now);
      expect(usdForm.parseAmount('12.34').valueOrNull!.minorUnits, 1234);
    });
  });

  group('instant', () {
    test('accepts now', () {
      expect(vndForm().validateInstant(now).isOk, isTrue);
    });

    test('accepts the past', () {
      expect(
        vndForm().validateInstant(now.subtract(const Duration(days: 30))).isOk,
        isTrue,
      );
    });

    test('rejects the future', () {
      // A balance that includes money not yet spent is wrong.
      final failure = failureOf(
        vndForm().validateInstant(now.add(const Duration(minutes: 1))),
      );
      expect(failure.kind, FailureKind.validation);
      expect(failure.message, contains('future'));
    });

    test('compares in UTC, not local time', () {
      final localFuture = now.add(const Duration(hours: 1)).toLocal();
      expect(vndForm().validateInstant(localFuture).isOk, isFalse);
    });

    test('normalises the accepted instant to UTC', () {
      final result = vndForm().validateInstant(
        now.subtract(const Duration(hours: 1)).toLocal(),
      );
      expect(result.valueOrNull!.isUtc, isTrue);
    });
  });

  group('build', () {
    Result<Transaction> build({
      String amount = '45000',
      DateTime? at,
      String? note,
    }) {
      return vndForm().build(
        id: 'tx-1',
        rawAmount: amount,
        direction: TransactionDirection.expense,
        category: SpendCategory.food,
        occurredAt: at ?? now,
        note: note,
      );
    }

    test('produces a transaction from valid input', () {
      final tx = build(note: 'phở').valueOrNull!;
      expect(tx.id, 'tx-1');
      expect(tx.amount.minorUnits, 45000);
      expect(tx.category, SpendCategory.food);
      expect(tx.note, 'phở');
      expect(tx.createdAt, now);
    });

    test('reports the amount problem first', () {
      final failure = failureOf(
        build(amount: '', at: now.add(const Duration(days: 1))),
      );
      expect(failure.message, 'Enter an amount');
    });

    test('reports the date problem when the amount is fine', () {
      final failure = failureOf(build(at: now.add(const Duration(days: 1))));
      expect(failure.message, contains('future'));
    });

    test('an empty note becomes no note', () {
      expect(build(note: '').valueOrNull!.note, isNull);
      expect(build(note: '   ').valueOrNull!.note, isNull);
    });

    test('an over-length note is rejected rather than truncated', () {
      final failure = failureOf(
        build(note: 'a' * (Transaction.maxNoteLength + 1)),
      );
      expect(failure.kind, FailureKind.validation);
    });

    test('nothing is built when validation fails', () {
      expect(build(amount: '0').isOk, isFalse);
    });
  });
}
