import 'package:engine/engine.dart';

import 'identified.dart';
import 'mission.dart';

/// "Build your answer" (brief 27): a beat the player assembles from short fragments instead of
/// picking a finished line. For a "tell me about a time" beat the [parts] are the situation,
/// the task, the action and the result, in that order; the [decoys] are the tempting pieces
/// that don't belong ("we" not "I", vague, blame).
///
/// The beat's own [Beat.options] stay: they're what the Recall Room and the why step's reasons
/// are written against. The player builds instead of picking, and the engine's [scoreBuild]
/// turns what they built into an ordinary scored line.
class BuildBeat implements Identified {
  const BuildBeat({
    required this.id,
    required this.parts,
    required this.decoys,
    required this.orderLessonId,
    required this.missingLessonId,
  });

  @override
  final String id;

  /// The strong answer's fragments, in their right order.
  final List<Fragment> parts;

  /// The fragments that don't belong. Each carries the flag of its mistake and that flag's
  /// lesson.
  final List<Fragment> decoys;

  /// The lesson taught when the order alone lost the listener ([Flag.rambling]).
  final String orderLessonId;

  /// The lesson taught when too much was left out ([Flag.vague]).
  final String missingLessonId;

  /// Every fragment, parts then decoys. The mission player shuffles them.
  List<Fragment> get fragments => [...parts, ...decoys];

  /// The engine's view: ids and flags, no words.
  BuildSpec get spec => BuildSpec(
    id: id,
    parts: [for (final p in parts) p.id],
    decoys: {for (final d in decoys) d.id: d.flags},
  );

  /// The strong answer: every part, in order. What the debrief sets beside the player's own.
  AnswerOption get strongAnswer => answerFor([for (final p in parts) p.id]);

  /// The answer built from [placed] (fragment ids, in the order tapped) as a line like any
  /// other: its words are the fragments joined, its points and flags the engine's, and its
  /// lesson the first decoy's, else the order's or the gaps'.
  AnswerOption answerFor(List<String> placed) {
    final result = scoreBuild(spec, placed);
    final choice = result.choice;
    final kept = parseBuildOptionId(choice.optionId)!.placed;
    final byId = {for (final f in fragments) f.id: f};
    String? lessonId;
    for (final id in result.decoysUsed) {
      lessonId ??= byId[id]!.lessonId;
    }
    if (lessonId == null && choice.flags.contains(Flag.rambling)) {
      lessonId = orderLessonId;
    }
    if (lessonId == null && choice.flags.contains(Flag.vague)) {
      lessonId = missingLessonId;
    }
    return AnswerOption(
      id: choice.optionId,
      text: [for (final id in kept) byId[id]!.text].join(' '),
      scores: choice.scores,
      flags: choice.flags,
      lessonId: lessonId,
    );
  }

  /// The built answer an option id names, or null when [optionId] isn't one of this build's.
  AnswerOption? answerById(String optionId) {
    final parsed = parseBuildOptionId(optionId);
    if (parsed == null || parsed.buildId != id) return null;
    return answerFor(parsed.placed);
  }
}

/// A short piece of an answer, tapped into place.
class Fragment implements Identified {
  const Fragment({
    required this.id,
    required this.text,
    this.flags = const {},
    this.lessonId,
  });

  @override
  final String id;

  /// A sentence or a clause; the built answer is the fragments joined with spaces.
  final String text;

  /// Empty on a part of the strong answer; a decoy's mistake.
  final Set<Flag> flags;

  /// A decoy's lesson; null on a part.
  final String? lessonId;
}
