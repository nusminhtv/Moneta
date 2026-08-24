import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/id_generator.dart';

void main() {
  group('SystemIdGenerator', () {
    test('produces unique ids across many draws', () {
      final generator = SystemIdGenerator();
      final ids = {for (var i = 0; i < 10000; i++) generator.next()};
      expect(ids, hasLength(10000));
    });

    test('stays unique when every id lands in the same millisecond', () {
      // The timestamp prefix alone is not enough; this is what the random
      // suffix is for.
      final frozen = DateTime.utc(2026, 8, 24, 12);
      final generator = SystemIdGenerator(now: () => frozen);
      final ids = {for (var i = 0; i < 5000; i++) generator.next()};
      expect(ids, hasLength(5000));
    });

    test('sorts lexicographically in creation order', () {
      var millis = 1000000000000;
      final generator = SystemIdGenerator(
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(millis += 1000, isUtc: true),
      );
      final ids = [for (var i = 0; i < 200; i++) generator.next()];
      final sorted = [...ids]..sort();
      expect(ids, sorted);
    });

    test('has the documented shape', () {
      final id = SystemIdGenerator().next();
      expect(
        id,
        matches(
          RegExp(
            '^[0-9a-z]{${SystemIdGenerator.timestampWidth},}'
            '-[0-9a-z]{${SystemIdGenerator.randomLength}}\$',
          ),
        ),
      );
    });

    test('uses the injected randomness', () {
      final generator = SystemIdGenerator(
        random: Random(42),
        now: () => DateTime.utc(2026),
      );
      final other = SystemIdGenerator(
        random: Random(42),
        now: () => DateTime.utc(2026),
      );
      expect(generator.next(), other.next());
    });
  });

  group('FixedIdGenerator', () {
    test('is deterministic and ordered', () {
      final generator = FixedIdGenerator();
      expect(generator.next(), 'id-1');
      expect(generator.next(), 'id-2');
      expect(generator.next(), 'id-3');
      expect(generator.count, 3);
    });

    test('honours a custom prefix', () {
      expect(FixedIdGenerator(prefix: 'tx').next(), 'tx-1');
    });

    test('two instances do not share state', () {
      final a = FixedIdGenerator()..next();
      final b = FixedIdGenerator();
      expect(b.next(), 'id-1');
      expect(a.next(), 'id-2');
    });
  });
}
