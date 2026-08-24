import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';

void main() {
  test('SystemClock returns a UTC instant', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
  });

  test('FixedClock is deterministic and settable', () {
    final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
    expect(clock.nowUtc(), DateTime.utc(2026, 3, 1, 12));
    clock.instant = DateTime.utc(2027);
    expect(clock.nowUtc().year, 2027);
  });
}
