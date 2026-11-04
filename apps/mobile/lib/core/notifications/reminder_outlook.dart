import 'reminder_copy.dart';
import 'reminder_plan.dart';

/// Why no reminder is coming.
enum ReminderQuiet {
  /// The web build: reminders are phone-only (FR-53).
  web,

  /// The player switched them off (or never said yes).
  off,

  /// On in the game, but the phone isn't letting the game post notifications.
  blocked,

  /// On and allowed, with nothing to say: every room is done and no cards are due.
  nothingPlanned,
}

/// What Settings says under the reminders switch (brief 42): the next reminder, or why there
/// is none. Exactly one of [next] and [quiet] is set.
class ReminderOutlook {
  const ReminderOutlook.next(PlannedReminder this.next) : quiet = null;
  const ReminderOutlook.quiet(ReminderQuiet this.quiet) : next = null;

  final PlannedReminder? next;
  final ReminderQuiet? quiet;
}

/// The line, in plain words: "Next: tomorrow at 19:40, from Priya", or the reason there's none.
/// [now] is the device's clock, so "tomorrow" means the player's tomorrow.
String nextReminderLine(ReminderOutlook outlook, DateTime now) {
  final next = outlook.next;
  if (next == null) {
    return switch (outlook.quiet) {
      ReminderQuiet.web => ReminderLines.web,
      ReminderQuiet.blocked => ReminderLines.blocked,
      ReminderQuiet.nothingPlanned => ReminderLines.nothingPlanned,
      ReminderQuiet.off || null => ReminderLines.off,
    };
  }
  return 'Next: ${reminderWhen(next.at, now)}, from ${reminderSender(next)}';
}

/// "tomorrow at 19:40", "Thursday at 09:00", or, a week or more ahead, "Tuesday 10 November at
/// 19:40". A 24-hour clock: the line is short, and the time is never after 21:00 anyway.
String reminderWhen(DateTime at, DateTime now) =>
    '${dayWords(at, now)} at ${_twoDigits(at.hour)}:${_twoDigits(at.minute)}';

/// [day] as the player says it, from [now]: "today", "tomorrow", "Thursday" within the week,
/// "Tuesday 10 November" a week or more ahead. The reminders' line and the debrief's dated
/// promise use the same words, so they never name the same day differently.
String dayWords(DateTime day, DateTime now) {
  final days = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return switch (days) {
    0 => 'today',
    1 => 'tomorrow',
    < _week => weekdayName(day),
    _ => fullDate(day),
  };
}

/// "Thursday".
String weekdayName(DateTime day) => _weekdays[day.weekday - 1];

/// "Thursday 5 November".
String fullDate(DateTime day) =>
    '${weekdayName(day)} ${day.day} ${_months[day.month - 1]}';

/// Who a reminder comes from: the interviewer by name, or the Recall Room.
String reminderSender(PlannedReminder r) => switch (r.kind) {
  ReminderKind.recallDue => 'the Recall Room',
  ReminderKind.nudge =>
    ReminderCopy.name(r.interviewerId) ?? ReminderCopy.company,
};

/// The reasons, word for word (Settings shows them; tests find them).
abstract final class ReminderLines {
  static const String web =
      'Reminders are phone-only: the web version sends none.';
  static const String off = 'Off: no reminders will be sent.';
  static const String blocked =
      'Next: none. Your phone is blocking notifications for The Last Room; allow them in its '
      'settings.';
  static const String nothingPlanned =
      'Next: none. Every room is done and no cards are due.';
}

const int _week = 7;

String _twoDigits(int n) => n.toString().padLeft(2, '0');

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
