import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lookups the mission player needs over the content bundle. Content is const data, so these
/// are plain searches; a miss means a content bug, and `validateContent` already rules those
/// out for shipped content.
extension MissionLookup on Mission {
  /// Every option the player can pick in this mission: beat lines and follow-up replies.
  Iterable<AnswerOption> get allOptions sync* {
    for (final beat in beats) {
      yield* beat.options;
    }
    for (final followUp in followUps) {
      yield* followUp.replies;
    }
  }

  AnswerOption? optionById(String id) {
    for (final option in allOptions) {
      if (option.id == id) return option;
    }
    return null;
  }

  FollowUp followUpById(String id) => followUps.firstWhere((f) => f.id == id);

  /// The interviewer who asks the question: the scene's lead.
  Interviewer get lead => interviewerById(question.speakerId);

  /// The chapter's colour grade (Chapter 1 is the lobby).
  ChapterGrade get grade => ChapterGrade.values[chapter - 1];

  /// Whether this mission opens its chapter (its title card plays the chapter's sound).
  bool get opensChapter =>
      missions.firstWhere((m) => m.chapter == chapter).number == number;

  /// The last playable mission of its chapter: finishing it opens the chapter report.
  bool get closesChapter {
    final after = next;
    return after == null || after.chapter != chapter;
  }

  /// The mission after this one in campaign order, or null after the last playable one.
  Mission? get next {
    final i = missions.indexOf(this);
    return i >= 0 && i + 1 < missions.length ? missions[i + 1] : null;
  }

  /// Draft-first (FR-11) is offered on the unhinted missions, the measured ones (1, 3 and 7):
  /// the draft is what "then vs. now" sets beside a later answer, so asking on every mission
  /// would only slow the scene.
  bool get offersDraft => !hinted;
}

extension AddressedLine on SceneLine {
  /// The line as said to the player: the content's candidate name ("Hi Jordan") becomes
  /// [name] ("Hi Sami"). The answer lines stay the practice CV's, in the first person.
  SceneLine addressedTo(String name) => SceneLine(
    speakerId: speakerId,
    text: text.replaceAll(_candidateName, name),
  );
}

/// The practice candidate's first name as the interviewers say it, as a whole word.
final RegExp _candidateName = RegExp(
  '\\b${RegExp.escape(player.name.split(' ').first)}\\b',
);

Interviewer interviewerById(String id) =>
    interviewers.firstWhere((i) => i.id == id);

Lesson? lessonById(String? id) {
  if (id == null) return null;
  for (final lesson in lessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}

/// The missions the player plays: the content's. Tests override it with fixture content (the
/// why step and reactions before brief 19's content lands).
final missionCatalogProvider = Provider<List<Mission>>((ref) => missions);

/// The mission at campaign [number] (1-based) in [catalog], or null if there's none.
Mission? missionByNumber(int number, {List<Mission> catalog = missions}) {
  for (final mission in catalog) {
    if (mission.number == number) return mission;
  }
  return null;
}
