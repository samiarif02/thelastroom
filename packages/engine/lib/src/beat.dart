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
  const BeatPick({
    required this.beat,
    required this.choice,
    this.decidedIn,
    this.reason,
  });

  final BeatKind beat;
  final ScoredChoice choice;

  /// How long the options were on screen before the player picked. The engine never reads a
  /// clock: the player measures it. `null` when not measured (an attempt saved before wave 5).
  final Duration? decidedIn;

  /// The player's answer when the interviewer asked "why that line?". `null` when the beat has
  /// no why step.
  final ReasonPick? reason;

  /// Picked faster than a person can read the options: a guess (see [guessThreshold]).
  bool get guessed => isGuess(decidedIn);
}

/// The reason the player gave for a pick, and whether it's the right reasoning for that pick.
class ReasonPick {
  const ReasonPick({
    required this.reasonId,
    required this.sound,
    this.counts = true,
  });

  /// The content id of the reason, for the debrief and analytics.
  final String reasonId;
  final bool sound;

  /// Whether the reason can cost points: only on a strongest line, where the wrong principle
  /// means the player got lucky. A weak line keeps its own (low) points whatever the reason;
  /// the debrief explains the misconception instead. Content's `Beat.reasonPick` sets it.
  final bool counts;
}

/// Picks made sooner than this after the options appear are guesses: nobody reads three
/// interview answers in under a second and a half.
const Duration guessThreshold = Duration(milliseconds: 1500);

bool isGuess(Duration? decidedIn) =>
    decidedIn != null && decidedIn < guessThreshold;

/// How the interviewer takes one pick, for her live reaction in the scene.
enum PickQuality { strong, weak, guessed }

/// The quality of one pick: a guess is a guess whatever it picked; otherwise a strong line
/// with a sound reason (or no why step) is strong. Brief 19 may refine the rule; the
/// signature is the contract with the mission player (brief 18).
PickQuality judgePick(BeatPick pick, {required bool strongestOption}) {
  if (pick.guessed) return PickQuality.guessed;
  final reasonOk = pick.reason?.sound ?? true;
  return strongestOption && reasonOk ? PickQuality.strong : PickQuality.weak;
}
