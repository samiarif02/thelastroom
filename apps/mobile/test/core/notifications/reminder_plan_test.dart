import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/notifications/reminder_copy.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';
import 'package:the_last_room/core/notifications/reminder_scheduler.dart';
import 'package:the_last_room/core/notifications/reminders.dart';

void main() {
  final afternoon = DateTime(2026, 11, 2, 14, 15);
  const priyaNext = NextMission(number: 2, interviewerId: 'priya');

  int none(DateTime _) => 0;

  List<PlannedReminder> plan({
    DateTime? now,
    bool enabled = true,
    int Function(DateTime)? recallDue,
    NextMission? next = priyaNext,
  }) => planReminders(
    now: now ?? afternoon,
    enabled: enabled,
    recallDue: recallDue ?? none,
    nextMission: next,
  );

  test('off: nothing is scheduled', () {
    expect(plan(enabled: false), isEmpty);
  });

  test('never today; days 1, 2, 3, then backing off to day 6', () {
    final days = [
      for (final r in plan()) r.at.difference(DateTime(2026, 11, 2)).inDays,
    ];
    expect(days, [1, 2, 3, 6]);
    expect(planDays, [1, 2, 3, 6]);
  });

  test('at most one a day', () {
    final days = plan().map((r) => DateTime(r.at.year, r.at.month, r.at.day));
    expect(days.toSet().length, days.length);
  });

  test('at the time the player plays, kept between 09:00 and 20:30', () {
    expect(plan().first.at, DateTime(2026, 11, 3, 14, 15));
    expect(
      plan(now: DateTime(2026, 11, 2, 23, 40)).first.at,
      DateTime(2026, 11, 3, 20, 30),
    );
    expect(
      plan(now: DateTime(2026, 11, 2, 6, 5)).first.at,
      DateTime(2026, 11, 3, 9),
    );
  });

  test('never at or after 21:00, whenever the game was opened', () {
    for (var minute = 0; minute < 24 * 60; minute += 7) {
      final now = DateTime(2026, 11, 2, minute ~/ 60, minute % 60);
      for (final r in plan(now: now)) {
        expect(r.at.hour * 60 + r.at.minute, lessThan(21 * 60), reason: '$now');
        expect(r.at.hour, greaterThanOrEqualTo(9), reason: '$now');
      }
    }
  });

  test(
    'cards due come first: "N traps are waiting", opening the Recall Room',
    () {
      final reminders = plan(recallDue: (day) => day.day >= 4 ? 3 : 0);
      expect(reminders.map((r) => r.kind), [
        ReminderKind.nudge,
        ReminderKind.recallDue,
        ReminderKind.recallDue,
        ReminderKind.recallDue,
      ]);
      final recall = reminders[1];
      expect(recall.title, ReminderCopy.recallTitle);
      expect(recall.body, contains('3 traps'));
      expect(recall.missionNumber, isNull);
      expect(reminderRoute(recall.missionNumber), '/tower/recall');
    },
  );

  test(
    'otherwise the next interviewer nudges, in character, opening the mission',
    () {
      final nudge = plan().first;
      expect(nudge.kind, ReminderKind.nudge);
      expect(nudge.title, startsWith('Priya'));
      expect(nudge.missionNumber, 2);
      expect(reminderRoute(nudge.missionNumber), '/tower/mission/2');
    },
  );

  test('nothing due and no mission left: quiet', () {
    expect(plan(next: null), isEmpty);
  });

  test('three wordings per kind, and a variant per day', () {
    final bodies = plan().map((r) => r.body).toSet();
    expect(bodies.length, greaterThanOrEqualTo(ReminderCopy.variants));
    for (final id in ['priya', 'marcus', 'lena', 'sam']) {
      final lines = {
        for (var v = 0; v < ReminderCopy.variants; v++)
          ReminderCopy.nudgeBody(id, v),
      };
      expect(lines, hasLength(ReminderCopy.variants), reason: id);
    }
    expect(
      ReminderCopy.recallBody(1, 0),
      '1 trap is waiting in the Recall Room.',
    );
    expect(ReminderCopy.nudgeTitle('nobody'), ReminderCopy.company);
  });

  test(
    'a payload says where to go and what to report, and survives the trip',
    () {
      for (final r in plan(recallDue: (day) => day.day.isEven ? 2 : 0)) {
        final decoded = decodeReminderPayload(encodeReminderPayload(r))!;
        expect(decoded.kind, r.kind);
        expect(decoded.variant, r.variant);
        expect(decoded.missionNumber, r.missionNumber);
      }
      expect(decodeReminderPayload('nonsense'), isNull);
      expect(decodeReminderPayload('nudge:1'), isNull);
      expect(decodeReminderPayload('recallDue:x'), isNull);
    },
  );
}
