/// Injectable source of "now" so time-dependent logic stays testable.
abstract interface class Clock {
  /// The current instant, in UTC.
  DateTime nowUtc();
}

/// Production clock backed by [DateTime.now].
final class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Deterministic clock for tests and golden files.
final class FixedClock implements Clock {
  /// Creates a clock frozen at [instant].
  FixedClock(this.instant);

  /// The instant returned by [nowUtc].
  DateTime instant;

  @override
  DateTime nowUtc() => instant.toUtc();
}
