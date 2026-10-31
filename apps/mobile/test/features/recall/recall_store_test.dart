import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/features/recall/recall_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final schedule = RecallSchedule(
    cards: [
      RecallCard(
        cardId: 'trap_a',
        box: LeitnerBox.three,
        due: CalendarDay(2026, 11, 2),
      ),
      RecallCard(
        cardId: 'lesson_b',
        box: LeitnerBox.one,
        due: CalendarDay(2026, 10, 31),
      ),
    ],
    ingested: const {'m01#1', 'abc-123'},
  );

  void expectSame(RecallSchedule a, RecallSchedule b) {
    expect(a.cards, b.cards);
    expect(a.ingested, b.ingested);
  }

  test('a schedule survives JSON both ways', () {
    expectSame(RecallSchedule.fromJson(schedule.toJson()), schedule);
  });

  test('anything malformed is a FormatException, never a crash', () {
    for (final bad in <Object?>[
      null,
      'text',
      {'v': 2, 'cards': <Object?>[], 'ingested': <Object?>[]},
      {'v': 1},
      {
        'v': 1,
        'cards': [
          {'id': 'a', 'box': 'nine', 'due': '2026-10-31'},
        ],
        'ingested': <Object?>[],
      },
      {
        'v': 1,
        'cards': [
          {'id': 'a', 'box': 'one', 'due': 'tomorrow'},
        ],
        'ingested': <Object?>[],
      },
    ]) {
      expect(
        () => RecallSchedule.fromJson(bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });

  test('shared_preferences: empty on first run, then what was saved', () async {
    SharedPreferences.setMockInitialValues({});
    const store = SharedPreferencesRecallStore();
    expectSame(await store.load(), RecallSchedule.empty);
    await store.save(schedule);
    expectSame(await store.load(), schedule);
  });

  test('an attempt is keyed by its id, or its mission and number', () {
    expect(attemptKey('m01', 2, 'abc'), 'abc');
    expect(attemptKey('m01', 2, null), 'm01#2');
  });
}
