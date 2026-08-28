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

/// Deterministic clock that advances by [step] on every read.
///
/// [FixedClock] cannot expose a bug where code reads the clock twice and
/// compares the two readings: frozen, the readings are equal and the comparison
/// always passes. In production they differ by microseconds and it does not.
///
/// That is not hypothetical. The add-transaction sheet read `nowUtc()` once for
/// its validator and again for the transaction's instant, then rejected the
/// instant for being *after* now — so every submission failed with "Pick a date
/// that is not in the future", on a form with no date field. The whole suite was
/// green, because every test used a frozen clock.
///
/// Use this wherever the code under test reads the clock more than once.
final class TickingClock implements Clock {
  /// Creates a clock starting at [start] that advances by [step] per read.
  TickingClock(this.start, {this.step = const Duration(microseconds: 1)});

  /// The instant the first read returns.
  final DateTime start;

  /// How much later each subsequent read is.
  final Duration step;

  int _reads = 0;

  /// How many times this clock has been read.
  int get reads => _reads;

  @override
  DateTime nowUtc() => start.toUtc().add(step * _reads++);
}
