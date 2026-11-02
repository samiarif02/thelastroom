import 'package:engine/engine.dart';
import 'package:test/test.dart';

MissionScore scored(int total, {Map<Dimension, int>? dimensions}) =>
    MissionScore(
      dimensions: dimensions ?? {for (final d in Dimension.values) d: total},
      total: total,
      optionIdsByCost: const [],
      flags: const {},
    );

PlayedMission played(
  String id,
  int total, {
  bool hinted = false,
  List<SkillRequirement> requirements = const [],
  Map<Dimension, int>? dimensions,
}) => PlayedMission(
  missionId: id,
  score: scored(total, dimensions: dimensions),
  hinted: hinted,
  requirements: requirements,
);

const evidence = SkillRequirement(
  skill: Skill.evidenceBuilder,
  dimension: Dimension.specificity,
  minScore: 70,
);

void main() {
  group('missionXp', () {
    test('a base for playing, half the score, a bonus the first time', () {
      expect(missionXp(total: 0, firstClear: false), 20);
      expect(missionXp(total: 100, firstClear: false), 70);
      expect(missionXp(total: 100, firstClear: true), 100);
      expect(missionXp(total: 67, firstClear: true), 20 + 33 + 30);
    });

    test('never negative, never above a perfect first clear', () {
      for (var t = -10; t <= 120; t++) {
        final xp = missionXp(total: t, firstClear: true);
        expect(xp, inInclusiveRange(missionBaseXp + firstClearBonusXp, 100));
      }
    });

    test('a better score never earns less', () {
      for (var t = 0; t < 100; t++) {
        expect(
          missionXp(total: t + 1, firstClear: false),
          greaterThanOrEqualTo(missionXp(total: t, firstClear: false)),
        );
      }
    });
  });

  test('recall: 5 for a card known, 1 for any other answer', () {
    const k = RecallVerdict.known;
    const g = RecallVerdict.guessed;
    const m = RecallVerdict.missed;
    expect(recallXp([]), 0);
    expect(recallXp([k, k, g, m, k]), 5 + 5 + 1 + 1 + 5);
  });

  group('totalXp and lastAttemptXp', () {
    test('only the first finish of a mission gets the bonus', () {
      final attempts = [played('m1', 40), played('m1', 60), played('m2', 80)];
      expect(totalXp(attempts), (20 + 20 + 30) + (20 + 30) + (20 + 40 + 30));
      expect(totalXp(attempts, recallRoundXp: 12), totalXp(attempts) + 12);
    });

    test("the debrief's +N is the last attempt's XP", () {
      expect(lastAttemptXp([]), 0);
      expect(lastAttemptXp([played('m1', 40)]), 20 + 20 + 30);
      expect(lastAttemptXp([played('m1', 40), played('m1', 60)]), 20 + 30);
    });
  });

  group('unlockedSkills', () {
    test(
      'a skill unlocks when an unhinted attempt reaches its requirement',
      () {
        final attempts = [
          played(
            'm7',
            60,
            requirements: [evidence],
            dimensions: {for (final d in Dimension.values) d: 60},
          ),
          played('m7', 80, requirements: [evidence]),
        ];
        expect(unlockedSkills(attempts.take(1).toList()), isEmpty);
        expect(unlockedSkills(attempts), {Skill.evidenceBuilder});
      },
    );

    test('a hinted attempt never unlocks, however good', () {
      expect(
        unlockedSkills([
          played('m4', 100, hinted: true, requirements: [evidence]),
        ]),
        isEmpty,
      );
    });

    test('once unlocked, a weaker attempt later keeps it', () {
      expect(
        unlockedSkills([
          played('m7', 90, requirements: [evidence]),
          played('m7', 10, requirements: [evidence]),
        ]),
        {Skill.evidenceBuilder},
      );
    });
  });

  group('the weekly goal', () {
    // Wednesday 4 November 2026.
    final wednesday = CalendarDay(2026, 11, 4);

    test('the week starts on Monday', () {
      expect(weekStart(wednesday), CalendarDay(2026, 11, 2));
      expect(weekStart(CalendarDay(2026, 11, 2)), CalendarDay(2026, 11, 2));
      expect(weekStart(CalendarDay(2026, 11, 8)), CalendarDay(2026, 11, 2));
    });

    test(
      'counts different days this week, not games, and resets on Monday',
      () {
        final days = [
          CalendarDay(2026, 10, 31), // last Saturday: last week
          CalendarDay(2026, 11, 2),
          CalendarDay(2026, 11, 2), // a second game the same day
          CalendarDay(2026, 11, 4),
          CalendarDay(2026, 11, 5), // tomorrow: not yet
        ];
        expect(sessionsThisWeek(days, today: wednesday), 2);
        expect(sessionsThisWeek(days, today: CalendarDay(2026, 11, 9)), 0);
        expect(defaultWeeklyGoal, 3);
      },
    );
  });

  test('days until a later day, across a month end', () {
    expect(CalendarDay(2026, 10, 30).daysUntil(CalendarDay(2026, 11, 2)), 3);
    expect(CalendarDay(2026, 11, 2).daysUntil(CalendarDay(2026, 11, 2)), 0);
    expect(CalendarDay(2026, 11, 2).daysUntil(CalendarDay(2026, 11, 1)), -1);
    expect(CalendarDay(2026, 11, 4).weekday, DateTime.wednesday);
  });
}
