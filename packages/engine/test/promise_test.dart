import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  // A Wednesday.
  final today = CalendarDay(2026, 11, 4);
  final tomorrow = today.addDays(1);

  RecallCard card(String id, LeitnerBox box, CalendarDay due) =>
      RecallCard(cardId: id, box: box, due: due);

  group('nextRecallDay', () {
    test('no cards: no day', () {
      expect(nextRecallDay(const [], today: today), isNull);
    });

    test('a card due today or overdue comes back tomorrow, never today', () {
      expect(
        nextRecallDay([card('a', LeitnerBox.one, today)], today: today),
        tomorrow,
      );
      expect(
        nextRecallDay([
          card('a', LeitnerBox.one, today.addDays(-3)),
        ], today: today),
        tomorrow,
      );
    });

    test('otherwise the earliest due day', () {
      expect(
        nextRecallDay([
          card('a', LeitnerBox.seven, today.addDays(7)),
          card('b', LeitnerBox.three, today.addDays(3)),
        ], today: today),
        today.addDays(3),
      );
    });
  });

  test('notesDueBy counts every card due on or before the day', () {
    final cards = [
      card('a', LeitnerBox.one, today),
      card('b', LeitnerBox.three, today.addDays(3)),
      card('c', LeitnerBox.seven, today.addDays(7)),
    ];
    expect(notesDueBy(cards, tomorrow), 1);
    expect(notesDueBy(cards, today.addDays(3)), 2);
    expect(notesDueBy(cards, today.addDays(30)), 3);
  });

  group('promiseAfterRoom', () {
    test("a room's new mistakes (due today) come back tomorrow", () {
      final cards = withMissedCards(const [], [
        'trap_a',
        'trap_b',
      ], today: today);
      expect(
        promiseAfterRoom(
          cards: cards,
          roomCardIds: ['trap_a', 'trap_b'],
          today: today,
          nextRoom: 2,
        ),
        RecallPromise(
          day: tomorrow,
          daysAhead: 1,
          notes: 2,
          fromThisRoom: true,
          nextRoom: 2,
        ),
      );
    });

    test("only this room's notes are counted, not earlier ones", () {
      final cards = [
        card('old', LeitnerBox.one, today),
        ...withMissedCards(const [], ['trap_a'], today: today),
      ];
      final p = promiseAfterRoom(
        cards: cards,
        roomCardIds: ['trap_a'],
        today: today,
        nextRoom: 4,
      );
      expect(p, isA<RecallPromise>());
      expect((p as RecallPromise).notes, 1);
      expect(p.fromThisRoom, isTrue);
    });

    test('a room card already practised today promises its box date', () {
      // Missed, then known in the Recall Room the same day: box three, due in 3 days. The
      // debrief of a replay that earns it again is the other case; here only the schedule
      // decides, so a Saturday it is.
      final known = reviewRecallCard(
        newRecallCard('trap_a', today: today),
        correct: true,
        today: today,
        decidedIn: const Duration(seconds: 4),
      );
      final cards = [(known as Rescheduled).card];
      final p = promiseAfterRoom(
        cards: cards,
        roomCardIds: ['trap_a'],
        today: today,
        nextRoom: 2,
      );
      expect(
        p,
        RecallPromise(
          day: CalendarDay(2026, 11, 7),
          daysAhead: 3,
          notes: 1,
          fromThisRoom: true,
          nextRoom: 2,
        ),
      );
      expect(CalendarDay(2026, 11, 7).weekday, DateTime.saturday);
    });

    test('a clean room promises the next room, whatever else is waiting', () {
      final cards = [card('old', LeitnerBox.three, today.addDays(2))];
      expect(
        promiseAfterRoom(
          cards: cards,
          roomCardIds: const [],
          today: today,
          nextRoom: 5,
        ),
        const NextRoomPromise(nextRoom: 5),
      );
    });

    test('a clean last room promises the earlier notes still waiting', () {
      final cards = [
        card('old', LeitnerBox.seven, today.addDays(6)),
        card('older', LeitnerBox.seven, today.addDays(9)),
      ];
      expect(
        promiseAfterRoom(cards: cards, roomCardIds: const [], today: today),
        RecallPromise(
          day: today.addDays(6),
          daysAhead: 6,
          notes: 1,
          fromThisRoom: false,
        ),
      );
    });

    test('nothing at all: every room is done, nothing to bring back', () {
      expect(
        promiseAfterRoom(cards: const [], roomCardIds: const [], today: today),
        const NextRoomPromise(),
      );
    });

    test('a mistake with no card (retired content) promises the next room', () {
      expect(
        promiseAfterRoom(
          cards: const [],
          roomCardIds: ['gone'],
          today: today,
          nextRoom: 3,
        ),
        const NextRoomPromise(nextRoom: 3),
      );
    });

    test('the same inputs give the same promise (reproducible offline)', () {
      final cards = withMissedCards(const [], ['trap_a'], today: today);
      RoomPromise p() => promiseAfterRoom(
        cards: cards,
        roomCardIds: ['trap_a'],
        today: today,
        nextRoom: 2,
      );
      expect(p(), p());
      expect(p().hashCode, p().hashCode);
    });

    test('across a month end and a clock change, days stay whole', () {
      // 31 October 2026 → 1 November: the UK clocks go back on 25 October, the US on
      // 1 November. CalendarDay counts days, not hours.
      final saturday = CalendarDay(2026, 10, 31);
      final p = promiseAfterRoom(
        cards: withMissedCards(const [], ['t'], today: saturday),
        roomCardIds: ['t'],
        today: saturday,
      );
      expect((p as RecallPromise).day, CalendarDay(2026, 11, 1));
      expect(p.daysAhead, 1);
    });
  });
}
