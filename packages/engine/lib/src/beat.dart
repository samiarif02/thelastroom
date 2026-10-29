import 'dimension_scores.dart';
import 'flag.dart';

/// The three beats an answer is built from, in the order they're played (FR-12).
enum BeatKind { open, evidence, land }

/// What the engine needs to know about one line the player picked: its points and flags.
/// The text stays in `packages/content`; the engine never sees words.
class ScoredChoice {
  const ScoredChoice({
    required this.optionId,
    required this.scores,
    this.flags = const {},
  });

  /// The content id of the option, so a result can point back at the line (red pen, recall).
  final String optionId;
  final DimensionScores scores;
  final Set<Flag> flags;
}

/// A pick made in one beat of the answer.
class BeatPick {
  const BeatPick({required this.beat, required this.choice});

  final BeatKind beat;
  final ScoredChoice choice;
}
