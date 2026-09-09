/// How long ago something happened, in words.
///
/// Notification subtitles on `57:622` end in "2 hours ago", "8 hours ago",
/// "3 days ago". This produces that tail.
///
/// **Elapsed, not calendar.** Something at 23:00 last night reads as "9 hours
/// ago" rather than "1 day ago", which is what the frame's mixed hours-and-days
/// samples imply. Day *grouping* on that screen is calendar-based and local —
/// the two are deliberately different questions, and conflating them is why a
/// row can sit under "Today" and still say "20 hours ago".
///
/// Both instants must be UTC, like everything else stored in this app.
library;

/// A human phrase for the gap between [instant] and [now].
///
/// [now] is passed in rather than read from the system clock: a formatter that
/// calls `DateTime.now()` cannot be tested at a chosen moment, and this project
/// injects `Clock` everywhere for that reason.
String relativeTime(DateTime instant, DateTime now) {
  final elapsed = now.difference(instant);

  // A future instant is a clock skew or a bad fixture, not something to render
  // as "-3 days ago". Clamped rather than thrown: a notification list is not
  // worth crashing over a timestamp a second into the future.
  if (elapsed.isNegative) return 'just now';

  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return _plural(elapsed.inMinutes, 'minute');
  if (elapsed.inDays < 1) return _plural(elapsed.inHours, 'hour');
  return _plural(elapsed.inDays, 'day');
}

String _plural(int count, String unit) =>
    '$count $unit${count == 1 ? '' : 's'} ago';
