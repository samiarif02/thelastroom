import 'beat.dart';
import 'dimension.dart';
import 'dimension_scores.dart';
import 'flag.dart';
import 'line_cost.dart';

/// Everything one mission attempt produced, as the engine scores it.
class AttemptInput {
  const AttemptInput({
    required this.picks,
    required this.followUpReply,
    required this.hinted,
  });

  /// One pick per beat, in beat order (open, evidence, land).
  final List<BeatPick> picks;

  /// The reply to the interviewer's follow-up: the only source of adaptability.
  final ScoredChoice followUpReply;

  /// Whether hint cards were available. Unhinted attempts are the only ones that can unlock
  /// a skill (FR-32).
  final bool hinted;
}

/// A scored attempt, everything the debrief and progress screens show (FR-15, FR-16).
///
/// Two scores are equal when every field is, so "the same attempt scored twice gives the same
/// score" is a plain `expect(a, b)`.
class MissionScore {
  const MissionScore({
    required this.dimensions,
    required this.total,
    required this.optionIdsByCost,
    required this.flags,
  });

  /// Each dimension normalised to 0–100.
  final Map<Dimension, int> dimensions;

  /// The weighted mission score, 0–100 ([Dimension.weightPercent]).
  final int total;

  /// Every pick (three beats, then the reply), costliest first: ordered by weighted shortfall
  /// from a perfect line, ties to the earliest. The debrief marks the first in red pen and
  /// teaches the lesson of the first one that has a lesson (FR-15).
  final List<String> optionIdsByCost;

  /// The line that cost the most.
  String get costliestOptionId => optionIdsByCost.first;

  /// Every flag raised across the beats and the reply, for the lesson and recall cards.
  final Set<Flag> flags;

  @override
  bool operator ==(Object other) =>
      other is MissionScore &&
      other.total == total &&
      Dimension.values.every((d) => other.dimensions[d] == dimensions[d]) &&
      other.dimensions.length == dimensions.length &&
      _sameList(other.optionIdsByCost, optionIdsByCost) &&
      other.flags.length == flags.length &&
      other.flags.containsAll(flags);

  @override
  int get hashCode => Object.hash(
    total,
    Object.hashAll(Dimension.values.map((d) => dimensions[d])),
    Object.hashAll(optionIdsByCost),
    Object.hashAllUnordered(flags),
  );

  @override
  String toString() =>
      'MissionScore(total: $total, dimensions: $dimensions, '
      'optionIdsByCost: $optionIdsByCost, flags: $flags)';
}

bool _sameList(List<String> a, List<String> b) =>
    a.length == b.length &&
    Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

/// Scores one attempt, deterministically and offline (FR-20–FR-22).
///
/// - **Relevance** and **specificity**: the mean of the three beat picks and the follow-up
///   reply, on each dimension.
/// - **Structure**: the *lowest* structure score among the three beats. An answer is as well
///   built as its weakest beat, which is how "scored across beats as a whole, not per pick"
///   (FR-22) is made checkable. Three worked examples (the named tests in
///   `scoring_test.dart`, "structure is the weakest beat"):
///   - a strong answer, beats 3, 3, 3: min 3 → 3 / 3 × 100 = **100**;
///   - one weak beat in a strong answer, beats 3, 3, 1: min 1 → 1 / 3 × 100 = 33.3 → **33**.
///     The debrief's line: "An answer is only as clear as its weakest beat: one rambling line
///     took structure from 100 to 33." Averaging would give 78 and hide the beat that lost
///     the listener;
///   - an evenly middling answer, beats 2, 2, 2: min 2 → 2 / 3 × 100 = 66.7 → **67**.
/// - **Adaptability**: the follow-up reply's adaptability score.
///
/// Each 0–3 dimension is scaled to 0–100 and rounded half up; [MissionScore.total] is those
/// four rounded scores weighted by [Dimension.weightPercent], rounded half up once more, so the
/// dossier's total can be checked by hand from the four numbers it shows. The same input always
/// gives the same score.
///
/// Throws an [ArgumentError] unless [AttemptInput.picks] is exactly one pick per beat, in beat
/// order: a malformed attempt is a bug in the caller, not a score of zero.
MissionScore scoreAttempt(AttemptInput input) {
  final beats = _beatChoices(input.picks);
  final reply = input.followUpReply;
  final answer = [...beats, reply];

  int meanOf(Dimension d) => _percent(
    answer.fold(0, (sum, c) => sum + c.scores[d]),
    answer.length * DimensionScores.max,
  );

  final dimensions = <Dimension, int>{
    Dimension.relevance: meanOf(Dimension.relevance),
    Dimension.specificity: meanOf(Dimension.specificity),
    Dimension.structure: _percent(
      beats.map((c) => c.scores.structure).reduce((a, b) => a < b ? a : b),
      DimensionScores.max,
    ),
    Dimension.adaptability: _percent(
      reply.scores.adaptability,
      DimensionScores.max,
    ),
  };

  final weighted = Dimension.values.fold(
    0,
    (sum, d) => sum + d.weightPercent * dimensions[d]!,
  );

  final shortfalls = [
    for (final beat in beats) weightedShortfall(beat, beatDimensions),
    weightedShortfall(reply, replyDimensions),
  ];

  return MissionScore(
    dimensions: Map.unmodifiable(dimensions),
    total: _roundHalfUp(weighted, _percentPoints),
    optionIdsByCost: List.unmodifiable(
      indexesByCost(shortfalls).map((i) => answer[i].optionId),
    ),
    flags: Set.unmodifiable({for (final c in answer) ...c.flags}),
  );
}

/// The beat choices in order, after checking there's exactly one per beat.
List<ScoredChoice> _beatChoices(List<BeatPick> picks) {
  final kinds = picks.map((p) => p.beat).toList();
  final inOrder =
      kinds.length == BeatKind.values.length &&
      Iterable<int>.generate(kinds.length)
          .every((i) => kinds[i] == BeatKind.values[i]);
  if (!inOrder) {
    throw ArgumentError.value(
      kinds,
      'picks',
      'needs one pick per beat, in the order ${BeatKind.values}',
    );
  }
  return [for (final p in picks) p.choice];
}

/// The weights are percentages, so a weighted sum is in hundredths of a point.
const int _percentPoints = 100;

/// [earned] out of [outOf], as 0–100 rounded half up.
int _percent(int earned, int outOf) =>
    _roundHalfUp(earned * maxMissionScore, outOf);

/// [numerator] / [denominator] rounded half up, in integers so no floating-point error can make
/// the same attempt score differently on two devices. Both are non-negative here.
int _roundHalfUp(int numerator, int denominator) =>
    (2 * numerator + denominator) ~/ (2 * denominator);

/// The trust meter after the picks so far (0–100), drawn as the heartbeat line while the
/// player answers, so it reacts within a beat rather than only at the debrief.
///
/// The exact formula, applied pick by pick:
///
/// ```text
/// trust₀ = initialTrust                                         (50)
/// pointsₖ = relevance + specificity + structure of pick k       (0–9)
/// trustₖ  = clamp(trustₖ₋₁ + trustStepPerPoint × (pointsₖ − middlingLinePoints), 0, 100)
///         = clamp(trustₖ₋₁ + 4 × (pointsₖ − 6), 0, 100)
/// ```
///
/// A middling line (2, 2, 2) leaves the meter where it was; a perfect line lifts it 12; a line
/// scoring 1, 1, 1 drops it 12; a 0, 0, 0 line drops it 24. Adaptability is left out because
/// beat lines don't carry it; a reply that dodges the follow-up already scores low on
/// relevance. The clamp is applied after every pick, so the meter is always exactly what was
/// drawn: a run that hits 0 climbs back from 0, not from a hidden debt. Worked tables for a
/// strong and a weak run are the "trust meter" tests in `scoring_test.dart`.
int trustAfter(List<ScoredChoice> picksSoFar) => picksSoFar.fold(
  initialTrust,
  (trust, pick) =>
      (trust + trustStepPerPoint * (_trustPoints(pick) - middlingLinePoints))
          .clamp(0, maxMissionScore),
);

int _trustPoints(ScoredChoice pick) =>
    beatDimensions.fold(0, (sum, d) => sum + pick.scores[d]);

/// The top of every normalised score: dimensions, mission totals and the trust meter.
const int maxMissionScore = 100;

/// Where the trust meter starts each mission: neutral, neither won nor lost.
const int initialTrust = 50;

/// The per-dimension score of a middling line: on topic and organised, but not specific.
const int middlingDimensionScore = 2;

/// The trust meter's reference line: [middlingDimensionScore] on each of relevance,
/// specificity and structure (6 of 9). A line scoring this leaves trust unchanged.
final int middlingLinePoints = middlingDimensionScore * beatDimensions.length;

/// How far the trust meter moves for each point a line is above or below
/// [middlingLinePoints]. At 4, a perfect line moves it 12 of 100: visible within one beat, and
/// four perfect lines (50 → 98) still stop short of the ceiling.
const int trustStepPerPoint = 4;
