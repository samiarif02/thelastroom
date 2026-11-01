import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // A "tell me about a time" build: situation, task, action, result, and two decoys.
  const spec = BuildSpec(
    id: 'b',
    parts: ['s', 't', 'a', 'r'],
    decoys: {
      'we': {Flag.weNotI},
      'blame': {Flag.blame},
    },
  );

  ({int relevance, int specificity, int structure}) points(
    List<String> placed,
  ) {
    final s = scoreBuild(spec, placed).choice.scores;
    return (
      relevance: s.relevance,
      specificity: s.specificity,
      structure: s.structure,
    );
  }

  group('scoreBuild', () {
    test('every part, in order, no decoy: the strong answer, 3 3 3', () {
      final result = scoreBuild(spec, ['s', 't', 'a', 'r']);
      expect(points(['s', 't', 'a', 'r']), (
        relevance: 3,
        specificity: 3,
        structure: 3,
      ));
      expect(result.perfect, isTrue);
      expect(result.choice.flags, isEmpty);
      expect(result.choice.scores.adaptability, 0);
    });

    group('order: each part out of place costs a point of structure', () {
      test('result before action: one out of order, structure 2', () {
        final result = scoreBuild(spec, ['s', 't', 'r', 'a']);
        expect(result.outOfOrder, 1);
        expect(points(['s', 't', 'r', 'a']).structure, 2);
        expect(result.choice.flags, isEmpty);
      });

      test('two out of order: structure 1, and it rambles', () {
        final result = scoreBuild(spec, ['a', 's', 'r', 't']);
        // Longest run in order: s, t (or s, r; a, r): 2 of 4, so 2 out of order.
        expect(result.outOfOrder, 2);
        expect(result.choice.scores.structure, 1);
        expect(result.choice.flags, {Flag.rambling});
      });

      test('backwards: three out of order, structure 0', () {
        expect(scoreBuild(spec, ['r', 'a', 't', 's']).outOfOrder, 3);
        expect(points(['r', 'a', 't', 's']).structure, 0);
      });

      test('order is judged on the parts placed, not on the gaps', () {
        // s, a, r is in order with t left out: a missing part, nothing out of order.
        final result = scoreBuild(spec, ['s', 'a', 'r']);
        expect(result.outOfOrder, 0);
        expect(result.missing, 1);
      });
    });

    group('completeness: each part left out costs a point of specificity', () {
      test('no result: specificity 2, structure untouched', () {
        expect(points(['s', 't', 'a']), (
          relevance: 3,
          specificity: 2,
          structure: 3,
        ));
      });

      test('two left out: specificity 1, and it is vague', () {
        final result = scoreBuild(spec, ['s', 'a']);
        expect(result.choice.scores.specificity, 1);
        expect(result.choice.flags, {Flag.vague});
      });

      test('nothing of the strong answer: 0 everywhere', () {
        expect(points(['we']), (relevance: 0, specificity: 0, structure: 0));
        expect(points([]), (relevance: 0, specificity: 0, structure: 0));
      });
    });

    group('a decoy holds the dimension its flag lowers at 1', () {
      test('"we" not "I": specificity 1, the rest untouched', () {
        final result = scoreBuild(spec, ['s', 't', 'we', 'a', 'r']);
        expect(points(['s', 't', 'we', 'a', 'r']), (
          relevance: 3,
          specificity: 1,
          structure: 3,
        ));
        expect(result.decoysUsed, ['we']);
        expect(result.choice.flags, {Flag.weNotI});
        expect(result.perfect, isFalse);
      });

      test('blame: relevance 1', () {
        expect(points(['s', 't', 'a', 'r', 'blame']).relevance, 1);
      });

      test('a decoy never lifts a lower score', () {
        // Three missing: specificity 0, and the "we" ceiling of 1 doesn't raise it.
        expect(points(['s', 'we']).specificity, 0);
      });
    });

    test('every flagged result respects the validator ceiling', () {
      // All orders of every subset of the six fragments: no flag above its ceiling.
      const all = ['s', 't', 'a', 'r', 'we', 'blame'];
      void walk(List<String> placed) {
        final c = scoreBuild(spec, placed).choice;
        for (final f in c.flags) {
          expect(
            c.scores[f.lowers],
            lessThanOrEqualTo(flaggedDimensionCeiling),
            reason: '$placed flagged $f',
          );
        }
        expect(c.scores.isInRange, isTrue);
        if (placed.length == 4) return;
        for (final id in all) {
          if (!placed.contains(id)) walk([...placed, id]);
        }
      }

      walk([]);
    });

    test('unknown and repeated fragments are ignored', () {
      final result = scoreBuild(spec, ['s', 's', 'zz', 't', 'a', 'r']);
      expect(result.perfect, isTrue);
      expect(result.choice.optionId, buildOptionId('b', ['s', 't', 'a', 'r']));
    });

    test('the same build always scores the same', () {
      final a = scoreBuild(spec, ['t', 's', 'we', 'r']).choice;
      final b = scoreBuild(spec, ['t', 's', 'we', 'r']).choice;
      expect(a.optionId, b.optionId);
      expect(a.flags, b.flags);
      expect(a.scores[Dimension.structure], b.scores[Dimension.structure]);
    });

    test('a perfect build scores like a perfect line in the mission', () {
      final built = scoreBuild(spec, ['s', 't', 'a', 'r']).choice;
      final score = scoreAttempt(
        attempt([even('o', 3), built, even('l', 3)], even('r', 3)),
      );
      expect(score.total, 100);
      expect(trustAfter([built]), trustAfter([even('x', 3)]));
    });
  });

  group('build option ids', () {
    test('round trip', () {
      final id = buildOptionId('m04_evidence_build', ['m04_b_s', 'm04_b_a']);
      expect(id, 'm04_evidence_build=m04_b_s+m04_b_a');
      final parsed = parseBuildOptionId(id)!;
      expect(parsed.buildId, 'm04_evidence_build');
      expect(parsed.placed, ['m04_b_s', 'm04_b_a']);
    });

    test('an empty build and an ordinary option id', () {
      expect(parseBuildOptionId(buildOptionId('b', []))!.placed, isEmpty);
      expect(parseBuildOptionId('m04_evidence_tagged'), isNull);
    });
  });
}
