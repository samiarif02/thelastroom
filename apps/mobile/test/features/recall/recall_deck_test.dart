import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/recall/recall_deck.dart';

import 'recall_fixtures.dart';

void main() {
  final deck = RecallDeck(gameContent);

  group('missedCardIds', () {
    test('the strongest lines and a good reply earn no cards', () {
      final best = [for (final b in m1.beats) strongestOf(b)];
      expect(deck.missedCardIds(m1Attempt(best)), isEmpty);
    });

    test('each weak line earns the card of the trap that tempts it', () {
      final (weakOpen, trapOpen) = weakOf(m1.beats[0]);
      final (weakLand, trapLand) = weakOf(m1.beats[2]);
      final picks = [weakOpen, strongestOf(m1.beats[1]), weakLand];
      expect(deck.missedCardIds(m1Attempt(picks)), [trapOpen.id, trapLand.id]);
    });

    test('a weak follow-up reply earns its lesson card', () {
      final best = [for (final b in m1.beats) strongestOf(b)];
      expect(
        deck.missedCardIds(m1Attempt(best, replyOptionId: m1WeakReply.id)),
        [m1WeakReply.lessonId],
      );
    });

    test('an attempt at a mission that no longer exists earns nothing', () {
      final attempt = m1Attempt(const ['x', 'y', 'z']);
      expect(
        RecallDeck(
          const ContentBundle(
            chapters: [],
            interviewers: [],
            lessons: [],
            missions: [],
          ),
        ).missedCardIds(attempt),
        isEmpty,
      );
    });
  });

  group('question', () {
    test(
      'a trap card: the misconception, its line, and the principle wins',
      () {
        final (weak, trap) = weakOf(m1.beats[0]);
        final q = deck.question(trap.id, seed: 7)!;
        final sound = m1.beats[0].why!.reasons.firstWhere(
          (r) => r.soundFor.isNotEmpty,
        );
        expect(q.kind, RecallCardKind.trap);
        expect(q.kicker, RecallDeck.trapKicker);
        expect(q.prompt, trap.text);
        expect(
          q.quote,
          m1.beats[0].options.firstWhere((o) => o.id == weak).text,
        );
        expect(q.correctChoiceId, sound.id);
        expect(q.choices.map((c) => c.id), contains(sound.id));
        expect(q.choices.map((c) => c.id), isNot(contains(trap.id)));
      },
    );

    test('every trap in the game makes a card of three distinct choices', () {
      for (final mission in missions) {
        for (final beat in mission.beats) {
          for (final trap in beat.why!.reasons.where(
            (r) => r.tempts.isNotEmpty,
          )) {
            final q = deck.question(trap.id, seed: 3)!;
            final ids = q.choices.map((c) => c.id).toSet();
            expect(ids, hasLength(RecallDeck.trapChoices), reason: trap.id);
            expect(ids, contains(q.correctChoiceId));
            expect(ids, isNot(contains(trap.id)));
          }
        }
      }
    });

    test(
      'the choices are shuffled by the seed, the same seed the same order',
      () {
        final (_, trap) = weakOf(m1.beats[1]);
        List<String> order(int seed) => deck
            .question(trap.id, seed: seed)!
            .choices
            .map((c) => c.id)
            .toList();
        expect(order(5), order(5));
        final orders = {for (var s = 0; s < 20; s++) order(s).join(',')};
        expect(orders.length, greaterThan(1));
      },
    );

    test('a lesson card asks the lesson\'s own recall check', () {
      final lesson = lessons.first;
      final q = deck.question(lesson.id, seed: 1)!;
      expect(q.kind, RecallCardKind.lesson);
      expect(q.prompt, lesson.recall.prompt);
      expect(q.correctChoiceId, lesson.recall.correctOptionId);
      expect(q.takeaway, lesson.takeaway);
      expect(q.choices, hasLength(lesson.recall.options.length));
    });

    test('an id the content no longer has makes no card', () {
      expect(deck.question('gone', seed: 1), isNull);
    });
  });
}
