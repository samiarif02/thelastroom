import 'beat.dart';
import 'dimension.dart';
import 'flag.dart';

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
}

/// Scores one attempt, deterministically and offline (FR-20–FR-22).
///
/// - **Relevance** and **specificity**: the mean of the three beat picks and the follow-up
///   reply, on each dimension.
/// - **Structure**: the *lowest* structure score among the three beats. An answer is as well
///   built as its weakest beat, which is how "scored across beats as a whole, not per pick"
///   (FR-22) is made checkable.
/// - **Adaptability**: the follow-up reply's adaptability score.
///
/// Each 0–3 dimension is scaled to 0–100, then weighted into [MissionScore.total], rounding
/// half up. The same input always gives the same score.
MissionScore scoreAttempt(AttemptInput input) => throw UnimplementedError();

/// The trust meter after the picks so far (0–100), drawn as the heartbeat line while the
/// player answers. Starts at [initialTrust]; each pick moves it by how far the line is above or
/// below a middling one, so it reacts within a beat rather than only at the debrief.
int trustAfter(List<ScoredChoice> picksSoFar) => throw UnimplementedError();

/// The top of every normalised score: dimensions, mission totals and the trust meter.
const int maxMissionScore = 100;

/// Where the trust meter starts each mission: neutral, neither won nor lost.
const int initialTrust = 50;
