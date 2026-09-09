import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/relative_time.dart';

/// The tail of every notification subtitle on `57:622`.
void main() {
  final now = DateTime.utc(2026, 9, 9, 12);

  String at(Duration ago) => relativeTime(now.subtract(ago), now);

  group('boundaries', () {
    test('under a minute is "just now"', () {
      expect(at(Duration.zero), 'just now');
      expect(at(const Duration(seconds: 59)), 'just now');
    });

    test('one minute is the first counted value', () {
      expect(at(const Duration(minutes: 1)), '1 minute ago');
    });

    test('fifty-nine minutes is still minutes', () {
      expect(at(const Duration(minutes: 59)), '59 minutes ago');
    });

    test('an hour switches unit', () {
      expect(at(const Duration(hours: 1)), '1 hour ago');
    });

    test('twenty-three hours is still hours', () {
      expect(at(const Duration(hours: 23)), '23 hours ago');
    });

    test('a day switches unit again', () {
      expect(at(const Duration(hours: 24)), '1 day ago');
    });
  });

  group('the frame samples', () {
    test('2 hours ago', () {
      expect(at(const Duration(hours: 2)), '2 hours ago');
    });

    test('8 hours ago', () {
      expect(at(const Duration(hours: 8)), '8 hours ago');
    });

    test('3 days ago', () {
      expect(at(const Duration(days: 3)), '3 days ago');
    });
  });

  group('plurals', () {
    test('one is singular in every unit', () {
      expect(at(const Duration(minutes: 1)), contains('1 minute '));
      expect(at(const Duration(hours: 1)), contains('1 hour '));
      expect(at(const Duration(days: 1)), contains('1 day '));
    });

    test('two is plural in every unit', () {
      expect(at(const Duration(minutes: 2)), contains('2 minutes '));
      expect(at(const Duration(hours: 2)), contains('2 hours '));
      expect(at(const Duration(days: 2)), contains('2 days '));
    });
  });

  group('elapsed, not calendar', () {
    test('late last night reads in hours, not as a day', () {
      // The same instant groups under a different calendar day than it reports
      // in words. That is deliberate: grouping and elapsed time answer
      // different questions.
      final lastNight = DateTime.utc(2026, 9, 8, 23);
      expect(relativeTime(lastNight, now), '13 hours ago');
    });
  });

  group('a future instant', () {
    test('does not render a negative duration', () {
      final later = now.add(const Duration(days: 3));
      expect(relativeTime(later, now), 'just now');
    });

    test('a second into the future is tolerated, not thrown', () {
      final later = now.add(const Duration(seconds: 1));
      expect(relativeTime(later, now), 'just now');
    });
  });

  group('long gaps', () {
    test('a year is reported in days rather than switching unit', () {
      // No week, month or year unit: the frame never shows one, and inventing
      // "11 months ago" would be a rule nothing in the design asks for.
      expect(at(const Duration(days: 365)), '365 days ago');
    });
  });
}
