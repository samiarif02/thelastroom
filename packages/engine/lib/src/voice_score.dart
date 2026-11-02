import 'dimension.dart';
import 'scoring.dart';

/// One thing a strong spoken answer does, as the engine sees it: an id and the dimension making
/// it earns. The text lives in content.
class VoicePoint {
  const VoicePoint({required this.id, required this.dimension});

  final String id;
  final Dimension dimension;
}

/// How many of the points behind one dimension were made.
class PointTally {
  const PointTally({
    required this.made,
    required this.of,
    required this.direct,
  });

  final int made;
  final int of;

  /// False when no point earns this dimension directly, so it took the share of *all* points
  /// made ([scoreVoiceAnswer]).
  final bool direct;

  @override
  bool operator ==(Object other) =>
      other is PointTally &&
      other.made == made &&
      other.of == of &&
      other.direct == direct;

  @override
  int get hashCode => Object.hash(made, of, direct);

  @override
  String toString() => 'PointTally($made of $of${direct ? '' : ', all'})';
}

/// A scored voice answer: the [MissionScore] progress keeps, and the tally behind each
/// dimension, so the debrief can say why each number is what it is.
class VoiceScore {
  const VoiceScore({required this.score, required this.tallies});

  final MissionScore score;
  final Map<Dimension, PointTally> tallies;
}

/// Scores a spoken answer from the points it made, deterministically and offline.
///
/// [points] are every point the mission listens for (the question's, then the follow-up's), each
/// tied to a dimension; [made] the ids of those the answer made, whoever judged it (the AI
/// recruiter, or the player ticking a self-check). Ids in [made] that aren't in [points] are
/// ignored.
///
/// - Each dimension is the share of *its* points made, scaled to 0–100 and rounded half up:
///   two relevance points, one made → **50**.
/// - A dimension no point earns directly takes the share of *all* points made, so it neither
///   gives free marks nor zeroes an answer for something it was never asked: five points, three
///   made → **60**.
/// - [MissionScore.total] is the four rounded scores weighted by [Dimension.weightPercent],
///   rounded half up once more, as in `scoreAttempt`, so the dossier's total can be checked by
///   hand.
/// - [MissionScore.optionIdsByCost] lists the missed points first, then the made ones, each
///   group by the weight of its dimension (heaviest first, ties in content order): the first
///   is the point that cost the most.
///
/// Worked example (the "worked example" test): relevance a, b; specificity c; structure d;
/// adaptability e (the follow-up). Made a, c, e: relevance 50, specificity 100, structure 0,
/// adaptability 100 → total (25×50 + 30×100 + 25×0 + 20×100) / 100 = 62.5 → **63**.
///
/// Throws an [ArgumentError] when [points] is empty or repeats an id: a malformed mission is a
/// bug in the caller, not a score of zero.
VoiceScore scoreVoiceAnswer({
  required List<VoicePoint> points,
  required Set<String> made,
}) {
  if (points.isEmpty) {
    throw ArgumentError.value(points, 'points', 'needs at least one point');
  }
  final ids = {for (final p in points) p.id};
  if (ids.length != points.length) {
    throw ArgumentError.value(points, 'points', 'repeats an id');
  }
  bool isMade(VoicePoint p) => made.contains(p.id);
  final all = PointTally(
    made: points.where(isMade).length,
    of: points.length,
    direct: false,
  );

  final tallies = <Dimension, PointTally>{
    for (final d in Dimension.values)
      d: switch (points.where((p) => p.dimension == d).toList()) {
        final mine when mine.isNotEmpty => PointTally(
          made: mine.where(isMade).length,
          of: mine.length,
          direct: true,
        ),
        _ => all,
      },
  };
  final dimensions = <Dimension, int>{
    for (final d in Dimension.values)
      d: _roundHalfUp(tallies[d]!.made * maxMissionScore, tallies[d]!.of),
  };
  final weighted = Dimension.values.fold(
    0,
    (sum, d) => sum + d.weightPercent * dimensions[d]!,
  );

  // Heaviest dimension first; a stable sort keeps content order within a dimension.
  int byWeight(VoicePoint a, VoicePoint b) =>
      b.dimension.weightPercent.compareTo(a.dimension.weightPercent);
  final missed = [
    for (final p in points)
      if (!isMade(p)) p,
  ];
  final kept = [
    for (final p in points)
      if (isMade(p)) p,
  ];
  _stableSort(missed, byWeight);
  _stableSort(kept, byWeight);

  return VoiceScore(
    score: MissionScore(
      dimensions: Map.unmodifiable(dimensions),
      total: _roundHalfUp(weighted, _percentPoints),
      optionIdsByCost: List.unmodifiable([
        for (final p in [...missed, ...kept]) p.id,
      ]),
      flags: const {},
    ),
    tallies: Map.unmodifiable(tallies),
  );
}

/// The weights are percentages, so a weighted sum is in hundredths of a point.
const int _percentPoints = 100;

/// [numerator] / [denominator] rounded half up, in integers (the same rule as `scoreAttempt`).
int _roundHalfUp(int numerator, int denominator) =>
    (2 * numerator + denominator) ~/ (2 * denominator);

/// An insertion sort: [List.sort] isn't promised to be stable, and ties must keep content order.
void _stableSort<T>(List<T> list, int Function(T, T) compare) {
  for (var i = 1; i < list.length; i++) {
    final item = list[i];
    var j = i - 1;
    while (j >= 0 && compare(list[j], item) > 0) {
      list[j + 1] = list[j];
      j--;
    }
    list[j + 1] = item;
  }
}
