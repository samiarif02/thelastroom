import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/profile/profile_repository.dart';
import '../../core/progress/progress_repository.dart';
import 'progression_store.dart';

/// Where the player stands (FR-16, FR-32, FR-42), recomputed from the stored attempts and the
/// [ProgressionRecord]: the engine's pure rules do the arithmetic.
class Progression {
  const Progression({
    required this.xp,
    required this.lastXp,
    required this.unlocked,
    required this.uncelebrated,
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    this.interviewDate,
  });

  final int xp;

  /// What the latest mission attempt earned (the debrief's "+N XP").
  final int lastXp;
  final Set<Skill> unlocked;

  /// Unlocked but not yet celebrated: the debrief shows each one's card once.
  final Set<Skill> uncelebrated;
  final int sessionsThisWeek;
  final int weeklyGoal;
  final CalendarDay? interviewDate;

  bool get goalMet => sessionsThisWeek >= weeklyGoal;

  static const Progression empty = Progression(
    xp: 0,
    lastXp: 0,
    unlocked: {},
    uncelebrated: {},
    sessionsThisWeek: 0,
    weeklyGoal: defaultWeeklyGoal,
  );
}

/// The device's clock, read here only. Tests pin it.
final progressionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

CalendarDay dayOf(DateTime t) => CalendarDay(t.year, t.month, t.day);

/// The player's progression. A record that can't be read counts as empty (and is logged): XP
/// and skills from missions still show, because they come from the attempts.
final progressionProvider = FutureProvider.autoDispose<Progression>((
  ref,
) async {
  final today = dayOf(ref.watch(progressionClockProvider)());
  final record = await loadProgressionRecord(ref);
  final stored = await ref.watch(progressRepositoryProvider).attempts();
  final played = [
    for (final a in stored)
      if (missions.where((m) => m.id == a.missionId).firstOrNull case final m?)
        PlayedMission(
          missionId: a.missionId,
          score: a.score,
          hinted: a.hinted,
          requirements: m.skillRequirements,
        ),
  ];
  final unlocked = unlockedSkills(played);
  final days = {
    ...record.recallDays,
    for (final a in stored) dayOf((a.completedAt ?? DateTime.now()).toLocal()),
  };
  final profile = ref.watch(profileProvider).value;
  return Progression(
    xp: totalXp(played, recallRoundXp: record.recallXp),
    lastXp: lastAttemptXp(played),
    unlocked: unlocked,
    uncelebrated: unlocked.difference(record.celebrated),
    sessionsThisWeek: sessionsThisWeek(days, today: today),
    weeklyGoal: profile?.weeklyGoal ?? defaultWeeklyGoal,
    interviewDate: record.interviewDate,
  );
});

/// The saved record, or an empty one if it can't be read (malformed, or the store failing):
/// progression never blocks a screen or a reminder.
Future<ProgressionRecord> loadProgressionRecord(Ref ref) async {
  final store = ref.read(progressionStoreProvider);
  try {
    return await store.load();
  } on Object catch (e) {
    if (ref.mounted) {
      ref.read(logProvider).warn('progression record unreadable', {
        'error': e.runtimeType.toString(),
      });
    }
    return ProgressionRecord.empty;
  }
}

final progressionActionsProvider = Provider<ProgressionActions>(
  ProgressionActions.new,
);

/// The few things that change the record: a Recall Room round, a celebrated unlock, the
/// interview date. Each saves, then refreshes [progressionProvider]. A failed save is logged,
/// never shown.
class ProgressionActions {
  ProgressionActions(this._ref);

  final Ref _ref;

  Future<void> recordRecallRound(List<RecallVerdict> verdicts) => _change(
    (r) => r.copyWith(
      recallXp: r.recallXp + recallXp(verdicts),
      recallDays: {...r.recallDays, _today},
    ),
  );

  Future<void> celebrate(Iterable<Skill> skills) =>
      _change((r) => r.copyWith(celebrated: {...r.celebrated, ...skills}));

  Future<void> setInterviewDate(CalendarDay? day) =>
      _change((r) => r.copyWith(interviewDate: () => day));

  CalendarDay get _today => dayOf(_ref.read(progressionClockProvider)());

  Future<void> _change(
    ProgressionRecord Function(ProgressionRecord) change,
  ) async {
    // Every await can outlive the container (a test ending, the app closing): check before
    // touching the ref again.
    final store = _ref.read(progressionStoreProvider);
    try {
      final record = await loadProgressionRecord(_ref);
      if (!_ref.mounted) return;
      await store.save(change(record));
    } on Object catch (e) {
      if (!_ref.mounted) return;
      _ref.read(logProvider).warn('progression not saved', {
        'error': e.runtimeType.toString(),
      });
    }
    if (_ref.mounted) _ref.invalidate(progressionProvider);
  }
}
