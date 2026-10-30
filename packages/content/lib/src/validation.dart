import 'package:engine/engine.dart';

import 'identified.dart';
import 'interviewer.dart';
import 'lesson.dart';
import 'mission.dart';

/// Everything the game ships, checked as one unit so cross-references can be resolved.
class ContentBundle {
  const ContentBundle({
    required this.chapters,
    required this.interviewers,
    required this.lessons,
    required this.missions,
  });

  /// All three chapters: the playable one and the locked teasers (FR-31).
  final List<Chapter> chapters;
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

/// The longest an answer line may be, in words. Lines are read on a phone mid-interview: the
/// owner's target is 20–25 words, and anything over this fails (writing note 4, 2026-10-30).
const int maxOptionWords = 30;

/// The longest an interviewer's line may be, in characters: about two subtitle lines of the
/// 22 pt serif on a 360 dp phone (DESIGN.md), so a line never needs a third.
const int maxSubtitleChars = 80;

/// The number of words in [text], split on whitespace.
int wordCount(String text) =>
    text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

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
  final lessonsById = {for (final l in bundle.lessons) l.id: l};

  void checkSpeaker(String ownerId, SceneLine line) {
    if (!interviewerIds.contains(line.speakerId)) {
      issue(ownerId, 'speaker ${line.speakerId} is not an interviewer');
    }
    if (line.text.length > maxSubtitleChars) {
      issue(
        ownerId,
        'a line by ${line.speakerId} is ${line.text.length} characters, '
        'over $maxSubtitleChars',
      );
    }
  }

  void checkWords(String id, String text) {
    final words = wordCount(text);
    if (words > maxOptionWords) {
      issue(id, 'is $words words, over $maxOptionWords');
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
      checkWords(option.id, option.text);
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
      if (lessonId != null) {
        final lesson = lessonsById[lessonId];
        if (lesson == null) {
          issue(option.id, 'lesson $lessonId does not exist');
        } else if (!option.flags.contains(lesson.flag)) {
          // The debrief shows the lesson's flaw under this line, so it must be this line's.
          issue(
            option.id,
            'teaches $lessonId, a ${lesson.flag.wireName} lesson, '
            'but is not flagged ${lesson.flag.wireName}',
          );
        }
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
    for (final option in recall.options) {
      checkId(option);
      checkWords(option.id, option.text);
    }
    if (!recall.options.any((o) => o.id == recall.correctOptionId)) {
      issue(lesson.id, 'the recall answer is not one of its options');
    }
  }

  _checkChapters(bundle, issue);

  final missionsById = {for (final m in bundle.missions) m.id: m};
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

    final continuity = mission.continuity;
    if (continuity != null) {
      _checkContinuity(mission, continuity, missionsById, issue);
      for (final variant in continuity.variants) {
        checkSpeaker(mission.id, variant.line);
      }
    }
    if (mission.epilogue.length > maxSceneLines) {
      issue(
        mission.id,
        'has ${mission.epilogue.length} epilogue lines, at most $maxSceneLines',
      );
    }
    for (final line in mission.epilogue) {
      checkSpeaker(mission.id, line);
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

/// Chapters are numbered 1, 2, 3…; every mission sits in a playable one; a playable chapter's
/// tower titles are its missions' titles, in order, and its missions are numbered without gaps.
void _checkChapters(
  ContentBundle bundle,
  void Function(String id, String problem) issue,
) {
  for (var i = 0; i < bundle.chapters.length; i++) {
    if (bundle.chapters[i].number != i + 1) {
      issue(
        'chapter ${bundle.chapters[i].number}',
        'chapters must be 1, 2, 3…',
      );
    }
  }
  final chaptersByNumber = {for (final c in bundle.chapters) c.number: c};
  for (final mission in bundle.missions) {
    final chapter = chaptersByNumber[mission.chapter];
    if (chapter == null || !chapter.playable) {
      issue(mission.id, 'chapter ${mission.chapter} is not a playable chapter');
    }
  }
  final numbers = [for (final m in bundle.missions) m.number];
  for (var i = 0; i < numbers.length; i++) {
    if (numbers[i] != i + 1) {
      issue(
        bundle.missions[i].id,
        'missions must be numbered 1, 2, 3… in order',
      );
    }
  }
  for (final chapter in bundle.chapters) {
    if (chapter.missionTitles.isEmpty) {
      issue('chapter ${chapter.number}', 'has no mission titles to tease');
    }
    if (!chapter.playable) continue;
    final titles = [
      for (final m in bundle.missions)
        if (m.chapter == chapter.number) m.title,
    ];
    final same =
        titles.length == chapter.missionTitles.length &&
        Iterable<int>.generate(titles.length)
            .every((i) => titles[i] == chapter.missionTitles[i]);
    if (!same) {
      issue(
        'chapter ${chapter.number}',
        "its mission titles don't match its missions",
      );
    }
  }
}

/// A continuity challenge quotes an earlier mission's beat line, once per line, and adds one
/// setup line that must still fit the scene.
void _checkContinuity(
  Mission mission,
  Continuity continuity,
  Map<String, Mission> missionsById,
  void Function(String id, String problem) issue,
) {
  final source = missionsById[continuity.fromMissionId];
  if (source == null || source.number >= mission.number) {
    issue(
      mission.id,
      'continuity must come from an earlier mission, not ${continuity.fromMissionId}',
    );
    return;
  }
  final beatOptionIds = {
    for (final beat in source.beats)
      for (final option in beat.options) option.id,
  };
  final quoted = <String>{};
  for (final variant in continuity.variants) {
    if (!beatOptionIds.contains(variant.sourceOptionId)) {
      issue(
        mission.id,
        '${variant.sourceOptionId} is not a beat line of ${source.id}',
      );
    }
    if (!quoted.add(variant.sourceOptionId)) {
      issue(mission.id, '${variant.sourceOptionId} is challenged twice');
    }
  }
  if (mission.scene.length + 1 > maxSceneLines) {
    issue(
      mission.id,
      'the continuity line makes ${mission.scene.length + 1} scene lines, '
      'at most $maxSceneLines',
    );
  }
}
