import 'calendar_day.dart';
import 'recall.dart';
import 'scoring.dart';
import 'skill.dart';

/// Progression (FR-16, FR-32, FR-42): XP, unlocked skills and the soft weekly goal, as pure
/// functions of what the player did. The app stores attempts and recall rounds; everything here
/// is recomputed from them, so it's the same on every device and after a restore.

/// XP for one mission attempt: a base for playing, half the score on top, and a bonus the first
/// time the mission is finished. A 0 still earns the base (showing up counts); a 100 on a first
/// clear earns 100.
///
/// ```text
/// xp = missionBaseXp + total ÷ 2 (rounded down) + (first clear ? firstClearBonusXp : 0)
/// ```
int missionXp({required int total, required bool firstClear}) =>
    missionBaseXp +
    total.clamp(0, maxMissionScore) ~/ missionScoreXpDivisor +
    (firstClear ? firstClearBonusXp : 0);

/// XP for playing a mission at all.
const int missionBaseXp = 20;

/// The score is worth half its points in XP.
const int missionScoreXpDivisor = 2;

/// The first finish of each mission is worth this much more.
const int firstClearBonusXp = 30;

/// XP for a Recall Room round: each card known after thinking earns [recallKnownXp], and every
/// other answer [recallTriedXp] (the effort of coming back counts; a guess isn't rewarded more
/// than a miss).
int recallXp(List<RecallVerdict> verdicts) => verdicts.fold(
  0,
  (sum, v) => sum + (v == RecallVerdict.known ? recallKnownXp : recallTriedXp),
);

const int recallKnownXp = 5;
const int recallTriedXp = 1;

/// One finished attempt, as progression needs it.
class PlayedMission {
  const PlayedMission({
    required this.missionId,
    required this.score,
    required this.hinted,
    required this.requirements,
  });

  final String missionId;
  final MissionScore score;
  final bool hinted;

  /// The mission's skill requirements (content).
  final List<SkillRequirement> requirements;
}

/// Total XP from every attempt, in the order they were played, plus [recallRoundXp] (the sum of
/// [recallXp] over the rounds played).
int totalXp(List<PlayedMission> attempts, {int recallRoundXp = 0}) {
  final cleared = <String>{};
  var xp = recallRoundXp;
  for (final a in attempts) {
    xp += missionXp(total: a.score.total, firstClear: cleared.add(a.missionId));
  }
  return xp;
}

/// The XP the last of [attempts] earned (the debrief's "+N"), or 0 with none.
int lastAttemptXp(List<PlayedMission> attempts) {
  if (attempts.isEmpty) return 0;
  final last = attempts.last;
  final before = attempts.take(attempts.length - 1).map((a) => a.missionId);
  return missionXp(
    total: last.score.total,
    firstClear: !before.contains(last.missionId),
  );
}

/// Every skill the player has demonstrated, attempt by attempt ([newlyUnlockedSkills]: only
/// unhinted attempts that reach a requirement). A skill, once unlocked, stays unlocked.
Set<Skill> unlockedSkills(List<PlayedMission> attempts) {
  final unlocked = <Skill>{};
  for (final a in attempts) {
    unlocked.addAll(
      newlyUnlockedSkills(
        score: a.score,
        hinted: a.hinted,
        requirements: a.requirements,
        alreadyUnlocked: unlocked,
      ),
    );
  }
  return unlocked;
}

/// The Monday that starts [day]'s week: the weekly goal resets then.
CalendarDay weekStart(CalendarDay day) =>
    day.addDays(-(day.weekday - DateTime.monday));

/// How many different days this week (Monday to [today]) the player practised: a mission or a
/// Recall Room round. Days played in other weeks don't count.
int sessionsThisWeek(
  Iterable<CalendarDay> playedDays, {
  required CalendarDay today,
}) {
  final start = weekStart(today);
  return {
    for (final d in playedDays)
      if (!d.isBefore(start) && !today.isBefore(d)) d,
  }.length;
}

/// The soft weekly goal when the player hasn't set one (FR-42: "3 sessions this week").
const int defaultWeeklyGoal = 3;
