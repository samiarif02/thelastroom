import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('compareToBaseline subtracts per dimension and in total', () {
    // Baseline: every line 1 → every dimension 33, total 33.
    // Latest: every line 3 except a land with structure 2 → structure 67, total 92.
    final baseline = scoreAttempt(
      attempt([even('o', 1), even('e', 1), even('l', 1)], even('r', 1)),
    );
    final latest = scoreAttempt(
      attempt([even('o', 3), even('e', 3), line('l', 3, 3, 2)], even('r', 3)),
    );
    final comparison = compareToBaseline(baseline: baseline, latest: latest);
    expect(comparison.dimensionDeltas, {
      Dimension.relevance: 67,
      Dimension.specificity: 67,
      Dimension.structure: 34,
      Dimension.adaptability: 67,
    });
    // (25 × 100 + 30 × 100 + 25 × 67 + 20 × 100) / 100 = 91.75 → 92; 92 − 33 = 59.
    expect(comparison.totalDelta, 59);
    expect(
      compareToBaseline(baseline: latest, latest: baseline).totalDelta,
      -59,
    );
  });

  group('ScoreBucket', () {
    test('20-point bands, with 100 in the top one', () {
      expect(ScoreBucket.of(0), ScoreBucket.from0);
      expect(ScoreBucket.of(19), ScoreBucket.from0);
      expect(ScoreBucket.of(20), ScoreBucket.from20);
      expect(ScoreBucket.of(59), ScoreBucket.from40);
      expect(ScoreBucket.of(60), ScoreBucket.from60);
      expect(ScoreBucket.of(80), ScoreBucket.from80);
      expect(ScoreBucket.of(100), ScoreBucket.from80);
    });

    test('every band name says where it starts', () {
      for (final bucket in ScoreBucket.values) {
        expect(bucket.name, 'from${bucket.index * scoreBucketWidth}');
      }
    });

    test('a total outside 0–100 is a bug', () {
      expect(() => ScoreBucket.of(-1), throwsRangeError);
      expect(() => ScoreBucket.of(101), throwsRangeError);
    });
  });

  test('ScoreDeltaBucket bands: down, flat ±5, up, up a lot from 20', () {
    expect(ScoreDeltaBucket.of(-6), ScoreDeltaBucket.down);
    expect(ScoreDeltaBucket.of(-5), ScoreDeltaBucket.flat);
    expect(ScoreDeltaBucket.of(0), ScoreDeltaBucket.flat);
    expect(ScoreDeltaBucket.of(5), ScoreDeltaBucket.flat);
    expect(ScoreDeltaBucket.of(6), ScoreDeltaBucket.up);
    expect(ScoreDeltaBucket.of(19), ScoreDeltaBucket.up);
    expect(ScoreDeltaBucket.of(20), ScoreDeltaBucket.upALot);
    expect(ScoreDeltaBucket.of(100), ScoreDeltaBucket.upALot);
  });
}
