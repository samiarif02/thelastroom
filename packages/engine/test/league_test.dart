import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// Wednesday 4 November 2026; its week starts Monday 2 November.
final wednesday = CalendarDay(2026, 11, 4);
final monday = CalendarDay(2026, 11, 2);

void main() {
  group('leagueFor', () {
    test('the thresholds: Bronze 0, Silver 500, Gold 1,200, Platinum 2,200, Diamond 3,500', () {
      expect(leagueFor(0), League.bronze);
      expect(leagueFor(499), League.bronze);
      expect(leagueFor(500), League.silver);
      expect(leagueFor(1199), League.silver);
      expect(leagueFor(1200), League.gold);
      expect(leagueFor(2199), League.gold);
      expect(leagueFor(2200), League.platinum);
      expect(leagueFor(3499), League.platinum);
      expect(leagueFor(3500), League.diamond);
      expect(leagueFor(1000000), League.diamond);
    });

    test('negative XP (never reported) is still Bronze', () {
      expect(leagueFor(-5), League.bronze);
    });

    test('more XP never means a lower league', () {
      var last = League.bronze;
      for (var xp = 0; xp <= 4000; xp += 7) {
        final league = leagueFor(xp);
        expect(league.index, greaterThanOrEqualTo(last.index));
        last = league;
      }
    });

    test('leagues climb in order, each one further than the last', () {
      for (final l in League.values.skip(1)) {
        expect(l.minXp, greaterThan(League.values[l.index - 1].minXp));
      }
      expect(League.bronze.next, League.silver);
      expect(League.diamond.next, isNull);
    });
  });

  group('xpToNextLeague', () {
    test('what is left to the next threshold', () {
      expect(xpToNextLeague(0), 500);
      expect(xpToNextLeague(940), 260);
      expect(xpToNextLeague(1199), 1);
      expect(xpToNextLeague(1200), 1000);
    });

    test('none in Diamond', () {
      expect(xpToNextLeague(3500), isNull);
      expect(xpToNextLeague(9000), isNull);
    });
  });

  group('leagueProgress', () {
    test('0 at a threshold, halfway in the middle, 1 in Diamond', () {
      expect(leagueProgress(500), 0);
      expect(leagueProgress(850), closeTo(0.5, 1e-9));
      expect(leagueProgress(1199), lessThan(1));
      expect(leagueProgress(3500), 1);
    });
  });

  group('weekXp', () {
    test('sums Monday to today', () {
      final earned = [
        DatedXp(monday, 40),
        DatedXp(wednesday, 62),
        DatedXp(monday.addDays(1), 5),
      ];
      expect(weekXp(earned, today: wednesday), 107);
    });

    test('last week (Sunday) and later days do not count', () {
      final earned = [
        DatedXp(monday.addDays(-1), 90),
        DatedXp(wednesday.addDays(1), 30),
        DatedXp(wednesday, 10),
      ];
      expect(weekXp(earned, today: wednesday), 10);
    });

    test('a new week starts at 0', () {
      expect(weekXp([DatedXp(wednesday, 50)], today: monday.addDays(7)), 0);
      expect(weekXp(const [], today: wednesday), 0);
    });
  });

  group('attemptXps', () {
    MissionScore score(int total) => MissionScore(
      dimensions: {for (final d in Dimension.values) d: total},
      total: total,
      optionIdsByCost: const [],
      flags: const {},
    );
    PlayedMission played(String id, int total) => PlayedMission(
      missionId: id,
      score: score(total),
      hinted: false,
      requirements: const [],
    );

    test('each attempt in order, a mission\'s first clear counted once', () {
      final attempts = [played('m1', 60), played('m1', 80), played('m2', 0)];
      expect(attemptXps(attempts).map((x) => x.total), [80, 60, 50]);
    });

    test('they add up to totalXp', () {
      final attempts = [played('m1', 60), played('m2', 90), played('m1', 10)];
      expect(
        attemptXps(attempts).fold(0, (s, x) => s + x.total) + 12,
        totalXp(attempts, recallRoundXp: 12),
      );
    });
  });

  group('weeksInARow', () {
    // Days played in the week starting [weeksAgo] Mondays before this one.
    List<CalendarDay> week(int weeksAgo, int days) => [
      for (var d = 0; d < days; d++) monday.addDays(-7 * weeksAgo + d),
    ];

    test('counts back from this week while each week met the goal', () {
      final days = [...week(0, 3), ...week(1, 3), ...week(2, 4), ...week(4, 3)];
      expect(weeksInARow(days, weeklyGoal: 3, today: wednesday), 3);
    });

    test('this week not met yet: last week\'s streak is still alive', () {
      final days = [...week(0, 1), ...week(1, 3), ...week(2, 3)];
      expect(weeksInARow(days, weeklyGoal: 3, today: wednesday), 2);
    });

    test('a missed week breaks it', () {
      final days = [...week(0, 3), ...week(2, 3)];
      expect(weeksInARow(days, weeklyGoal: 3, today: wednesday), 1);
    });

    test('two days in one week are two sessions; one day twice is one', () {
      final days = [monday, monday, monday.addDays(1)];
      expect(weeksInARow(days, weeklyGoal: 2, today: wednesday), 1);
      expect(weeksInARow([monday, monday], weeklyGoal: 2, today: wednesday), 0);
    });

    test('nothing played, or a goal under one session, is no streak', () {
      expect(weeksInARow(const [], weeklyGoal: 3, today: wednesday), 0);
      expect(weeksInARow(week(0, 3), weeklyGoal: 0, today: wednesday), 0);
    });

    test('the week runs Monday to Sunday', () {
      final sunday = monday.addDays(-1);
      expect(weeksInARow([sunday], weeklyGoal: 1, today: wednesday), 1);
      expect(weeksInARow([sunday], weeklyGoal: 1, today: monday.addDays(7)), 0);
    });
  });

  group('xpToPass', () {
    test('strictly more than the player above', () {
      expect(xpToPass(mine: 100, above: 139), 40);
      expect(xpToPass(mine: 120, above: 120), 1);
      expect(xpToPass(mine: 130, above: 120), 1);
    });
  });
}
