// Time-zone gate.
//
// Local-time assertions cannot fail under UTC. `formatTimeOfDay(instant)` and
// `formatTimeOfDay(instant.toLocal())` are the same string when the process zone
// is UTC, so a test comparing them passes for an implementation that never
// converts at all. The same is true of any "last local day" calculation: in UTC
// the right answer and the UTC-based wrong answer coincide.
//
// tool/verify.sh exports TZ before running anything. This checks that it took
// effect, so removing that line fails the gate loudly instead of quietly turning
// a set of tests into decoration.
//
// Usage: dart run tool/check_timezone.dart
import 'dart:io';

/// The zone the gate runs in — the app's target locale, and ahead of UTC.
const String expectedZoneName = 'Asia/Ho_Chi_Minh';

/// Offset that zone has year-round (it observes no daylight saving).
const Duration expectedOffset = Duration(hours: 7);

void main() {
  final tz = Platform.environment['TZ'];
  final offset = DateTime.now().timeZoneOffset;

  if (offset == Duration.zero) {
    stderr
      ..writeln('✗ timezone: the process is running in UTC.')
      ..writeln(
        '  Every local-time assertion in the suite is decorative under UTC — a\n'
        '  function that forgets .toLocal() returns the same answer, so the test\n'
        '  passes for a broken implementation.',
      )
      ..writeln('  Expected TZ=$expectedZoneName (got ${tz ?? "unset"}).');
    exit(1);
  }

  if (tz != expectedZoneName) {
    stderr
      ..writeln(
        '✗ timezone: TZ is "${tz ?? "unset"}", expected "$expectedZoneName".',
      )
      ..writeln(
        '  The suite has assertions that only discriminate in a specific zone;\n'
        '  running in another one changes what they prove.',
      );
    exit(1);
  }

  if (offset != expectedOffset) {
    stderr.writeln(
      '✗ timezone: TZ=$expectedZoneName resolved to $offset, '
      'expected $expectedOffset. Is the tzdata on this machine current?',
    );
    exit(1);
  }

  stdout.writeln(
    '✓ timezone: $expectedZoneName ($offset), local-time tests can discriminate',
  );
}
