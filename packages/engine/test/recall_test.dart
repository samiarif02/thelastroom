import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  final today = CalendarDay(2026, 10, 29);

  RecallCard card(String id, LeitnerBox box, CalendarDay due) =>
      RecallCard(lessonId: id, box: box, due: due);

  RecallCard rescheduled(RecallOutcome outcome) => switch (outcome) {
    Rescheduled(:final card) => card,
    Retired() => fail('expected the card to stay, but it retired'),
  };

  test('a new card goes in box one, due tomorrow', () {
    final c = newRecallCard('lesson_a', today: today);
    expect(c.lessonId, 'lesson_a');
    expect(c.box, LeitnerBox.one);
    expect(c.due, CalendarDay(2026, 10, 30));
  });

  group('reviewRecallCard', () {
    test('correct moves one → three, due in 3 days', () {
      final c = rescheduled(
        reviewRecallCard(
          card('l', LeitnerBox.one, today),
          correct: true,
          today: today,
        ),
      );
      expect(c.box, LeitnerBox.three);
      expect(c.due, CalendarDay(2026, 11, 1));
    });

    test('correct moves three → seven, due in 7 days', () {
      final c = rescheduled(
        reviewRecallCard(
          card('l', LeitnerBox.three, today),
          correct: true,
          today: today,
        ),
      );
      expect(c.box, LeitnerBox.seven);
      expect(c.due, CalendarDay(2026, 11, 5));
    });

    test('correct from box seven retires the card', () {
      final outcome = reviewRecallCard(
        card('l', LeitnerBox.seven, today),
        correct: true,
        today: today,
      );
      expect(outcome, isA<Retired>().having((r) => r.lessonId, 'id', 'l'));
    });

    test('wrong sends any box back to one, due tomorrow', () {
      for (final box in LeitnerBox.values) {
        final c = rescheduled(
          reviewRecallCard(
            card('l', box, today.addDays(-3)),
            correct: false,
            today: today,
          ),
        );
        expect(c.box, LeitnerBox.one);
        expect(c.due, today.addDays(1));
        expect(c.lessonId, 'l');
      }
    });

    test('the new due day counts from the review, not the old due day', () {
      final late = rescheduled(
        reviewRecallCard(
          card('l', LeitnerBox.one, today.addDays(-10)),
          correct: true,
          today: today,
        ),
      );
      expect(late.due, today.addDays(3));
    });
  });

  group('dueRecallCards', () {
    final cards = [
      card('future', LeitnerBox.one, today.addDays(1)),
      card('today_seven', LeitnerBox.seven, today),
      card('today_one_b', LeitnerBox.one, today),
      card('today_one_a', LeitnerBox.one, today),
      card('overdue', LeitnerBox.three, today.addDays(-2)),
    ];

    test('due on or before today: most overdue, then lowest box, then id', () {
      expect(dueRecallCards(cards, today: today).map((c) => c.lessonId), [
        'overdue',
        'today_one_a',
        'today_one_b',
        'today_seven',
      ]);
    });

    test('at most the limit, six by default', () {
      final many = [
        for (var i = 0; i < 10; i++)
          card('lesson_$i', LeitnerBox.one, today.addDays(-i)),
      ];
      expect(dueRecallCards(many, today: today), hasLength(6));
      expect(
        dueRecallCards(many, today: today, limit: 2).map((c) => c.lessonId),
        ['lesson_9', 'lesson_8'],
      );
      expect(recallSessionCardLimit, 6);
    });

    test('nothing due, nothing returned; a negative limit is a bug', () {
      expect(dueRecallCards(cards, today: today.addDays(-5)), isEmpty);
      expect(
        () => dueRecallCards(cards, today: today, limit: -1),
        throwsRangeError,
      );
    });
  });
}
