import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';

void main() {
  final start = DateTime.utc(2026, 8);
  final end = DateTime.utc(2026, 9);

  TransactionQuery ok(Result<TransactionQuery> r) =>
      r.when(ok: (q) => q, err: (f) => fail('expected Ok, got $f'));

  group('construction', () {
    test('an unfiltered query matches everything', () {
      expect(TransactionQuery.all.isUnfiltered, isTrue);
      expect(ok(TransactionQuery.build()).isUnfiltered, isTrue);
    });

    test('normalises the range to UTC', () {
      final query = ok(
        TransactionQuery.build(
          start: DateTime(2026, 8),
          end: DateTime(2026, 9),
        ),
      );
      expect(query.start!.isUtc, isTrue);
      expect(query.end!.isUtc, isTrue);
    });

    test('rejects an inverted range instead of matching nothing', () {
      // An empty list would look like "no transactions" and hide the bug.
      final result = TransactionQuery.build(start: end, end: start);
      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (f) => expect(f.kind, FailureKind.validation),
      );
    });

    test('rejects a zero-width range', () {
      // start == end can never match anything, given exclusive end.
      expect(TransactionQuery.build(start: start, end: start).isOk, isFalse);
    });

    test('rejects a non-positive limit', () {
      expect(TransactionQuery.build(limit: 0).isOk, isFalse);
      expect(TransactionQuery.build(limit: -1).isOk, isFalse);
      expect(TransactionQuery.build(limit: 1).isOk, isTrue);
    });

    test('allows a one-sided range', () {
      expect(TransactionQuery.build(start: start).isOk, isTrue);
      expect(TransactionQuery.build(end: end).isOk, isTrue);
    });
  });

  group('containsInstant — the boundary rule', () {
    final query = ok(TransactionQuery.build(start: start, end: end));

    test('the start instant is included', () {
      expect(query.containsInstant(start), isTrue);
    });

    test('the end instant is excluded', () {
      expect(query.containsInstant(end), isFalse);
    });

    test('one millisecond before the end is included', () {
      expect(
        query.containsInstant(end.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('one millisecond before the start is excluded', () {
      expect(
        query.containsInstant(start.subtract(const Duration(milliseconds: 1))),
        isFalse,
      );
    });

    test('adjacent ranges neither overlap nor drop the boundary instant', () {
      final august = ok(TransactionQuery.build(start: start, end: end));
      final september = ok(
        TransactionQuery.build(start: end, end: DateTime.utc(2026, 10)),
      );
      expect(august.containsInstant(end), isFalse);
      expect(september.containsInstant(end), isTrue);
    });

    test('a local instant is compared in UTC', () {
      final localMidAugust = DateTime.utc(2026, 8, 15).toLocal();
      expect(query.containsInstant(localMidAugust), isTrue);
    });

    test('an unbounded query contains any instant', () {
      expect(TransactionQuery.all.containsInstant(DateTime.utc(1990)), isTrue);
      expect(TransactionQuery.all.containsInstant(DateTime.utc(2200)), isTrue);
    });

    test('a one-sided range bounds only that side', () {
      final from = ok(TransactionQuery.build(start: start));
      expect(from.containsInstant(DateTime.utc(2030)), isTrue);
      expect(from.containsInstant(DateTime.utc(2020)), isFalse);
    });
  });

  group('equality', () {
    test('queries with the same shape are equal', () {
      expect(
        ok(TransactionQuery.build(categories: {SpendCategory.food})),
        ok(TransactionQuery.build(categories: {SpendCategory.food})),
      );
    });

    test('a different category set is a different query', () {
      expect(
        ok(TransactionQuery.build(categories: {SpendCategory.food})),
        isNot(ok(TransactionQuery.build(categories: {SpendCategory.bills}))),
      );
    });
  });
}
