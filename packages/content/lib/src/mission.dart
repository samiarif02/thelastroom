import 'package:engine/engine.dart';

import 'identified.dart';

/// One of the three campaign chapters: a floor of the tower (brief §6).
class Chapter {
  const Chapter({
    required this.number,
    required this.title,
    required this.missionTitles,
    required this.playable,
  });

  final int number;
  final String title;

  /// Shown on the tower even while the chapter is locked: the tease (FR-31).
  final List<String> missionTitles;

  /// `false` for Chapters 2–3 in v1: visible, locked, teased.
  final bool playable;
}

/// One interview moment (FR-10–FR-16): a scene, a question, an answer built in three beats, a
/// follow-up and a lesson.
class Mission implements Identified {
  const Mission({
    required this.id,
    required this.chapter,
    required this.number,
    required this.title,
    required this.scene,
    required this.question,
    required this.beats,
    required this.followUps,
    required this.hinted,
    this.isBaseline = false,
    this.skillRequirements = const [],
  });

  @override
  final String id;
  final int chapter;

  /// The mission's place in the campaign, 1–21.
  final int number;
  final String title;

  /// 1–3 setup lines before the question (FR-10).
  final List<SceneLine> scene;
  final SceneLine question;

  /// Exactly three, in [BeatKind] order.
  final List<Beat> beats;

  /// Exactly one default (no trigger), plus at most one per flag.
  final List<FollowUp> followUps;

  /// Whether hint cards are offered. Mission 1 (baseline), Mission 3 (recall checkpoint) and
  /// Mission 7 (review) are unhinted (FR-30).
  final bool hinted;

  /// Mission 1: its first completion is stored as the baseline every later score is compared
  /// with.
  final bool isBaseline;

  /// What this mission demands to unlock a skill. Only meaningful on an unhinted mission.
  final List<SkillRequirement> skillRequirements;
}

/// One subtitle: who says it and what they say (typewriter reveal, FR-10).
class SceneLine {
  const SceneLine({required this.speakerId, required this.text});

  /// An [Interviewer] id.
  final String speakerId;
  final String text;
}

/// One beat of the answer: 3–4 plausible lines to pick from (FR-12).
class Beat {
  const Beat({required this.kind, required this.options});

  final BeatKind kind;
  final List<AnswerOption> options;
}

/// A line the player can pick. Distractors are realistic mistakes, never jokes (FR-12).
class AnswerOption implements Identified {
  const AnswerOption({
    required this.id,
    required this.text,
    required this.scores,
    this.flags = const {},
    this.lessonId,
  });

  @override
  final String id;
  final String text;
  final DimensionScores scores;
  final Set<Flag> flags;

  /// The lesson the debrief teaches when this is the costliest line, and the Recall Room card
  /// it schedules. `null` on a strong line.
  final String? lessonId;

  /// The engine's view of this option: points and flags, no text.
  ScoredChoice get scored =>
      ScoredChoice(optionId: id, scores: scores, flags: flags);
}

/// The interviewer's reaction to the weakest part of the answer (FR-14).
class FollowUp implements Identified {
  const FollowUp({
    required this.id,
    required this.line,
    required this.replies,
    this.trigger,
  });

  @override
  final String id;

  /// What the interviewer asks ("What did *you* specifically do?").
  final SceneLine line;

  /// 3–4 replies, scored like any option; their adaptability is the mission's.
  final List<AnswerOption> replies;

  /// The flag this follow-up answers; `null` for the mission's default.
  final Flag? trigger;

  FollowUpCandidate get candidate =>
      FollowUpCandidate(id: id, trigger: trigger);
}
