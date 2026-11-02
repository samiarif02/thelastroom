import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_store.dart';

MissionScore scoreOf(int each) => MissionScore(
  dimensions: {for (final d in Dimension.values) d: each},
  total: each,
  optionIdsByCost: const [],
  flags: const {},
);

AttemptRecord attempt(Mission m, int score, {int number = 1, DateTime? at}) =>
    AttemptRecord(
      missionId: m.id,
      attemptNumber: number,
      seed: 1,
      beatOptionIds: const [],
      followUpId: '',
      replyOptionId: '',
      score: scoreOf(score),
      hinted: m.hinted,
      completedAt: at,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wednesday 4 November 2026, 18:00.
  final now = DateTime(2026, 11, 4, 18);
  late InMemoryProgressRepository progress;
  late InMemoryProgressionStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    progress = InMemoryProgressRepository();
    store = InMemoryProgressionStore();
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: (_) {})),
        progressRepositoryProvider.overrideWithValue(progress),
        progressionStoreProvider.overrideWithValue(store),
        progressionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<Progression> read(ProviderContainer c) =>
      c.read(progressionProvider.future);

  test('a new player: no XP, no skills, a fresh week', () async {
    final p = await read(container());
    expect(p.xp, 0);
    expect(p.unlocked, isEmpty);
    expect(p.sessionsThisWeek, 0);
    expect(p.weeklyGoal, defaultWeeklyGoal);
  });

  test(
    'XP from missions, first clears included; +N is the last attempt',
    () async {
      await progress.recordAttempt(attempt(missionTheOpportunity, 40, at: now));
      await progress.recordAttempt(
        attempt(missionTheOpportunity, 60, number: 2, at: now),
      );
      final p = await read(container());
      expect(
        p.xp,
        missionXp(total: 40, firstClear: true) +
            missionXp(total: 60, firstClear: false),
      );
      expect(p.lastXp, missionXp(total: 60, firstClear: false));
    },
  );

  test(
    'a strong Mission 7 unlocks Evidence Builder, celebrated once',
    () async {
      final m7 = missions.firstWhere((m) => m.number == 7);
      await progress.recordAttempt(attempt(m7, 100, at: now));
      final c = container();
      final p = await read(c);
      expect(p.unlocked, contains(Skill.evidenceBuilder));
      expect(p.uncelebrated, contains(Skill.evidenceBuilder));

      await c.read(progressionActionsProvider).celebrate(p.uncelebrated);
      final after = await read(c);
      expect(after.unlocked, contains(Skill.evidenceBuilder));
      expect(after.uncelebrated, isEmpty);
    },
  );

  test('a hinted mission never unlocks, however strong', () async {
    final hinted = missions.firstWhere((m) => m.hinted);
    await progress.recordAttempt(attempt(hinted, 100, at: now));
    expect((await read(container())).unlocked, isEmpty);
  });

  test('a Recall Room round adds its XP and counts as a session', () async {
    final c = container();
    await c.read(progressionActionsProvider).recordRecallRound(const [
      RecallVerdict.known,
      RecallVerdict.missed,
    ]);
    final p = await read(c);
    expect(p.xp, recallKnownXp + recallTriedXp);
    expect(p.sessionsThisWeek, 1);
  });

  test('the weekly goal counts days this week, not last week', () async {
    await progress.recordAttempt(
      attempt(missionTheOpportunity, 50, at: DateTime(2026, 10, 30, 12)),
    );
    await progress.recordAttempt(
      attempt(
        missionTheOpportunity,
        50,
        number: 2,
        at: DateTime(2026, 11, 2, 9),
      ),
    );
    await progress.recordAttempt(
      attempt(
        missionTheOpportunity,
        50,
        number: 3,
        at: DateTime(2026, 11, 2, 21),
      ),
    );
    expect((await read(container())).sessionsThisWeek, 1);
  });

  test('the interview date is kept, and can be cleared', () async {
    final c = container();
    final actions = c.read(progressionActionsProvider);
    await actions.setInterviewDate(CalendarDay(2026, 11, 20));
    expect((await read(c)).interviewDate, CalendarDay(2026, 11, 20));
    await actions.setInterviewDate(null);
    expect((await read(c)).interviewDate, isNull);
  });

  group('the record on the device', () {
    final record = ProgressionRecord(
      recallXp: 12,
      recallDays: {CalendarDay(2026, 11, 2)},
      celebrated: const {Skill.evidenceBuilder},
      interviewDate: CalendarDay(2026, 11, 20),
    );

    test('survives JSON both ways', () {
      final back = ProgressionRecord.fromJson(record.toJson());
      expect(back.recallXp, 12);
      expect(back.recallDays, record.recallDays);
      expect(back.celebrated, record.celebrated);
      expect(back.interviewDate, record.interviewDate);
    });

    test('anything malformed is a FormatException', () {
      for (final bad in <Object?>[
        null,
        {'v': 2},
        {
          'v': 1,
          'recall_xp': 1,
          'recall_days': ['x'],
          'celebrated': <Object?>[],
        },
        {
          'v': 1,
          'recall_xp': 1,
          'recall_days': <Object?>[],
          'celebrated': ['flying'],
        },
      ]) {
        expect(() => ProgressionRecord.fromJson(bad), throwsFormatException);
      }
    });

    test(
      'an unreadable record counts as empty, and missions still score',
      () async {
        final c = ProviderContainer(
          overrides: [
            logProvider.overrideWithValue(Log(sink: (_) {})),
            progressRepositoryProvider.overrideWithValue(progress),
            progressionStoreProvider.overrideWithValue(_Corrupt()),
            progressionClockProvider.overrideWithValue(() => now),
          ],
        );
        addTearDown(c.dispose);
        await progress.recordAttempt(
          attempt(missionTheOpportunity, 50, at: now),
        );
        expect((await read(c)).xp, missionXp(total: 50, firstClear: true));
      },
    );
  });
}

class _Corrupt implements ProgressionStore {
  @override
  Future<ProgressionRecord> load() =>
      Future.error(const FormatException('corrupt'));

  @override
  Future<void> save(ProgressionRecord record) async {}
}
