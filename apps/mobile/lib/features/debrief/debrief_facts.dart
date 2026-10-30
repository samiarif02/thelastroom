import 'package:content/content.dart';
import 'package:engine/engine.dart';

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

/// "Relevance" for [Dimension.relevance].
String dimensionLabel(Dimension d) =>
    '${d.name[0].toUpperCase()}${d.name.substring(1)}';
