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

MissionScore scoreOf(
  int each, {
  List<ReasonVerdict> reasons = const [],
  int pointsMade = 0,
}) => MissionScore(
  dimensions: {for (final d in Dimension.values) d: each},
  total: each,
  optionIdsByCost: const [],
  flags: const {},
  reasonVerdicts: reasons,
  pointsMade: pointsMade,
);

AttemptRecord attempt(
  Mission m,
  int score, {
  int number = 1,
  DateTime? at,
  List<ReasonVerdict> reasons = const [],
  int pointsMade = 0,
}) => AttemptRecord(
  missionId: m.id,
  attemptNumber: number,
  seed: 1,
  beatOptionIds: const [],
  followUpId: '',
  replyOptionId: '',
  score: scoreOf(score, reasons: reasons, pointsMade: pointsMade),
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

  test('reason XP is in the total and the +N, and its part is kept apart (brief 55)', () async {
    const reasons = [
      ReasonVerdict.sound,
      ReasonVerdict.close,
      ReasonVerdict.guessed,
    ];
    await progress.recordAttempt(
      attempt(missionTheOpportunity, 40, at: now, reasons: reasons),
    );
    await progress.recordAttempt(
      attempt(
        missionTheOpportunity,
        60,
        number: 2,
        at: now,
        reasons: const [ReasonVerdict.sound, ReasonVerdict.sound],
      ),
    );
    final p = await read(container());
    expect(
      p.xp,
      missionXp(total: 40, firstClear: true) +
          15 +
          missionXp(total: 60, firstClear: false) +
          20,
    );
    expect(p.lastXp, missionXp(total: 60, firstClear: false) + 20);
    expect(p.lastReasonXp, 20);
    expect(p.lastRoomXp, missionXp(total: 60, firstClear: false));
  });

  test('reason XP moves no unlock: skills read dimension scores only', () async {
    final m7 = missions.firstWhere((m) => m.number == 7);
    // Every reason sound, but the answer too weak for the skill: still locked.
    await progress.recordAttempt(
      attempt(
        m7,
        30,
        at: now,
        reasons: const [ReasonVerdict.sound, ReasonVerdict.sound],
      ),
    );
    final p = await read(container());
    expect(p.lastReasonXp, 20);
    expect(p.unlocked, isEmpty);
  });

  test('a voice room earns 5 per point said out loud', () async {
    final voice = missions.firstWhere((m) => m.voice != null);
    await progress.recordAttempt(attempt(voice, 50, at: now, pointsMade: 4));
    final p = await read(container());
    expect(p.lastReasonXp, 4 * voicePointXp);
    expect(p.xp, missionXp(total: 50, firstClear: true) + 20);
  });

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

  group('the leaderboard numbers (issue 72)', () {
    test('this UTC week\'s XP: rooms since Monday and Recall rounds', () async {
      // Last Sunday's room is last week; Monday's and today's count.
      await progress.recordAttempt(
        attempt(missionTheOpportunity, 40, at: DateTime.utc(2026, 11, 1, 12)),
      );
      await progress.recordAttempt(
        attempt(
          missionTheOpportunity,
          60,
          number: 2,
          at: DateTime.utc(2026, 11, 2, 8),
        ),
      );
      final c = container();
      await c.read(progressionActionsProvider).recordRecallRound(const [
        RecallVerdict.known,
        RecallVerdict.missed,
      ]);
      final p = await read(c);
      // The second play: 20 + 30, no first clear; the round: 5 + 1.
      expect(p.weekXp, 50 + 6);
      expect(p.weekStartUtc, CalendarDay(2026, 11, 2));
      expect(p.xp, greaterThan(p.weekXp));
    });

    test('weeks in a row: the ring closed last week and this week', () async {
      for (final day in [
        DateTime(2026, 10, 26, 9),
        DateTime(2026, 10, 27, 9),
        DateTime(2026, 10, 28, 9),
        DateTime(2026, 11, 2, 9),
        DateTime(2026, 11, 3, 9),
        DateTime(2026, 11, 4, 9),
      ]) {
        await progress.recordAttempt(
          attempt(missionTheOpportunity, 50, at: day),
        );
      }
      final p = await read(container());
      expect(p.weeksInARow, 2);
    });

    test('a record saved before issue 72 still reads (no recall by day)', () {
      final old = ProgressionRecord.fromJson({
        'v': 1,
        'recall_xp': 12,
        'recall_days': ['2026-11-01'],
        'celebrated': <String>[],
      });
      expect(old.recallXpByUtcDay, isEmpty);
      final now = old.copyWith(recallXpByUtcDay: {CalendarDay(2026, 11, 4): 6});
      expect(ProgressionRecord.fromJson(now.toJson()).recallXpByUtcDay, {
        CalendarDay(2026, 11, 4): 6,
      });
    });
  });
}

class _Corrupt implements ProgressionStore {
  @override
  Future<ProgressionRecord> load() =>
      Future.error(const FormatException('corrupt'));

  @override
  Future<void> save(ProgressionRecord record) async {}
}
