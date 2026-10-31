import 'package:content/content.dart';
import 'package:engine/engine.dart';

import '../mission/mission_controller.dart';
import '../mission/mission_lookup.dart';

/// What the dossier shows for one scored attempt, read straight off the engine's
/// [MissionScore]: nothing here computes a score.
class DebriefFacts {
  const DebriefFacts({
    required this.dimensions,
    required this.total,
    required this.markedLine,
    required this.lesson,
  });

  /// From the engine's attempt score, in [Dimension] order.
  factory DebriefFacts.of(Mission mission, MissionScore score) {
    // The red pen and the lesson go to the costliest line that has a lesson (FR-15). On a run
    // with a costly-but-lessonless first line that's the next costliest; a clean run has none.
    AnswerOption? marked;
    Lesson? lesson;
    for (final id in score.optionIdsByCost) {
      final option = mission.optionById(id);
      final taught = lessonById(option?.lessonId);
      if (option != null && taught != null) {
        marked = option;
        lesson = taught;
        break;
      }
    }
    return DebriefFacts(
      dimensions: [
        for (final d in Dimension.values)
          (dimension: d, value: score.dimensions[d]!),
      ],
      total: score.total,
      markedLine: marked,
      lesson: lesson,
    );
  }

  final List<({Dimension dimension, int value})> dimensions;
  final int total;

  /// The line the red pen marks, quoted on the dossier. Null on a clean run.
  final AnswerOption? markedLine;

  /// The one lesson taught. Null on a clean run.
  final Lesson? lesson;

  /// The ledger row the pen underlines: the dimension the lesson's flag costs.
  int? get markedDimensionIndex {
    final lesson = this.lesson;
    if (lesson == null) return null;
    return Dimension.values.indexOf(lesson.flag.lowers);
  }

  /// A strong result plays the warm sting; there's never a fail sound.
  bool get strong => total >= strongFrom;

  /// The mission total at which the result counts as strong: the top two score bands.
  static const int strongFrom = 60;
}

/// The opening line that scores best in [mission]: what "A stronger version" sets beside the
/// player's own first try. Weighted like the engine's line cost; ties go to the first.
AnswerOption strongestOpening(Mission mission) {
  int worth(AnswerOption o) => [
    Dimension.relevance,
    Dimension.specificity,
    Dimension.structure,
  ].fold(0, (sum, d) => sum + d.weightPercent * o.scores[d]);
  final options = mission.beats.first.options;
  return options.reduce((best, o) => worth(o) > worth(best) ? o : best);
}

/// "Relevance" for [Dimension.relevance].
String dimensionLabel(Dimension d) =>
    '${d.name[0].toUpperCase()}${d.name.substring(1)}';

/// One beat of the answer as the debrief retells it: the line, how fast it was picked, the
/// principle the player gave, the principle that holds, and the misconception a weak line
/// fell for.
class BeatReasoning {
  const BeatReasoning({
    required this.kind,
    required this.line,
    required this.strongest,
    required this.guessed,
    this.decidedIn,
    this.given,
    this.principle,
    this.fellFor,
  });

  final BeatKind kind;
  final AnswerOption line;

  /// The line was the beat's strongest.
  final bool strongest;

  /// Picked before the player could have read the options (`BeatPick.guessed`).
  final bool guessed;
  final Duration? decidedIn;

  /// The reason the player gave; null on a beat that didn't ask why.
  final Reason? given;

  /// The beat's one sound principle; null when the beat didn't ask why.
  final Reason? principle;

  /// The misconception that leads to [line] when it's a weak one (`Reason.tempts`).
  final Reason? fellFor;

  /// Whether the player's reason is the sound principle for their line; null with no why step.
  bool? get sound => given?.isSoundFor(line.id);
}

/// The reasoning slip's rows, from the plays the controller kept, in beat order.
List<BeatReasoning> reasoningOf(Mission mission, List<BeatPlay> plays) => [
  for (var i = 0; i < plays.length; i++) _reasoning(mission.beats[i], plays[i]),
];

BeatReasoning _reasoning(Beat beat, BeatPlay play) {
  final reasons = beat.why?.reasons ?? const <Reason>[];
  final strongest = beat.isStrongest(play.option.id);
  return BeatReasoning(
    kind: beat.kind,
    line: play.option,
    strongest: strongest,
    guessed: isGuess(play.decidedIn),
    decidedIn: play.decidedIn,
    given: play.reason,
    principle: reasons.where((r) => r.soundFor.isNotEmpty).firstOrNull,
    fellFor: strongest
        ? null
        : reasons.where((r) => r.tempts.contains(play.option.id)).firstOrNull,
  );
}
