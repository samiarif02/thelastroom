import 'package:engine/engine.dart';

/// A scored line with the given points: relevance, specificity, structure, adaptability.
ScoredChoice line(
  String id,
  int relevance,
  int specificity,
  int structure, [
  int adaptability = 0,
  Set<Flag> flags = const {},
]) => ScoredChoice(
  optionId: id,
  scores: DimensionScores(
    relevance: relevance,
    specificity: specificity,
    structure: structure,
    adaptability: adaptability,
  ),
  flags: flags,
);

/// A line scoring [score] on every dimension.
ScoredChoice even(String id, int score, {Set<Flag> flags = const {}}) =>
    line(id, score, score, score, score, flags);

/// Three beat choices, in beat order.
List<BeatPick> beatsOf(List<ScoredChoice> choices) => [
  for (var i = 0; i < choices.length; i++)
    BeatPick(beat: BeatKind.values[i], choice: choices[i]),
];

/// An unhinted attempt from three beat choices and a reply.
AttemptInput attempt(
  List<ScoredChoice> beats,
  ScoredChoice reply, {
  bool hinted = false,
}) => AttemptInput(picks: beatsOf(beats), followUpReply: reply, hinted: hinted);
