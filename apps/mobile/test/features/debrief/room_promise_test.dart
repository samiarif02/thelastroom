import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/notifications/reminders.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/promise_card.dart';
import 'package:the_last_room/features/debrief/room_promise.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/recall/recall_store.dart';

import '../../core/notifications/reminder_fakes.dart';
import '../../ui/harness.dart';
import '../recall/recall_fixtures.dart';

void main() {
  // Wednesday 4 November 2026, 18:00: the room finishes, the debrief promises.
  final now = DateTime(2026, 11, 4, 18);
  final today = CalendarDay(2026, 11, 4);

  group('the promise, from the real schedule (brief 61)', () {
    late InMemoryProgressRepository progress;
    late InMemoryRecallStore recall;

    ProviderContainer container() {
      progress = InMemoryProgressRepository();
      recall = InMemoryRecallStore();
      final c = ProviderContainer(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          analyticsProvider.overrideWithValue(RecordingAnalytics()),
          progressRepositoryProvider.overrideWithValue(progress),
          recallStoreProvider.overrideWithValue(recall),
          progressionStoreProvider.overrideWithValue(
            InMemoryProgressionStore(),
          ),
          recallClockProvider.overrideWithValue(() => now),
          reminderClockProvider.overrideWithValue(() => now),
          reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
          reminderSettingsStoreProvider.overrideWithValue(
            MemoryReminderStore(const ReminderSettings(enabled: true)),
          ),
          remindersSupportedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    AttemptRecord withTrap() {
      final (weak, _) = weakOf(m1.beats.first);
      return m1Attempt([
        weak,
        for (final b in m1.beats.skip(1)) strongestOf(b),
      ]);
    }

    test(
      'a trap in room 1: it comes back tomorrow, and room 2 opens now; the '
      "reminder plan's first day is a Recall reminder on that same day",
      () async {
        final c = container();
        await progress.recordAttempt(withTrap());
        final reading = await c.read(roomPromiseProvider(m1.id).future);
        final p = reading.promise as RecallPromise;
        expect(p.day, CalendarDay(2026, 11, 5));
        expect(p.daysAhead, 1);
        expect(p.fromThisRoom, isTrue);
        expect(p.nextRoom, 2);
        expect(reading.opensNow, isTrue);

        // The same schedule the reminders plan from: day 1 is that Thursday, and it's Recall.
        final plan = await c.read(remindersProvider).plan(enabled: true);
        final first = plan.first;
        expect(first.kind, ReminderKind.recallDue);
        expect(CalendarDay(first.at.year, first.at.month, first.at.day), p.day);
        expect(first.body, contains('${p.notes == 1 ? '1 note' : p.notes}'));
        expect(first.body, endsWith('Then room 2.'));
      },
    );

    test('the Recall Room agrees: the note is in it today, and in the '
        "schedule's next day", () async {
      final c = container();
      await progress.recordAttempt(withTrap());
      final reading = await c.read(roomPromiseProvider(m1.id).future);
      expect(await c.read(recallDueCountProvider.future), greaterThan(0));
      expect(
        await c.read(nextRecallDayProvider.future),
        (reading.promise as RecallPromise).day,
      );
    });

    test('a clean room: the next room, not a date', () async {
      final c = container();
      await progress.recordAttempt(
        m1Attempt([for (final b in m1.beats) strongestOf(b)]),
      );
      final reading = await c.read(roomPromiseProvider(m1.id).future);
      expect(reading.promise, const NextRoomPromise(nextRoom: 2));
      expect(reading.opensNow, isTrue);
    });

    test('a replay: the next room is next, not "opens now"', () async {
      final c = container();
      await progress.recordAttempt(
        m1Attempt([for (final b in m1.beats) strongestOf(b)]),
      );
      await progress.recordAttempt(withTrap().copyWithNumber(2));
      final reading = await c.read(roomPromiseProvider(m1.id).future);
      expect(reading.promise, isA<RecallPromise>());
      expect(reading.opensNow, isFalse);
    });
  });

  group('the copy, per case', () {
    test('day words: tomorrow, a weekday, a date a week on', () {
      expect(PromiseCopy.when(today.addDays(1), today), 'tomorrow');
      expect(PromiseCopy.when(today.addDays(2), today), 'on Friday');
      expect(
        PromiseCopy.when(today.addDays(7), today),
        'on Wednesday 11 November',
      );
      expect(
        PromiseCopy.recallKicker(today.addDays(1)),
        'Recall Room · Thursday 5 November',
      );
    });

    test('this line, these lines, your notes', () {
      RecallPromise p(int notes, {bool room = true}) => RecallPromise(
        day: today.addDays(2),
        daysAhead: 2,
        notes: notes,
        fromThisRoom: room,
      );
      expect(
        PromiseCopy.recallHeadline(p(1), keeper: 'Priya', today: today),
        'Priya will bring this line back on Friday.',
      );
      expect(
        PromiseCopy.recallHeadline(p(2), keeper: 'Marcus', today: today),
        'Marcus will bring these 2 lines back on Friday.',
      );
      expect(
        PromiseCopy.recallHeadline(
          p(3, room: false),
          keeper: 'Sam',
          today: today,
        ),
        'Sam will bring your 3 notes back on Friday.',
      );
      expect(PromiseCopy.nextRoomLine(4, opensNow: true), 'Room 4 opens now.');
      expect(PromiseCopy.nextRoomLine(4, opensNow: false), 'Room 4 is next.');
      expect(
        PromiseCopy.nextRoomLine(null, opensNow: false),
        'That was the last room.',
      );
    });

    final room2 = missionByNumber(2)!;
    final cases = <(String, RoomPromiseReading, List<String>)>[
      (
        'recall',
        RoomPromiseReading(
          promise: RecallPromise(
            day: today.addDays(1),
            daysAhead: 1,
            notes: 1,
            fromThisRoom: true,
            nextRoom: 2,
          ),
          today: today,
          opensNow: true,
        ),
        [
          'Priya will bring this line back tomorrow.',
          'Room 2 opens now.',
          'Recall Room · Thursday 5 November',
        ],
      ),
      (
        'next room',
        RoomPromiseReading(
          promise: const NextRoomPromise(nextRoom: 2),
          today: today,
          opensNow: true,
        ),
        [
          'Up next · room 2',
          'Room 2 opens now.',
          PromiseCopy.cleanDetail(room2.lead.name),
        ],
      ),
      (
        'every room done',
        RoomPromiseReading(
          promise: const NextRoomPromise(),
          today: today,
          opensNow: false,
        ),
        [PromiseCopy.doneHeadline, PromiseCopy.doneDetail],
      ),
    ];
    for (final (name, reading, lines) in cases) {
      for (final (scale, still) in [(1.0, false), (2.0, true)]) {
        testWidgets(
          'the card: $name (text ${scale}x, reduced motion: $still)',
          (tester) async {
            await pumpKit(
              tester,
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PromiseCardView(reading: reading, keeper: m1.lead),
              ),
              textScale: scale,
              reduceMotion: still,
            );
            await pumpThrough(tester, const Duration(seconds: 1));
            for (final line in lines) {
              expect(find.text(line), findsOneWidget, reason: line);
            }
          },
        );
      }
    }
  });
}

extension on AttemptRecord {
  AttemptRecord copyWithNumber(int n) => AttemptRecord(
    missionId: missionId,
    attemptNumber: n,
    seed: seed,
    beatOptionIds: beatOptionIds,
    followUpId: followUpId,
    replyOptionId: replyOptionId,
    score: score,
    hinted: hinted,
  );
}
