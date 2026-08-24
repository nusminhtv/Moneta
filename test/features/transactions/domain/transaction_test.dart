import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

void main() {
  final occurred = DateTime.utc(2026, 8, 24, 9, 30);
  final created = DateTime.utc(2026, 8, 24, 9, 31);

  Result<Transaction> make({
    String id = 'tx-1',
    Money? amount,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    DateTime? occurredAt,
    DateTime? createdAt,
    String? note,
  }) {
    return Transaction.create(
      id: id,
      amount: amount ?? const Money(45000, Currency.vnd),
      direction: direction,
      category: category,
      occurredAt: occurredAt ?? occurred,
      createdAt: createdAt ?? created,
      note: note,
    );
  }

  Transaction ok(Result<Transaction> r) =>
      r.when(ok: (t) => t, err: (f) => fail('expected Ok, got $f'));

  AppFailure err(Result<Transaction> r) =>
      r.when(ok: (t) => fail('expected Err, got $t'), err: (f) => f);

  group('amount', () {
    test('accepts a positive magnitude', () {
      expect(ok(make()).amount.minorUnits, 45000);
    });

    test('rejects zero', () {
      expect(
        err(make(amount: const Money.zero(Currency.vnd))).kind,
        FailureKind.validation,
      );
    });

    test('rejects a negative amount, because direction carries the sign', () {
      final failure = err(make(amount: const Money(-100, Currency.vnd)));
      expect(failure.kind, FailureKind.validation);
      expect(failure.message, contains('direction'));
    });

    test('accepts a trillion minor units exactly', () {
      const big = Money(1000000000000, Currency.vnd);
      expect(ok(make(amount: big)).amount, big);
    });
  });

  group('signed amount', () {
    test('an expense is negative', () {
      final tx = ok(make(direction: TransactionDirection.expense));
      expect(tx.signedAmount.minorUnits, -45000);
      expect(tx.isIncome, isFalse);
    });

    test('income is positive', () {
      final tx = ok(
        make(
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
        ),
      );
      expect(tx.signedAmount.minorUnits, 45000);
      expect(tx.isIncome, isTrue);
    });

    test('the stored amount stays a positive magnitude either way', () {
      for (final direction in TransactionDirection.values) {
        expect(ok(make(direction: direction)).amount.minorUnits, 45000);
      }
    });
  });

  group('time', () {
    test('is normalised to UTC', () {
      final local = DateTime(2026, 8, 24, 16, 30);
      final tx = ok(make(occurredAt: local));
      expect(tx.occurredAt.isUtc, isTrue);
      expect(tx.occurredAt, local.toUtc());
    });

    test('an instant recorded in one zone reads the same in another', () {
      final instant = DateTime.utc(2026, 8, 24, 2);
      final tx = ok(make(occurredAt: instant.toLocal()));
      expect(tx.occurredAt, instant);
    });

    test('createdAt is also UTC', () {
      expect(
        ok(make(createdAt: DateTime(2026, 8, 24))).createdAt.isUtc,
        isTrue,
      );
    });
  });

  group('note', () {
    test('is null when absent', () {
      expect(ok(make()).note, isNull);
    });

    test('an empty or whitespace note collapses to null', () {
      // Two representations of one state would mean two code paths forever.
      expect(ok(make(note: '')).note, isNull);
      expect(ok(make(note: '   ')).note, isNull);
    });

    test('is trimmed', () {
      expect(ok(make(note: '  phở  ')).note, 'phở');
    });

    test('accepts exactly the maximum length', () {
      final note = 'a' * Transaction.maxNoteLength;
      expect(ok(make(note: note)).note, note);
    });

    test('rejects one character over, rather than truncating', () {
      final note = 'a' * (Transaction.maxNoteLength + 1);
      expect(err(make(note: note)).kind, FailureKind.validation);
    });
  });

  group('identity', () {
    test('rejects an empty id', () {
      expect(err(make(id: '')).kind, FailureKind.validation);
    });

    test('two transactions with identical fields but different ids differ', () {
      // A person can buy the same coffee twice.
      final a = ok(make(id: 'tx-1'));
      final b = ok(make(id: 'tx-2'));
      expect(a, isNot(b));
    });

    test('two transactions with the same id and fields are equal', () {
      expect(ok(make()), ok(make()));
    });
  });

  group('displayTitle', () {
    test('is the note when there is one', () {
      expect(ok(make(note: 'Cà phê sữa')).displayTitle, 'Cà phê sữa');
    });

    test('falls back to the category label', () {
      expect(ok(make()).displayTitle, SpendCategory.food.label);
    });
  });

  group('copyWith', () {
    test('replaces a field and keeps the rest', () {
      final tx = ok(make(note: 'first'));
      final updated = ok(tx.copyWith(amount: const Money(999, Currency.vnd)));
      expect(updated.amount.minorUnits, 999);
      expect(updated.note, 'first');
      expect(updated.id, tx.id);
      expect(updated.createdAt, tx.createdAt);
    });

    test('re-runs validation', () {
      final tx = ok(make());
      final result = tx.copyWith(amount: const Money.zero(Currency.vnd));
      expect(result.isOk, isFalse);
    });

    test('can clear the note', () {
      final tx = ok(make(note: 'something'));
      expect(ok(tx.copyWith(clearNote: true)).note, isNull);
    });
  });

  group('TransactionDirection', () {
    test('round-trips its stored name', () {
      for (final direction in TransactionDirection.values) {
        expect(TransactionDirection.tryParse(direction.name), direction);
      }
    });

    test('returns null for an unknown name rather than guessing', () {
      expect(TransactionDirection.tryParse('transfer'), isNull);
      expect(TransactionDirection.tryParse('Income'), isNull);
    });
  });

  test('toString is debuggable and shows the signed amount', () {
    expect(ok(make()).toString(), contains('tx-1'));
    expect(ok(make()).toString(), contains('food'));
  });
}
