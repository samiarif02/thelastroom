import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  // The worked example in `scoreVoiceAnswer`'s doc: two relevance points, one each of the rest.
  const a = VoicePoint(id: 'a', dimension: Dimension.relevance);
  const b = VoicePoint(id: 'b', dimension: Dimension.relevance);
  const c = VoicePoint(id: 'c', dimension: Dimension.specificity);
  const d = VoicePoint(id: 'd', dimension: Dimension.structure);
  const e = VoicePoint(id: 'e', dimension: Dimension.adaptability);
  const five = [a, b, c, d, e];

  group('scoreVoiceAnswer', () {
    test('the worked example: made a, c, e scores 50, 100, 0, 100 → 63', () {
      final scored = scoreVoiceAnswer(points: five, made: {'a', 'c', 'e'});
      expect(scored.score.dimensions, {
        Dimension.relevance: 50,
        Dimension.specificity: 100,
        Dimension.structure: 0,
        Dimension.adaptability: 100,
      });
      expect(scored.score.total, 63);
      expect(
        scored.tallies[Dimension.relevance],
        const PointTally(made: 1, of: 2, direct: true),
      );
    });

    test('every point made scores 100, none scores 0', () {
      final all = scoreVoiceAnswer(
        points: five,
        made: {for (final p in five) p.id},
      );
      final none = scoreVoiceAnswer(points: five, made: const {});
      expect(all.score.total, 100);
      expect(all.score.dimensions.values, everyElement(100));
      expect(none.score.total, 0);
      expect(none.score.dimensions.values, everyElement(0));
    });

    test('a dimension no point earns takes the share of all points made', () {
      // Three points, none for structure; two made → structure 2 of 3 → 67.
      const points = [a, c, e];
      final scored = scoreVoiceAnswer(points: points, made: {'a', 'c'});
      expect(scored.score.dimensions[Dimension.structure], 67);
      expect(
        scored.tallies[Dimension.structure],
        const PointTally(made: 2, of: 3, direct: false),
      );
      // relevance 100, specificity 100, structure 67, adaptability 0:
      // (25×100 + 30×100 + 25×67 + 20×0) / 100 = 71.75 → 72.
      expect(scored.score.total, 72);
    });

    test('ids that are not points are ignored', () {
      expect(
        scoreVoiceAnswer(points: five, made: {'a', 'zzz'}),
        isA<VoiceScore>().having(
          (s) => s.score,
          'score',
          scoreVoiceAnswer(points: five, made: {'a'}).score,
        ),
      );
    });

    test(
      'the costliest point is the heaviest missed one; made points come last',
      () {
        final scored = scoreVoiceAnswer(points: five, made: {'c'});
        // Missed: specificity 30 (none), relevance 25 (a, b), structure 25 (d), adaptability 20.
        expect(scored.score.optionIdsByCost, ['a', 'b', 'd', 'e', 'c']);
        expect(scored.score.costliestOptionId, 'a');
      },
    );

    test('a voice answer carries no flags and no guesses', () {
      final scored = scoreVoiceAnswer(points: five, made: {'a'});
      expect(scored.score.flags, isEmpty);
      expect(scored.score.guessed, isFalse);
    });

    test('the same ticks always give the same score', () {
      expect(
        scoreVoiceAnswer(points: five, made: {'b', 'd'}).score,
        scoreVoiceAnswer(points: five, made: {'d', 'b'}).score,
      );
    });

    test('half rounds up: one of two relevance points is exactly 50, one of three 33', () {
      const r3 = [
        VoicePoint(id: 'x', dimension: Dimension.relevance),
        VoicePoint(id: 'y', dimension: Dimension.relevance),
        VoicePoint(id: 'z', dimension: Dimension.relevance),
      ];
      expect(
        scoreVoiceAnswer(
          points: r3,
          made: {'x'},
        ).score.dimensions[Dimension.relevance],
        33,
      );
      expect(
        scoreVoiceAnswer(
          points: r3,
          made: {'x', 'y'},
        ).score.dimensions[Dimension.relevance],
        67,
      );
    });

    test('no points, or a repeated id, is a caller bug', () {
      expect(
        () => scoreVoiceAnswer(points: const [], made: const {}),
        throwsArgumentError,
      );
      expect(
        () => scoreVoiceAnswer(points: const [a, a], made: const {}),
        throwsArgumentError,
      );
    });
  });
}
