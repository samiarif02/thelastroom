import 'package:engine/engine.dart';

import 'identified.dart';
import 'interviewer.dart';
import 'lesson.dart';
import 'mission.dart';

/// Everything the game ships, checked as one unit so cross-references can be resolved.
class ContentBundle {
  const ContentBundle({
    required this.interviewers,
    required this.lessons,
    required this.missions,
  });

  final List<Interviewer> interviewers;
  final List<Lesson> lessons;
  final List<Mission> missions;
}

/// One thing wrong with the content, named by the id of the item it's on.
class ContentIssue {
  const ContentIssue(this.itemId, this.problem);

  final String itemId;
  final String problem;

  @override
  String toString() => '$itemId: $problem';
}

/// The fewest and most options a beat or follow-up may offer (FR-12).
const int minOptions = 3;
const int maxOptions = 4;

/// The fewest and most setup lines before the question (FR-10).
const int minSceneLines = 1;
const int maxSceneLines = 3;

/// Every rule the content must hold. An empty list means it's valid; the content tests assert
/// exactly that, so a broken mission fails CI instead of a playthrough.
///
/// Flags need no check here: [Flag] is an enum, so an unknown flag doesn't compile.
List<ContentIssue> validateContent(ContentBundle bundle) {
  final issues = <ContentIssue>[];
  void issue(String id, String problem) =>
      issues.add(ContentIssue(id, problem));

  final seen = <String>{};
  void checkId(Identified item) {
    if (!contentIdPattern.hasMatch(item.id)) {
      issue(item.id, 'id is not snake_case');
    }
    if (!seen.add(item.id)) issue(item.id, 'id is used more than once');
  }

  final interviewerIds = {for (final i in bundle.interviewers) i.id};
  final lessonIds = {for (final l in bundle.lessons) l.id};

  void checkSpeaker(String ownerId, SceneLine line) {
    if (!interviewerIds.contains(line.speakerId)) {
      issue(ownerId, 'speaker ${line.speakerId} is not an interviewer');
    }
  }

  void checkOptions(String ownerId, List<AnswerOption> options) {
    if (options.length < minOptions || options.length > maxOptions) {
      issue(
        ownerId,
        'has ${options.length} options, needs $minOptions–$maxOptions',
      );
    }
    for (final option in options) {
      checkId(option);
      if (!option.scores.isInRange) {
        issue(
          option.id,
          'a dimension score is outside 0–${DimensionScores.max}',
        );
      }
      for (final flag in option.flags) {
        if (option.scores[flag.lowers] > flaggedDimensionCeiling) {
          issue(
            option.id,
            'flagged ${flag.wireName} but scores above $flaggedDimensionCeiling '
            'on ${flag.lowers.name}',
          );
        }
      }
      final lessonId = option.lessonId;
      if (lessonId != null && !lessonIds.contains(lessonId)) {
        issue(option.id, 'lesson $lessonId does not exist');
      }
      // A flagged line can be the costliest one, and the debrief must then teach something
      // (FR-15) and schedule a recall card for it (FR-16).
      if (option.flags.isNotEmpty && lessonId == null) {
        issue(option.id, 'is flagged but teaches no lesson');
      }
    }
  }

  bundle.interviewers.forEach(checkId);

  for (final lesson in bundle.lessons) {
    checkId(lesson);
    final recall = lesson.recall;
    recall.options.forEach(checkId);
    if (!recall.options.any((o) => o.id == recall.correctOptionId)) {
      issue(lesson.id, 'the recall answer is not one of its options');
    }
  }

  for (final mission in bundle.missions) {
    checkId(mission);
    if (mission.scene.length < minSceneLines ||
        mission.scene.length > maxSceneLines) {
      issue(
        mission.id,
        'has ${mission.scene.length} scene lines, needs $minSceneLines–$maxSceneLines',
      );
    }
    for (final line in mission.scene) {
      checkSpeaker(mission.id, line);
    }
    checkSpeaker(mission.id, mission.question);

    final kinds = mission.beats.map((b) => b.kind).toList();
    final inOrder =
        kinds.length == BeatKind.values.length &&
        Iterable<int>.generate(kinds.length)
            .every((i) => kinds[i] == BeatKind.values[i]);
    if (!inOrder) {
      issue(mission.id, 'beats must be open, evidence, land, in that order');
    }
    for (final beat in mission.beats) {
      checkOptions('${mission.id} ${beat.kind.name} beat', beat.options);
    }

    final defaults = mission.followUps.where((f) => f.trigger == null).length;
    if (defaults != 1) {
      issue(mission.id, 'needs exactly one default follow-up, has $defaults');
    }
    final triggers = mission.followUps
        .map((f) => f.trigger)
        .whereType<Flag>()
        .toList();
    if (triggers.toSet().length != triggers.length) {
      issue(mission.id, 'two follow-ups answer the same flag');
    }
    for (final followUp in mission.followUps) {
      checkId(followUp);
      checkSpeaker(followUp.id, followUp.line);
      checkOptions(followUp.id, followUp.replies);
    }

    if (mission.isBaseline && (mission.hinted || mission.timed)) {
      issue(mission.id, 'the baseline must be unhinted and untimed');
    }
    if (mission.hinted && mission.skillRequirements.isNotEmpty) {
      issue(mission.id, 'a hinted mission can never unlock a skill');
    }
    for (final requirement in mission.skillRequirements) {
      if (requirement.minScore < 0 || requirement.minScore > maxMissionScore) {
        issue(
          mission.id,
          '${requirement.skill.wireName} needs a minimum within 0–$maxMissionScore',
        );
      }
    }
  }
  return issues;
}
