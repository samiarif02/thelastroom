import 'beat.dart';
import 'dimension.dart';
import 'dimension_scores.dart';
import 'flag.dart';

/// A "build your answer" beat as the engine sees it (brief 27): the parts of the strong answer
/// in their right order, and the decoys. Ids only; the words stay in `packages/content`.
///
/// Instead of picking one of 3–4 finished lines, the player taps short fragments into an
/// answer. [scoreBuild] turns what they built into an ordinary [ScoredChoice], so everything
/// after the beat (the trust meter, [scoreAttempt], the follow-up, the red pen) is unchanged.
class BuildSpec {
  const BuildSpec({
    required this.id,
    required this.parts,
    required this.decoys,
  });

  /// The content id of the build, the prefix of every built answer's option id.
  final String id;

  /// The fragments of the strong answer, in their right order (for a "tell me about a time"
  /// beat: situation, task, action, result).
  final List<String> parts;

  /// The tempting fragments that don't belong (vague, "we" not "I", blame), each with the
  /// flags it carries.
  final Map<String, Set<Flag>> decoys;
}

/// How a built answer scored, and why: every point lost is one of these counts.
class BuildResult {
  const BuildResult({
    required this.choice,
    required this.missing,
    required this.outOfOrder,
    required this.decoysUsed,
  });

  /// The built answer as a scored line: [buildOptionId], its points and flags.
  final ScoredChoice choice;

  /// Parts of the strong answer left out: each costs a point of specificity.
  final int missing;

  /// Parts placed out of their right order (the fewest that would have to move): each costs a
  /// point of structure.
  final int outOfOrder;

  /// The decoys the player put in, in the order placed.
  final List<String> decoysUsed;

  /// All the parts, in order, no decoy: the strong answer.
  bool get perfect => missing == 0 && outOfOrder == 0 && decoysUsed.isEmpty;
}

/// Scores the answer the player built from [placed] (fragment ids, in the order tapped), out
/// of [spec]. Pure and deterministic, like every other score.
///
/// The rules, each worth a point on one dimension, so the debrief can say exactly why:
///
/// - **Specificity**: 3, minus one for each part of the strong answer left out. An answer with
///   no result is a story with a detail missing.
/// - **Structure**: 3, minus one for each part out of order: the parts that would have to move
///   for the rest to read in order (the placed parts minus their longest run in the right
///   order). Result before action is one out of order: 2. A whole answer backwards is three: 0.
/// - **Relevance**: 3.
/// - **A decoy** holds the dimension its flag lowers at [flaggedDimensionCeiling] (a "we" decoy:
///   specificity at most 1), the same ceiling the content validator holds a flagged line to.
/// - With no part of the strong answer placed at all, every dimension is 0.
/// - Adaptability is 0: beats never earn it.
///
/// The flags are the decoys', plus [Flag.rambling] when the order alone brought structure to
/// the ceiling (two or more out of order) and [Flag.vague] when missing parts brought
/// specificity there, so the follow-up and the lesson work as they do for a picked line.
///
/// Fragment ids that are neither a part nor a decoy, and repeats, are ignored: the mission
/// player can't produce them, and a stale stored attempt must not crash a score.
BuildResult scoreBuild(BuildSpec spec, List<String> placed) {
  final seen = <String>{};
  final kept = [
    for (final id in placed)
      if ((spec.parts.contains(id) || spec.decoys.containsKey(id)) &&
          seen.add(id))
        id,
  ];
  final partOrder = [
    for (final id in kept)
      if (spec.parts.contains(id)) spec.parts.indexOf(id),
  ];
  final decoysUsed = [
    for (final id in kept)
      if (spec.decoys.containsKey(id)) id,
  ];
  final missing = spec.parts.length - partOrder.length;
  final outOfOrder = partOrder.length - _longestRising(partOrder);
  final decoyFlags = {for (final id in decoysUsed) ...spec.decoys[id]!};

  const max = DimensionScores.max;
  final empty = partOrder.isEmpty;
  final specificity = empty ? 0 : (max - missing).clamp(0, max);
  final structure = empty ? 0 : (max - outOfOrder).clamp(0, max);
  final flags = {
    ...decoyFlags,
    if (!empty && outOfOrder > 0 && structure <= flaggedDimensionCeiling)
      Flag.rambling,
    if (!empty && missing > 0 && specificity <= flaggedDimensionCeiling)
      Flag.vague,
  };
  int capped(int score, Dimension d) =>
      flags.any((f) => f.lowers == d) && score > flaggedDimensionCeiling
      ? flaggedDimensionCeiling
      : score;
  return BuildResult(
    choice: ScoredChoice(
      optionId: buildOptionId(spec.id, kept),
      scores: DimensionScores(
        relevance: empty ? 0 : capped(max, Dimension.relevance),
        specificity: capped(specificity, Dimension.specificity),
        structure: capped(structure, Dimension.structure),
        adaptability: 0,
      ),
      flags: Set.unmodifiable(flags),
    ),
    missing: missing,
    outOfOrder: outOfOrder,
    decoysUsed: List.unmodifiable(decoysUsed),
  );
}

/// The length of the longest strictly rising run (not necessarily adjacent) in [xs]: the most
/// parts that already read in the right order. Four parts at most, so the quadratic is fine.
int _longestRising(List<int> xs) {
  final best = List<int>.filled(xs.length, 1);
  for (var i = 0; i < xs.length; i++) {
    for (var j = 0; j < i; j++) {
      if (xs[j] < xs[i] && best[j] + 1 > best[i]) best[i] = best[j] + 1;
    }
  }
  return xs.isEmpty ? 0 : best.reduce((a, b) => a > b ? a : b);
}

/// Separates a build's id from the fragments in a built answer's option id.
const String buildIdSeparator = '=';

/// Separates the fragment ids in a built answer's option id.
const String buildPieceSeparator = '+';

/// The option id of the answer built from [placed] in build [buildId]:
/// `m04_evidence_build=m04_b_situation+m04_b_action`. Content ids are snake_case, so the
/// separators can't appear in them, and the id alone is enough to score the answer again
/// offline from a stored attempt.
String buildOptionId(String buildId, List<String> placed) =>
    '$buildId$buildIdSeparator${placed.join(buildPieceSeparator)}';

/// Reads a [buildOptionId] back: the build's id and the fragments in order, or null when
/// [optionId] isn't a built answer (an ordinary option id).
({String buildId, List<String> placed})? parseBuildOptionId(String optionId) {
  final at = optionId.indexOf(buildIdSeparator);
  if (at < 0) return null;
  final rest = optionId.substring(at + 1);
  return (
    buildId: optionId.substring(0, at),
    placed: rest.isEmpty ? const [] : rest.split(buildPieceSeparator),
  );
}
