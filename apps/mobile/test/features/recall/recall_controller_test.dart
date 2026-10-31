import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/recall/recall_store.dart';

import 'recall_fixtures.dart';

class RecordingAnalytics implements Analytics {
  final List<(AnalyticsEvent, EventProperties)> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add((event, properties));

  Map<String, Object> last(AnalyticsEvent event) => {
    for (final e in events.lastWhere((e) => e.$1 == event).$2.entries)
      e.key: e.value.wire,
  };
}

void main() {
  late InMemoryProgressRepository progress;
  late InMemoryRecallStore store;
  late RecordingAnalytics analytics;
  late DateTime now;

  setUp(() {
    progress = InMemoryProgressRepository();
    store = InMemoryRecallStore();
    analytics = RecordingAnalytics();
    now = DateTime(2026, 10, 31, 18);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: (_) {})),
        analyticsProvider.overrideWithValue(analytics),
        progressRepositoryProvider.overrideWithValue(progress),
        recallStoreProvider.overrideWithValue(store),
        recallClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // Opens the room and waits for it to load.
  Future<RecallRoomState> open(ProviderContainer c) async {
    c.listen(recallRoomProvider, (_, _) {});
    while (c.read(recallRoomProvider) is RecallLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.read(recallRoomProvider);
  }

  Future<void> recordWeakOpenAndLand() => progress.recordAttempt(
    m1Attempt([
      weakOf(m1.beats[0]).$1,
      strongestOf(m1.beats[1]),
      weakOf(m1.beats[2]).$1,
    ]),
  );

  test('before any mistake the room has no cards and says so', () async {
    final state = await open(container());
    expect(state, isA<RecallEmpty>().having((s) => s.hasCards, 'cards', false));
    expect(analytics.last(AnalyticsEvent.recallRoomOpened), {'due_cards': 0});
  });

  test(
    'the traps of a mission come back straight away, in one round',
    () async {
      await recordWeakOpenAndLand();
      final state = await open(container());
      final playing = state as RecallPlaying;
      expect(playing.round.map((q) => q.cardId).toSet(), {
        weakOf(m1.beats[0]).$2.id,
        weakOf(m1.beats[2]).$2.id,
      });
      expect(playing.index, 0);
      expect(playing.streak, 0);
    },
  );

  test('right after thinking: known, promoted, the streak grows', () async {
    await recordWeakOpenAndLand();
    final c = container();
    final first = await open(c) as RecallPlaying;
    now = now.add(const Duration(seconds: 5));
    await c
        .read(recallRoomProvider.notifier)
        .answer(first.question.correctChoiceId);
    final answered = c.read(recallRoomProvider) as RecallPlaying;
    expect(answered.verdict, RecallVerdict.known);
    expect(answered.streak, 1);
    final saved = store.schedule.cards.firstWhere(
      (card) => card.cardId == first.question.cardId,
    );
    expect(saved.box, LeitnerBox.three);
    expect(analytics.last(AnalyticsEvent.recallCardAnswered), {
      'card_kind': 'trap',
      'verdict': 'known',
      'box': 'one',
    });
  });

  test(
    'right but under 1.5 s: a guess, the card stays and returns tomorrow',
    () async {
      await recordWeakOpenAndLand();
      final c = container();
      final first = await open(c) as RecallPlaying;
      now = now.add(const Duration(milliseconds: 400));
      await c
          .read(recallRoomProvider.notifier)
          .answer(first.question.correctChoiceId);
      final answered = c.read(recallRoomProvider) as RecallPlaying;
      expect(answered.verdict, RecallVerdict.guessed);
      expect(answered.streak, 0);
      final saved = store.schedule.cards.firstWhere(
        (card) => card.cardId == first.question.cardId,
      );
      expect(saved.box, LeitnerBox.one);
      expect(saved.due, CalendarDay(2026, 11, 1));
    },
  );

  test(
    'wrong: missed, back to box one, and a second tap changes nothing',
    () async {
      await recordWeakOpenAndLand();
      final c = container();
      final first = await open(c) as RecallPlaying;
      final wrong = first.question.choices
          .firstWhere((ch) => ch.id != first.question.correctChoiceId)
          .id;
      now = now.add(const Duration(seconds: 4));
      final room = c.read(recallRoomProvider.notifier);
      await room.answer(wrong);
      await room.answer(first.question.correctChoiceId);
      final answered = c.read(recallRoomProvider) as RecallPlaying;
      expect(answered.verdict, RecallVerdict.missed);
      expect(answered.verdicts, hasLength(1));
      expect(answered.chosenId, wrong);
    },
  );

  test('a whole round ends with its summary and one session event', () async {
    await recordWeakOpenAndLand();
    final c = container();
    final room = c.read(recallRoomProvider.notifier);
    RecallRoomState state = await open(c);
    while (state is RecallPlaying) {
      now = now.add(const Duration(seconds: 3));
      await room.answer(state.question.correctChoiceId);
      room.next();
      state = c.read<RecallRoomState>(recallRoomProvider);
    }
    final done = state as RecallFinished;
    expect(done.known, 2);
    expect(done.bestStreak, 2);
    expect(analytics.last(AnalyticsEvent.recallSessionCompleted), {
      'cards': 2,
      'correct': 2,
      'box_moves': 2,
    });
  });

  test(
    'reopening the room the same day does not count the attempt twice',
    () async {
      await recordWeakOpenAndLand();
      final c = container();
      final room = c.read(recallRoomProvider.notifier);
      RecallRoomState state = await open(c);
      while (state is RecallPlaying) {
        now = now.add(const Duration(seconds: 3));
        await room.answer(state.question.correctChoiceId);
        room.next();
        state = c.read<RecallRoomState>(recallRoomProvider);
      }
      final again = await open(container());
      expect(
        again,
        isA<RecallEmpty>().having((s) => s.hasCards, 'cards', true),
      );
      expect(store.schedule.cards, hasLength(2));
    },
  );

  test('the tower count is the cards due today', () async {
    await recordWeakOpenAndLand();
    final c = container();
    expect(await c.read(recallDueCountProvider.future), 2);
  });

  test(
    'a schedule that cannot be read: the room says so and logs a warning',
    () async {
      final records = <LogRecord>[];
      final c = ProviderContainer(
        overrides: [
          logProvider.overrideWithValue(Log(sink: records.add)),
          analyticsProvider.overrideWithValue(analytics),
          progressRepositoryProvider.overrideWithValue(progress),
          recallStoreProvider.overrideWithValue(_BrokenStore()),
          recallClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      expect(await open(c), isA<RecallUnavailable>());
      expect(records.single.level, LogLevel.warn);
    },
  );
}

class _BrokenStore implements RecallStore {
  @override
  Future<RecallSchedule> load() =>
      Future.error(const FormatException('corrupt'));

  @override
  Future<void> save(RecallSchedule schedule) async {}
}
