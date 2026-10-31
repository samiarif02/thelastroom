import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  final today = CalendarDay(2026, 10, 29);
  const thinking = Duration(seconds: 4);
  const instant = Duration(milliseconds: 600);

  RecallCard card(String id, LeitnerBox box, CalendarDay due) =>
      RecallCard(cardId: id, box: box, due: due);

  RecallCard rescheduled(RecallOutcome outcome) => switch (outcome) {
    Rescheduled(:final card) => card,
    Retired() => fail('expected the card to stay, but it retired'),
  };

  test('a new card goes in box one, due the same day', () {
    final c = newRecallCard('trap_a', today: today);
    expect(c, card('trap_a', LeitnerBox.one, today));
  });

  group('judgeRecall', () {
    test('wrong is missed, however long it took', () {
      expect(judgeRecall(correct: false), RecallVerdict.missed);
      expect(
        judgeRecall(correct: false, decidedIn: thinking),
        RecallVerdict.missed,
      );
    });

    test('right after reading is known; right under 1.5 s is a guess', () {
      expect(
        judgeRecall(correct: true, decidedIn: thinking),
        RecallVerdict.known,
      );
      expect(
        judgeRecall(correct: true, decidedIn: instant),
        RecallVerdict.guessed,
      );
      expect(
        judgeRecall(correct: true, decidedIn: guessThreshold),
        RecallVerdict.known,
      );
      // Not measured: counted as read, as with a mission beat.
      expect(judgeRecall(correct: true), RecallVerdict.known);
    });
  });

  group('reviewRecallCard', () {
    test('known moves one → three, due in 3 days', () {
      final outcome = reviewRecallCard(
        card('l', LeitnerBox.one, today),
        correct: true,
        today: today,
        decidedIn: thinking,
      );
      expect(outcome.verdict, RecallVerdict.known);
      expect(
        rescheduled(outcome),
        card('l', LeitnerBox.three, CalendarDay(2026, 11, 1)),
      );
    });

    test('known moves three → seven, due in 7 days', () {
      final c = rescheduled(
        reviewRecallCard(
          card('l', LeitnerBox.three, today),
          correct: true,
          today: today,
        ),
      );
      expect(c, card('l', LeitnerBox.seven, CalendarDay(2026, 11, 5)));
    });

    test('known from box seven retires the card', () {
      final outcome = reviewRecallCard(
        card('l', LeitnerBox.seven, today),
        correct: true,
        today: today,
      );
      expect(outcome, isA<Retired>().having((r) => r.cardId, 'id', 'l'));
      expect(outcome.verdict, RecallVerdict.known);
    });

    test('missed sends any box back to one, due tomorrow', () {
      for (final box in LeitnerBox.values) {
        final outcome = reviewRecallCard(
          card('l', box, today.addDays(-3)),
          correct: false,
          today: today,
          decidedIn: thinking,
        );
        expect(outcome.verdict, RecallVerdict.missed);
        expect(
          rescheduled(outcome),
          card('l', LeitnerBox.one, today.addDays(1)),
        );
      }
    });

    test('a guessed right answer stays in its box, due tomorrow', () {
      for (final box in LeitnerBox.values) {
        final outcome = reviewRecallCard(
          card('l', box, today),
          correct: true,
          today: today,
          decidedIn: instant,
        );
        expect(outcome.verdict, RecallVerdict.guessed);
        expect(rescheduled(outcome), card('l', box, today.addDays(1)));
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

  group('withMissedCards', () {
    test('a new mistake gets a new card, due today', () {
      expect(withMissedCards([], ['trap_a', 'trap_b'], today: today), [
        card('trap_a', LeitnerBox.one, today),
        card('trap_b', LeitnerBox.one, today),
      ]);
    });

    test('making a mistake again puts its card back in box one', () {
      final cards = [
        card('trap_a', LeitnerBox.seven, today.addDays(5)),
        card('trap_b', LeitnerBox.three, today.addDays(2)),
        card('overdue', LeitnerBox.three, today.addDays(-2)),
      ];
      expect(
        withMissedCards(cards, ['trap_a', 'overdue', 'trap_a'], today: today),
        [
          card('trap_a', LeitnerBox.one, today),
          card('trap_b', LeitnerBox.three, today.addDays(2)),
          // Already overdue: stays overdue, so it comes first.
          card('overdue', LeitnerBox.one, today.addDays(-2)),
        ],
      );
    });

    test('no mistakes, no change', () {
      final cards = [card('a', LeitnerBox.three, today)];
      expect(withMissedCards(cards, const [], today: today), cards);
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
      expect(dueRecallCards(cards, today: today).map((c) => c.cardId), [
        'overdue',
        'today_one_a',
        'today_one_b',
        'today_seven',
      ]);
    });

    test('at most the limit, five by default (a one-minute round)', () {
      final many = [
        for (var i = 0; i < 10; i++)
          card('card_$i', LeitnerBox.one, today.addDays(-i)),
      ];
      expect(dueRecallCards(many, today: today), hasLength(5));
      expect(
        dueRecallCards(many, today: today, limit: 2).map((c) => c.cardId),
        ['card_9', 'card_8'],
      );
      expect(recallSessionCardLimit, 5);
    });

    test('nothing due, nothing returned; a negative limit is a bug', () {
      expect(dueRecallCards(cards, today: today.addDays(-5)), isEmpty);
      expect(
        () => dueRecallCards(cards, today: today, limit: -1),
        throwsRangeError,
      );
    });
  });

  test('the streak is the run of known answers at the end', () {
    const k = RecallVerdict.known;
    const g = RecallVerdict.guessed;
    const m = RecallVerdict.missed;
    expect(recallStreak([]), 0);
    expect(recallStreak([k, k, k]), 3);
    expect(recallStreak([k, m, k, k]), 2);
    expect(recallStreak([k, k, g]), 0);
  });
}
