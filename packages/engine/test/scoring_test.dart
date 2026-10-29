import 'dart:math';

import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('scoreAttempt', () {
    test('all 3s score 100 and all 0s score 0', () {
      final perfect = scoreAttempt(
        attempt([even('o', 3), even('e', 3), even('l', 3)], even('r', 3)),
      );
      final empty = scoreAttempt(
        attempt([even('o', 0), even('e', 0), even('l', 0)], even('r', 0)),
      );
      expect(perfect.total, 100);
      expect(perfect.dimensions.values, everyElement(100));
      expect(empty.total, 0);
      expect(empty.dimensions.values, everyElement(0));
    });

    group('a worked example per dimension', () {
      // Beats (relevance, specificity, structure, adaptability):
      //   open     3, 3, 3, 3
      //   evidence 2, 1, 2, 3
      //   land     1, 1, 3, 3
      // Reply      2, 0, 0, 2
      // The beats' adaptability and the reply's structure are set high and low on purpose:
      // neither may count.
      final score = scoreAttempt(
        attempt([
          line('o', 3, 3, 3, 3),
          line('e', 2, 1, 2, 3),
          line('l', 1, 1, 3, 3),
        ], line('r', 2, 0, 0, 2)),
      );

      test('relevance: the mean of three beats and the reply', () {
        // (3 + 2 + 1 + 2) / 12 = 8 / 12 = 66.7 → 67
        expect(score.dimensions[Dimension.relevance], 67);
      });

      test('specificity: the mean of three beats and the reply', () {
        // (3 + 1 + 1 + 0) / 12 = 5 / 12 = 41.7 → 42
        expect(score.dimensions[Dimension.specificity], 42);
      });

      test('structure: the weakest beat, the reply not counted', () {
        // min(3, 2, 3) = 2 → 2 / 3 = 66.7 → 67 (the reply's 0 is ignored)
        expect(score.dimensions[Dimension.structure], 67);
      });

      test('adaptability: the reply only, the beats not counted', () {
        // 2 / 3 = 66.7 → 67 (the beats' 3s are ignored)
        expect(score.dimensions[Dimension.adaptability], 67);
      });

      test('total: the rounded dimensions weighted, rounded half up', () {
        // (25 × 67 + 30 × 42 + 25 × 67 + 20 × 67) / 100
        //   = (1675 + 1260 + 1675 + 1340) / 100 = 59.5 → 60
        expect(score.total, 60);
      });

      test('orders every pick by weighted shortfall, ties to the earliest', () {
        // open      0                               =   0
        // evidence  25 × 1 + 30 × 2 + 25 × 1        = 110
        // land      25 × 2 + 30 × 2 + 25 × 0        = 110 (ties evidence, comes after)
        // reply     25 × 1 + 30 × 3 + 20 × 1        = 135
        expect(score.optionIdsByCost, ['r', 'e', 'l', 'o']);
        expect(score.costliestOptionId, 'r');
      });
    });

    group('structure is the weakest beat (FR-22)', () {
      ScoredChoice beat(String id, int structure) => line(id, 3, 3, structure);
      final reply = even('r', 3);

      test('a strong answer: beats 3, 3, 3 → structure 100', () {
        // min(3, 3, 3) = 3 → 3 / 3 × 100 = 100. Total 100.
        final score = scoreAttempt(
          attempt([beat('o', 3), beat('e', 3), beat('l', 3)], reply),
        );
        expect(score.dimensions[Dimension.structure], 100);
        expect(score.total, 100);
      });

      test('one weak beat in a strong answer: beats 3, 3, 1 → structure 33', () {
        // min(3, 3, 1) = 1 → 1 / 3 × 100 = 33.3 → 33. An average would say 78 and hide it.
        // Debrief: "An answer is only as clear as its weakest beat: one rambling line took
        // structure from 100 to 33."
        // Total (25 × 100 + 30 × 100 + 25 × 33 + 20 × 100) / 100 = 83.25 → 83.
        final score = scoreAttempt(
          attempt([beat('o', 3), beat('e', 3), beat('l', 1)], reply),
        );
        expect(score.dimensions[Dimension.structure], 33);
        expect(score.total, 83);
      });

      test('an evenly middling answer: beats 2, 2, 2 → structure 67', () {
        // min(2, 2, 2) = 2 → 2 / 3 × 100 = 66.7 → 67. Every dimension is 67, total 67.
        final score = scoreAttempt(
          attempt([even('o', 2), even('e', 2), even('l', 2)], even('r', 2)),
        );
        expect(score.dimensions[Dimension.structure], 67);
        expect(score.total, 67);
      });

      test('a 3-3-0 answer scores 0 on structure, not 67', () {
        final score = scoreAttempt(
          attempt([beat('o', 3), beat('e', 3), beat('l', 0)], reply),
        );
        expect(score.dimensions[Dimension.structure], 0);
      });
    });

    test('collects every flag from the beats and the reply', () {
      final score = scoreAttempt(
        attempt([
          even('o', 1, flags: {Flag.vague}),
          even('e', 1, flags: {Flag.weNotI, Flag.vague}),
          even('l', 3),
        ], even('r', 1, flags: {Flag.blame})),
      );
      expect(score.flags, {Flag.vague, Flag.weNotI, Flag.blame});
    });

    test('rejects picks that are not one per beat, in order', () {
      final reply = even('r', 2);
      expect(
        () => scoreAttempt(attempt([even('o', 2), even('e', 2)], reply)),
        throwsArgumentError,
      );
      expect(
        () => scoreAttempt(
          AttemptInput(
            picks: [
              BeatPick(beat: BeatKind.evidence, choice: even('e', 2)),
              BeatPick(beat: BeatKind.open, choice: even('o', 2)),
              BeatPick(beat: BeatKind.land, choice: even('l', 2)),
            ],
            followUpReply: reply,
            hinted: false,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('scoreAttempt properties', () {
    // Seeded, so every run checks the same attempts. The Random lives in the test, never in
    // the engine.
    const attempts = 400;
    final random = Random(20261029);
    int points() => random.nextInt(DimensionScores.max + 1);
    ScoredChoice randomLine(String id) =>
        line(id, points(), points(), points(), points());
    final samples = [
      for (var i = 0; i < attempts; i++)
        [randomLine('o'), randomLine('e'), randomLine('l'), randomLine('r')],
    ];
    MissionScore score(List<ScoredChoice> lines) =>
        scoreAttempt(attempt(lines.sublist(0, 3), lines[3]));

    test('the total and every dimension are always within 0–100', () {
      for (final lines in samples) {
        final s = score(lines);
        expect(s.total, inInclusiveRange(0, maxMissionScore));
        expect(s.dimensions.values, everyElement(inInclusiveRange(0, 100)));
      }
    });

    test('raising any one score of any one line never lowers the total', () {
      for (final lines in samples) {
        final before = score(lines).total;
        for (var pick = 0; pick < lines.length; pick++) {
          for (final d in Dimension.values) {
            final s = lines[pick].scores;
            if (s[d] == DimensionScores.max) continue;
            int bump(Dimension x) => s[x] + (x == d ? 1 : 0);
            final raised = [...lines];
            raised[pick] = line(
              lines[pick].optionId,
              bump(Dimension.relevance),
              bump(Dimension.specificity),
              bump(Dimension.structure),
              bump(Dimension.adaptability),
            );
            expect(
              score(raised).total,
              greaterThanOrEqualTo(before),
              reason: 'raising $d on pick $pick',
            );
          }
        }
      }
    });

    test('the same attempt scored twice gives the same MissionScore', () {
      for (final lines in samples) {
        final first = score(lines);
        final second = score(lines);
        expect(second, first);
        expect(second.hashCode, first.hashCode);
      }
    });

    test('optionIdsByCost ties go to the earliest pick', () {
      // Every line identical: all four tie, so the order is the play order.
      final tied = score([
        even('o', 1),
        even('e', 1),
        even('l', 1),
        even('r', 1),
      ]);
      expect(tied.optionIdsByCost, ['o', 'e', 'l', 'r']);
      // In random attempts, equal neighbours keep their play order.
      const order = ['o', 'e', 'l', 'r'];
      for (final lines in samples) {
        final ids = score(lines).optionIdsByCost;
        expect(ids.toSet(), order.toSet());
        for (var i = 1; i < ids.length; i++) {
          final cost = [
            for (final id in [ids[i - 1], ids[i]])
              _shortfall(lines[order.indexOf(id)], isReply: id == 'r'),
          ];
          expect(cost[0], greaterThanOrEqualTo(cost[1]));
          if (cost[0] == cost[1]) {
            expect(order.indexOf(ids[i - 1]), lessThan(order.indexOf(ids[i])));
          }
        }
      }
    });

    test('different scores are not equal', () {
      final a = score([even('o', 3), even('e', 3), even('l', 3), even('r', 3)]);
      final b = score([even('o', 3), even('e', 3), even('l', 2), even('r', 3)]);
      expect(a, isNot(b));
      expect(a.toString(), contains('total: 100'));
    });
  });

  group('trust meter', () {
    /// Plays [table] pick by pick and checks the meter after each one.
    void expectTable(List<(ScoredChoice, int)> table) {
      final picks = <ScoredChoice>[];
      for (final (pick, expected) in table) {
        picks.add(pick);
        expect(trustAfter(picks), expected, reason: 'after ${pick.optionId}');
      }
    }

    test('starts at 50 before any pick', () {
      expect(trustAfter(const []), initialTrust);
      expect(initialTrust, 50);
    });

    test('a middling line leaves it where it was', () {
      expect(trustAfter([even('o', 2), even('e', 2)]), initialTrust);
    });

    test('a strong run, pick by pick', () {
      // trust = clamp(previous + 4 × (relevance + specificity + structure − 6), 0, 100)
      // pick      points  change          trust
      // start                               50
      // open      3+3+3=9  4 × ( 9 − 6) = +12  62
      // evidence  3+3+2=8  4 × ( 8 − 6) =  +8  70
      // land      3+2+3=8  4 × ( 8 − 6) =  +8  78
      // reply     3+3+3=9  4 × ( 9 − 6) = +12  90
      expectTable([
        (line('open', 3, 3, 3), 62),
        (line('evidence', 3, 3, 2), 70),
        (line('land', 3, 2, 3), 78),
        (line('reply', 3, 3, 3, 3), 90),
      ]);
    });

    test('a weak run, pick by pick, clamped at 0', () {
      // pick      points  change          trust
      // start                               50
      // open      2+1+1=4  4 × (4 − 6) =  −8  42
      // evidence  1+0+1=2  4 × (2 − 6) = −16  26
      // land      1+1+0=2  4 × (2 − 6) = −16  10
      // reply     0+0+1=1  4 × (1 − 6) = −20   0 (−10 clamped)
      expectTable([
        (line('open', 2, 1, 1), 42),
        (line('evidence', 1, 0, 1), 26),
        (line('land', 1, 1, 0), 10),
        (line('reply', 0, 0, 1), 0),
      ]);
    });

    test('climbs back from 0, not from a hidden debt', () {
      // 50 → 26 → 2 → 0 (−22 clamped) → 12
      expectTable([
        (even('a', 0), 26),
        (even('b', 0), 2),
        (even('c', 0), 0),
        (even('d', 3), 12),
      ]);
    });

    test('never passes 100', () {
      expect(trustAfter(List.filled(10, even('top', 3))), maxMissionScore);
    });

    test('moves visibly within one beat: at least 4 points per point', () {
      expect(trustStepPerPoint, greaterThanOrEqualTo(4));
      expect(middlingLinePoints, 6);
    });
  });
}

/// The test's own copy of the cost rule, so the ordering is checked against the spec rather
/// than against the engine's helper.
int _shortfall(ScoredChoice c, {required bool isReply}) {
  final counted = isReply
      ? [Dimension.relevance, Dimension.specificity, Dimension.adaptability]
      : [Dimension.relevance, Dimension.specificity, Dimension.structure];
  return counted.fold(
    0,
    (sum, d) => sum + d.weightPercent * (DimensionScores.max - c.scores[d]),
  );
}
