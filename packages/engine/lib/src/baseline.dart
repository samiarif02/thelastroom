import 'dimension.dart';
import 'scoring.dart';

/// How the latest attempt compares with the Mission 1 baseline: the skill radar, the Chapter 1
/// report and "then vs. now" (FR-30, FR-41).
class BaselineComparison {
  const BaselineComparison({
    required this.dimensionDeltas,
    required this.totalDelta,
  });

  /// Latest minus baseline, per dimension, in points out of 100 (negative is a drop).
  final Map<Dimension, int> dimensionDeltas;

  /// Latest total minus baseline total.
  final int totalDelta;
}

/// Compares [latest] with [baseline]. Pure subtraction, so the report can be recomputed from
/// stored scores at any time.
BaselineComparison compareToBaseline({
  required MissionScore baseline,
  required MissionScore latest,
}) => throw UnimplementedError();

/// A mission score in a coarse band, for analytics: raw scores are never sent
/// (docs/rules/analytics.md). Bands are [scoreBucketWidth] points wide.
enum ScoreBucket {
  from0,
  from20,
  from40,
  from60,
  from80;

  /// The band [total] (0–100) falls in; 100 is in [from80].
  static ScoreBucket of(int total) => throw UnimplementedError();
}

/// The width of one [ScoreBucket] band, in points.
const int scoreBucketWidth = 20;

/// A score change in a coarse band, for `chapter_completed` analytics.
enum ScoreDeltaBucket {
  /// Down by more than [ScoreDeltaBucket.flatBand] points.
  down,

  /// Within ±[ScoreDeltaBucket.flatBand] points: no real change.
  flat,

  /// Up by more than [ScoreDeltaBucket.flatBand] and less than [ScoreDeltaBucket.bigGain].
  up,

  /// Up by [ScoreDeltaBucket.bigGain] points or more.
  upALot;

  static const int flatBand = 5;
  static const int bigGain = 20;

  static ScoreDeltaBucket of(int delta) => throw UnimplementedError();
}
