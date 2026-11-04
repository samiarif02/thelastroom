import 'calendar_day.dart';
import 'progression.dart';

/// The leaderboard (issue 72): leagues by total XP, the week's XP and the weeks-in-a-row
/// streak, as pure functions. The app reports these numbers to the shared board; the board
/// ranks by them. Weeks here are whatever calendar the caller passes days in: the app passes
/// UTC days for the week's XP (one shared board) and local days for the streak (the same days
/// the weekly ring counts).

/// A league, by total XP. XP never goes down, so a player never drops a league.
enum League {
  bronze(0),
  silver(500),
  gold(1200),
  platinum(2200),
  diamond(3500);

  const League(this.minXp);

  /// The total XP that reaches this league.
  final int minXp;

  /// The league after this one, or null for [diamond].
  League? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// The league [totalXp] is in: the highest whose [League.minXp] it reaches.
League leagueFor(int totalXp) => League.values.lastWhere(
  (l) => totalXp >= l.minXp,
  orElse: () => League.bronze,
);

/// XP still needed to reach the next league ("260 XP to Gold"), or null in [League.diamond].
int? xpToNextLeague(int totalXp) {
  final next = leagueFor(totalXp).next;
  return next == null ? null : next.minXp - totalXp;
}

/// How far through its league [totalXp] is, 0 to 1 (the banner's bar). 1 in [League.diamond].
double leagueProgress(int totalXp) {
  final league = leagueFor(totalXp);
  final next = league.next;
  if (next == null) return 1;
  return (totalXp - league.minXp) / (next.minXp - league.minXp);
}

/// XP earned on one day.
class DatedXp {
  const DatedXp(this.day, this.xp);

  final CalendarDay day;
  final int xp;

  @override
  bool operator ==(Object other) =>
      other is DatedXp && other.day == day && other.xp == xp;

  @override
  int get hashCode => Object.hash(day, xp);

  @override
  String toString() => 'DatedXp($day, $xp)';
}

/// The XP earned this week: every [earned] from [today]'s Monday ([weekStart]) to [today].
/// Earlier weeks (and, defensively, days after [today]) don't count.
int weekXp(Iterable<DatedXp> earned, {required CalendarDay today}) {
  final start = weekStart(today);
  return earned.fold(
    0,
    (sum, e) =>
        !e.day.isBefore(start) && !today.isBefore(e.day) ? sum + e.xp : sum,
  );
}

/// Weeks in a row the weekly goal was met ([sessionsThisWeek] ≥ [weeklyGoal], a session being a
/// day played), counted back from [today]'s week. This week counts once it's met; until then
/// the streak is still alive from last week (there's time left), so it isn't broken on Monday.
int weeksInARow(
  Iterable<CalendarDay> playedDays, {
  required int weeklyGoal,
  required CalendarDay today,
}) {
  final days = playedDays.toSet();
  // A goal under one session would be met by every week ever: no streak to count.
  if (weeklyGoal < 1 || days.isEmpty) return 0;
  bool met(CalendarDay inWeek) =>
      sessionsThisWeek(
        days,
        today: weekStart(inWeek).addDays(_lastDayOfWeek),
      ) >=
      weeklyGoal;
  var week = weekStart(today);
  if (!met(week)) week = week.addDays(-_daysInWeek);
  var streak = 0;
  while (met(week)) {
    streak++;
    week = week.addDays(-_daysInWeek);
  }
  return streak;
}

const int _daysInWeek = 7;
const int _lastDayOfWeek = 6;

/// XP needed to pass a player on [above] XP from [mine] ("40 XP to pass Ali"): strictly more,
/// so at least 1, since a tie goes to whoever was there first.
int xpToPass({required int mine, required int above}) =>
    above < mine ? 1 : above - mine + 1;
