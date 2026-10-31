import 'beat.dart';
import 'dimension.dart';
import 'dimension_scores.dart';
import 'pick_credit.dart';

/// The dimensions a beat pick counts towards. Adaptability isn't one: only the follow-up reply
/// earns it (brief §4).
const Set<Dimension> beatDimensions = {
  Dimension.relevance,
  Dimension.specificity,
  Dimension.structure,
};

/// The dimensions the follow-up reply counts towards. Structure isn't one: it's scored across
/// the three beats as a whole (FR-22).
const Set<Dimension> replyDimensions = {
  Dimension.relevance,
  Dimension.specificity,
  Dimension.adaptability,
};

/// How far [choice] falls short of a perfect line on the [counted] dimensions, each point
/// weighted by its dimension's [Dimension.weightPercent]. 0 is a perfect line.
///
/// One measure ranks both the follow-up's target (the weakest beat) and the debrief's red pen
/// (the costliest line), so the interviewer always probes the line the dossier marks.
int weightedShortfall(ScoredChoice choice, Set<Dimension> counted) =>
    counted.fold(
      0,
      (sum, d) =>
          sum + d.weightPercent * (DimensionScores.max - choice.scores[d]),
    );

/// [weightedShortfall] after a pick's credit: [choice]'s points kept at [keepPercent], in
/// hundredths of a point so 60 % of a 1 stays exact. With full credit it is exactly
/// `weightedShortfall × 100`, so the order of lines from attempts saved before wave 5 is
/// unchanged.
int creditedShortfall(
  ScoredChoice choice,
  Set<Dimension> counted, {
  int keepPercent = fullCreditPercent,
}) => counted.fold(
  0,
  (sum, d) =>
      sum +
      d.weightPercent *
          (DimensionScores.max * fullCreditPercent -
              choice.scores[d] * keepPercent),
);

/// The indexes of [shortfalls], costliest first. Ties keep their original order, so the
/// earliest pick wins (Dart's `List.sort` isn't stable, hence the index tie-break).
List<int> indexesByCost(List<int> shortfalls) =>
    List<int>.generate(shortfalls.length, (i) => i)..sort((a, b) {
      final byCost = shortfalls[b].compareTo(shortfalls[a]);
      return byCost != 0 ? byCost : a.compareTo(b);
    });
