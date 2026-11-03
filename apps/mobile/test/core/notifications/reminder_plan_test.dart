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

  test('never today; days 1, 3 and 5, then backing off to day 8', () {
    final days = [
      for (final r in plan()) r.at.difference(DateTime(2026, 11, 2)).inDays,
    ];
    expect(days, [1, 3, 5, 8]);
    expect(planDays, [1, 3, 5, 8]);
  });

  test(
    'installed and played on day 0, heard from on days 1, 3 and 5 (brief 42)',
    () {
      for (final day in [1, 3, 5]) {
        expect(planDays, contains(day));
      }
    },
  );

  test('backing off: the gaps between reminders never shrink', () {
    final gaps = [
      for (var i = 0; i < planDays.length; i++)
        planDays[i] - (i == 0 ? 0 : planDays[i - 1]),
    ];
    for (var i = 1; i < gaps.length; i++) {
      expect(gaps[i], greaterThanOrEqualTo(gaps[i - 1]), reason: '$gaps');
    }
    expect(gaps.last, greaterThan(gaps.first));
  });

  test('a nudge names who sends it; the Recall Room does not', () {
    expect(plan().first.interviewerId, 'priya');
    expect(plan(recallDue: (_) => 2).first.interviewerId, isNull);
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
    'cards due come first: "N notes are waiting", opening the Recall Room',
    () {
      final reminders = plan(recallDue: (day) => day.day >= 5 ? 3 : 0);
      expect(reminders.map((r) => r.kind), [
        ReminderKind.nudge,
        ReminderKind.recallDue,
        ReminderKind.recallDue,
        ReminderKind.recallDue,
      ]);
      final recall = reminders[1];
      expect(recall.title, ReminderCopy.recallTitle);
      expect(recall.body, contains('3 notes'));
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

  test('three wordings per kind, never the same one twice in a row', () {
    final bodies = plan().map((r) => r.body).toList();
    expect(bodies.toSet().length, greaterThanOrEqualTo(ReminderCopy.variants));
    for (var i = 1; i < bodies.length; i++) {
      expect(bodies[i], isNot(bodies[i - 1]));
    }
    for (final id in ['priya', 'marcus', 'lena', 'sam']) {
      final lines = {
        for (var v = 0; v < ReminderCopy.variants; v++)
          ReminderCopy.nudgeBody(id, v),
      };
      expect(lines, hasLength(ReminderCopy.variants), reason: id);
    }
    expect(
      ReminderCopy.recallBody(1, 0),
      '1 note is waiting in the Recall Room.',
    );
    // The Recall Room calls them notes; so does every reminder (QA 51).
    for (var v = 0; v < ReminderCopy.variants; v++) {
      for (final due in [1, 3]) {
        expect(ReminderCopy.recallBody(due, v), contains('note'));
        expect(ReminderCopy.recallBody(due, v), isNot(contains('trap')));
      }
    }
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

  test(
    'with an interview ahead, nudges count down to it; after it, they do not',
    () {
      final reminders = planReminders(
        now: afternoon,
        enabled: true,
        recallDue: none,
        nextMission: priyaNext,
        interviewDate: DateTime(2026, 11, 6),
      );
      // Days 1, 3, 5 and 8: 3 Nov, 5 Nov, 7 Nov, 10 Nov.
      expect(reminders[0].body, startsWith('3 days to your interview. '));
      expect(reminders[1].body, startsWith('Your interview is tomorrow. '));
      expect(reminders[2].body, ReminderCopy.nudgeBody('priya', 2));
      expect(reminders[3].body, ReminderCopy.nudgeBody('priya', 0));
      final onTheDay = planReminders(
        now: afternoon,
        enabled: true,
        recallDue: none,
        nextMission: priyaNext,
        interviewDate: DateTime(2026, 11, 5),
      );
      expect(onTheDay[1].body, startsWith('Interview day. '));
    },
  );
}
