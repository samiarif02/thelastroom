import 'calendar_day.dart';
import 'reason_verdict.dart';
import 'recall.dart';
import 'scoring.dart';
import 'skill.dart';

/// Progression (FR-16, FR-32, FR-42): XP, unlocked skills and the soft weekly goal, as pure
/// functions of what the player did. The app stores attempts and recall rounds; everything here
/// is recomputed from them, so it's the same on every device and after a restore.

/// The room XP for one mission attempt: a base for playing, half the score on top, and a bonus the first
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

/// XP for the explaining in one attempt (brief 55): each "why that line?" earns its
/// [ReasonVerdict.xp] (sound [reasonSoundXp], close [reasonCloseXp], a guess 0; a built beat
/// asks no why and earns nothing), and each point a spoken answer makes earns [voicePointXp].
///
/// ```text
/// reasonXp = Σ verdict.xp over the beats that asked why + pointsMade × voicePointXp
/// ```
///
/// A pure function of the attempt's final picks (stored, never the XP itself), so it's the
/// same after a resume, a restore or a rescore, and an attempt stored before wave 5 (no
/// reasons) earns 0 here and exactly its room XP, as before.
int reasonXp(MissionScore score) =>
    score.reasonVerdicts.fold(0, (sum, v) => sum + v.xp) +
    score.pointsMade * voicePointXp;

/// What one attempt earned, in its two parts: the debrief's "+62 XP · 40 for the room, 22 for
/// your reasons".
class AttemptXp {
  const AttemptXp({required this.room, required this.reasons});

  /// [missionXp]: playing, the score, a first clear.
  final int room;

  /// [reasonXp]: the reasons given, or the points said out loud.
  final int reasons;

  int get total => room + reasons;

  static const AttemptXp none = AttemptXp(room: 0, reasons: 0);

  @override
  bool operator ==(Object other) =>
      other is AttemptXp && other.room == room && other.reasons == reasons;

  @override
  int get hashCode => Object.hash(room, reasons);

  @override
  String toString() => 'AttemptXp(room: $room, reasons: $reasons)';
}

/// [attempt]'s XP: [missionXp] for the room plus [reasonXp].
AttemptXp attemptXp(PlayedMission attempt, {required bool firstClear}) =>
    AttemptXp(
      room: missionXp(total: attempt.score.total, firstClear: firstClear),
      reasons: reasonXp(attempt.score),
    );

/// Total XP from every attempt, in the order they were played (each [attemptXp]: the room and
/// its reasons), plus [recallRoundXp] (the sum of [recallXp] over the rounds played). Every term
/// is zero or more, so playing more never lowers it.
int totalXp(List<PlayedMission> attempts, {int recallRoundXp = 0}) =>
    attemptXps(attempts).fold(recallRoundXp, (sum, xp) => sum + xp.total);

/// What each of [attempts] earned, in the order they were played: [attemptXp], with the first
/// clear of each mission counted once. The leaderboard dates each one to sum a week.
List<AttemptXp> attemptXps(List<PlayedMission> attempts) {
  final cleared = <String>{};
  return [
    for (final a in attempts)
      attemptXp(a, firstClear: cleared.add(a.missionId)),
  ];
}

/// What the last of [attempts] earned (the debrief's "+N", and its breakdown), or
/// [AttemptXp.none] with none.
AttemptXp lastAttemptXp(List<PlayedMission> attempts) {
  if (attempts.isEmpty) return AttemptXp.none;
  final last = attempts.last;
  final before = attempts.take(attempts.length - 1).map((a) => a.missionId);
  return attemptXp(last, firstClear: !before.contains(last.missionId));
}

/// Every skill the player has demonstrated, attempt by attempt ([newlyUnlockedSkills]: only
/// unhinted attempts that reach a requirement). A skill, once unlocked, stays unlocked.
///
/// Skills read dimension scores, never XP. XP is shown and summed, never a gate: rooms and
/// floors open by clearing the room before, and the weekly goal counts days. So reason XP
/// (brief 55) moves no unlock.
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
