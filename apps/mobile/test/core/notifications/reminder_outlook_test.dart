import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/notifications/reminder_outlook.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';

void main() {
  // A Monday evening.
  final now = DateTime(2026, 11, 2, 18, 5);

  PlannedReminder nudge(DateTime at, {String? from = 'priya'}) =>
      PlannedReminder(
        id: 1,
        at: at,
        kind: ReminderKind.nudge,
        title: 'Priya · Northstar Labs',
        body: 'Your next interview is waiting.',
        variant: 0,
        missionNumber: 2,
        interviewerId: from,
      );

  String line(PlannedReminder r) =>
      nextReminderLine(ReminderOutlook.next(r), now);

  test('tomorrow, at the planned time, from the interviewer', () {
    expect(
      line(nudge(DateTime(2026, 11, 3, 19, 40))),
      'Next: tomorrow at 19:40, from Priya',
    );
    expect(
      line(nudge(DateTime(2026, 11, 3, 9), from: 'marcus')),
      'Next: tomorrow at 09:00, from Marcus',
    );
  });

  test('later this week by weekday; a week or more by date', () {
    expect(
      line(nudge(DateTime(2026, 11, 5, 18, 5))),
      'Next: Thursday at 18:05, from Priya',
    );
    expect(
      line(nudge(DateTime(2026, 11, 10, 18, 5))),
      'Next: Tuesday 10 November at 18:05, from Priya',
    );
  });

  test('cards due: from the Recall Room', () {
    final recall = PlannedReminder(
      id: 1,
      at: DateTime(2026, 11, 3, 18, 5),
      kind: ReminderKind.recallDue,
      title: 'Recall Room',
      body: '2 notes are waiting in the Recall Room.',
      variant: 0,
    );
    expect(line(recall), 'Next: tomorrow at 18:05, from the Recall Room');
  });

  test('an unknown sender is the company', () {
    expect(
      line(nudge(DateTime(2026, 11, 3, 10), from: null)),
      'Next: tomorrow at 10:00, from Northstar Labs',
    );
  });

  test('none, and why: off, blocked, the web, nothing to say', () {
    String quiet(ReminderQuiet q) =>
        nextReminderLine(ReminderOutlook.quiet(q), now);
    expect(quiet(ReminderQuiet.off), ReminderLines.off);
    expect(quiet(ReminderQuiet.blocked), ReminderLines.blocked);
    expect(quiet(ReminderQuiet.web), ReminderLines.web);
    expect(quiet(ReminderQuiet.nothingPlanned), ReminderLines.nothingPlanned);
    expect(ReminderLines.web, contains('phone-only'));
  });

  test('across a month end, still "tomorrow"', () {
    expect(
      reminderWhen(DateTime(2026, 12, 1, 12), DateTime(2026, 11, 30, 23)),
      'tomorrow at 12:00',
    );
  });
}
