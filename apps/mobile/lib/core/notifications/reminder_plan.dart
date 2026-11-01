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

  @override
  String toString() => 'PlannedReminder($id, $at, ${kind.name}, "$body")';
}

/// The reminders' rules (FR-50, FR-51, brief 26), as one pure function: the app calls it on
/// every open and every close, cancels what was scheduled, and schedules the result (ADR 0004).
///
/// - **Never today.** The player is here now; the plan starts tomorrow.
/// - **At most one a day,** at the time of day the player last opened the game (their habit),
///   kept between [earliestMinute] and [latestMinute]: never after 21:00, never early.
/// - **Kind, then backing off.** Days 1, 2 and 3; if those three went unanswered the player
///   hasn't opened the game since (any open re-plans), so after them only every third day
///   (day 6), then silence until they come back. [planDays].
/// - **Recall first:** a day with cards due in the Recall Room gets "N traps are waiting";
///   otherwise the next mission's interviewer nudges, in character. With nothing due and no
///   mission left, that day is quiet.
/// - Off ([enabled] false, or no permission): nothing.
///
/// [recallDue] gives, for a calendar day, how many cards will be due by then.
List<PlannedReminder> planReminders({
  required DateTime now,
  required bool enabled,
  required int Function(DateTime day) recallDue,
  NextMission? nextMission,
}) {
  if (!enabled) return const [];
  final minute = (now.hour * _minutesPerHour + now.minute).clamp(
    earliestMinute,
    latestMinute,
  );
  final plan = <PlannedReminder>[];
  for (final day in planDays) {
    final at = DateTime(
      now.year,
      now.month,
      now.day + day,
      minute ~/ _minutesPerHour,
      minute % _minutesPerHour,
    );
    final variant = day % ReminderCopy.variants;
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
          body: ReminderCopy.nudgeBody(nextMission.interviewerId, variant),
          variant: variant,
          missionNumber: nextMission.number,
        ),
      );
    }
  }
  return plan;
}

/// The days (from today) a plan may use: three in a row, then, if those were ignored, every
/// third day. Seven days ahead at most (ADR 0004); the next open re-plans anyway.
const List<int> planDays = [1, 2, 3, 6];

/// 09:00: nothing before the day has started.
const int earliestMinute = 9 * _minutesPerHour;

/// 20:30: comfortably before the 21:00 cut-off.
const int latestMinute = 20 * _minutesPerHour + 30;

const int _minutesPerHour = 60;
