import 'reminder_copy.dart';

/// What a reminder is for (`notification_opened`'s `type`).
enum ReminderKind {
  /// Cards are due in the Recall Room.
  recallDue,

  /// The next mission's interviewer, in character.
  nudge,
}

/// The mission the player plays next, and who asks its question.
class NextMission {
  const NextMission({required this.number, required this.interviewerId});

  final int number;
  final String interviewerId;
}

/// One local notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.variant,
    this.missionNumber,
    this.interviewerId,
  });

  /// Stable per day of the plan, so a re-plan replaces rather than duplicates.
  final int id;

  /// Local time.
  final DateTime at;
  final ReminderKind kind;
  final String title;
  final String body;

  /// Which wording was used (`notification_opened`'s `variant`).
  final int variant;

  /// Where a tap goes: the mission for a nudge, the Recall Room when null.
  final int? missionNumber;

  /// Who sends a nudge ("from Priya" in Settings); null for the Recall Room.
  final String? interviewerId;

  @override
  String toString() => 'PlannedReminder($id, $at, ${kind.name}, "$body")';
}

/// The reminders' rules (FR-50, FR-51, brief 26), as one pure function: the app calls it on
/// every open and every close, cancels what was scheduled, and schedules the result (ADR 0004).
///
/// - **Never today.** The player is here now; the plan starts tomorrow.
/// - **At most one a day,** at the time of day the player last opened the game (their habit),
///   kept between [earliestMinute] and [latestMinute]: never after 21:00, never early.
/// - **Kind, then backing off.** The day after, then every other day (days 3 and 5: the days
///   the game wants the player back, brief 42); if those three went unanswered the player
///   hasn't opened the game since (any open re-plans), so after them a three-day gap (day 8),
///   then silence until they come back. [planDays].
/// - **Recall first:** a day with cards due in the Recall Room gets "N traps are waiting";
///   otherwise the next mission's interviewer nudges, in character. With nothing due and no
///   mission left, that day is quiet.
/// - Off ([enabled] false, or no permission): nothing.
///
/// [recallDue] gives, for a calendar day, how many cards will be due by then. With an
/// [interviewDate] (FR-4) still ahead, a nudge leads with the countdown to it.
List<PlannedReminder> planReminders({
  required DateTime now,
  required bool enabled,
  required int Function(DateTime day) recallDue,
  NextMission? nextMission,
  DateTime? interviewDate,
}) {
  if (!enabled) return const [];
  final minute = (now.hour * _minutesPerHour + now.minute).clamp(
    earliestMinute,
    latestMinute,
  );
  final plan = <PlannedReminder>[];
  for (final (index, day) in planDays.indexed) {
    final at = DateTime(
      now.year,
      now.month,
      now.day + day,
      minute ~/ _minutesPerHour,
      minute % _minutesPerHour,
    );
    // By position, so the reminders in one plan never repeat a wording back to back.
    final variant = index % ReminderCopy.variants;
    final due = recallDue(DateTime(at.year, at.month, at.day));
    if (due > 0) {
      plan.add(
        PlannedReminder(
          id: day,
          at: at,
          kind: ReminderKind.recallDue,
          title: ReminderCopy.recallTitle,
          body: ReminderCopy.recallBody(due, variant),
          variant: variant,
        ),
      );
    } else if (nextMission != null) {
      plan.add(
        PlannedReminder(
          id: day,
          at: at,
          kind: ReminderKind.nudge,
          title: ReminderCopy.nudgeTitle(nextMission.interviewerId),
          body: _nudgeBody(nextMission, variant, at, interviewDate),
          variant: variant,
          missionNumber: nextMission.number,
          interviewerId: nextMission.interviewerId,
        ),
      );
    }
  }
  return plan;
}

String _nudgeBody(
  NextMission next,
  int variant,
  DateTime at,
  DateTime? interviewDate,
) {
  final line = ReminderCopy.nudgeBody(next.interviewerId, variant);
  if (interviewDate == null) return line;
  final day = DateTime.utc(at.year, at.month, at.day);
  final interview = DateTime.utc(
    interviewDate.year,
    interviewDate.month,
    interviewDate.day,
  );
  final days = interview.difference(day).inDays;
  return days < 0 ? line : ReminderCopy.withCountdown(days, line);
}

/// The days (from today, the last time the game was open) a plan may use: tomorrow, then every
/// other day, so a player who installs and plays on day 0 hears from us on days 1, 3 and 5
/// (brief 42: the owner's day-3 and day-5 return); if all three were ignored, a longer gap
/// (FR-51's back-off) to day 8, then nothing more until the next open re-plans. The gaps only
/// grow: 1, 2, 2, 3.
const List<int> planDays = [1, 3, 5, 8];

/// 09:00: nothing before the day has started.
const int earliestMinute = 9 * _minutesPerHour;

/// 20:30: comfortably before the 21:00 cut-off.
const int latestMinute = 20 * _minutesPerHour + 30;

const int _minutesPerHour = 60;
