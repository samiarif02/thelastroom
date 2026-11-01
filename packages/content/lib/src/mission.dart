import 'package:engine/engine.dart';

import 'build_beat.dart';
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
    this.timed = true,
    this.isBaseline = false,
    this.skillRequirements = const [],
    this.continuity,
    this.epilogue = const [],
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

  /// Whether the soft 60-second answer timer runs (FR-13). Mission 1 is untimed (owner,
  /// 2026-10-29): the baseline measures the answer, not reading speed. Calm mode turns the
  /// timer off on any mission; that's a player setting, not content.
  final bool timed;

  /// Mission 1: its first completion is stored as the baseline every later score is compared
  /// with.
  final bool isBaseline;

  /// What this mission demands to unlock a skill. Only meaningful on an unhinted mission.
  final List<SkillRequirement> skillRequirements;

  /// Mission 6: the interviewer picks up a line from an earlier answer (FR-30). `null` on every
  /// other mission.
  final Continuity? continuity;

  /// Lines played after the debrief: Mission 7's cliffhanger before the Chapter 2 teaser.
  /// Empty on most missions.
  final List<SceneLine> epilogue;
}

/// An earlier mission's answer, carried into this one: the interviewer quotes the line that
/// cost the most and challenges it (brief §6, Mission 6).
///
/// The challenge is one extra setup line, played after [Mission.scene] and before the
/// question. The beats stay the same for every variant, so the player answers the same
/// question however they got there; only what the interviewer quotes changes.
class Continuity {
  const Continuity({required this.fromMissionId, required this.variants});

  /// The mission whose answer is challenged.
  final String fromMissionId;

  /// One per beat option of [fromMissionId] that can be the costliest beat line.
  final List<ContinuityVariant> variants;

  /// The challenge for an attempt at [fromMissionId], given its `MissionScore.optionIdsByCost`:
  /// the variant for the costliest line that has one. The follow-up reply never has one, so
  /// this is the costliest *beat* line. `null` when the earlier mission hasn't been played.
  SceneLine? lineFor(List<String> optionIdsByCost) {
    for (final optionId in optionIdsByCost) {
      for (final variant in variants) {
        if (variant.sourceOptionId == optionId) return variant.line;
      }
    }
    return null;
  }
}

/// What the interviewer says when [sourceOptionId] was the costliest line.
class ContinuityVariant {
  const ContinuityVariant({required this.sourceOptionId, required this.line});

  /// A beat option id of [Continuity.fromMissionId].
  final String sourceOptionId;
  final SceneLine line;
}

/// One subtitle: who says it and what they say (typewriter reveal, FR-10).
class SceneLine {
  const SceneLine({required this.speakerId, required this.text});

  /// An [Interviewer] id.
  final String speakerId;
  final String text;
}

/// One beat of the answer: 3–4 plausible lines to pick from (FR-12), or, when it has a
/// [build], an answer the player assembles from fragments (brief 27).
class Beat {
  const Beat({
    required this.kind,
    required this.options,
    this.why,
    this.reaction,
    this.build,
  });

  final BeatKind kind;
  final List<AnswerOption> options;

  /// "Build your answer": when set, the player taps fragments into an answer instead of
  /// picking one of [options], and there's no why step (putting the parts in order is the
  /// reasoning). [why] stays in the content for the Recall Room.
  final BuildBeat? build;

  /// The line [optionId] names: one of [options], or an answer built in [build]. Null when
  /// it's neither (a stale id from older content).
  AnswerOption? optionById(String optionId) {
    for (final o in options) {
      if (o.id == optionId) return o;
    }
    return build?.answerById(optionId);
  }

  /// After the pick the interviewer asks why (wave 5: picking at random stops paying). `null`:
  /// this beat has no why step.
  final ReasonPrompt? why;

  /// The interviewer's line straight after the pick, by how it landed. `null`: no reaction.
  final BeatReaction? reaction;

  /// THE way to build the [ReasonPick] for [reason] given after picking [optionId]. The reason
  /// only counts (can cost 40 %) on a strongest line; a weak line keeps its own points, and
  /// [Reason.tempts] tells the debrief which misconception the player fell for.
  ReasonPick reasonPick(Reason reason, String optionId) => ReasonPick(
    reasonId: reason.id,
    sound: reason.isSoundFor(optionId),
    counts: isStrongest(optionId),
  );

  /// Whether [optionId] is a strongest line of this beat: the smallest weighted shortfall on
  /// relevance, specificity and structure (the measure the debrief's red pen uses). Lines tied
  /// for best are all strongest. The mission player passes this to `judgePick`.
  ///
  /// A built answer is strongest when it scores as well as the best line: every part, in
  /// order, no decoy.
  bool isStrongest(String optionId) {
    int shortfall(AnswerOption o) =>
        weightedShortfall(o.scored, beatDimensions);
    final best = options.map(shortfall).reduce((a, b) => a < b ? a : b);
    final option = optionById(optionId);
    return option != null && shortfall(option) <= best;
  }
}

/// "Why that line?": the question and 3–4 reasons. Reasons are principles about interviewing,
/// never a restatement of a line: one is the real reason the strongest line works, the others
/// are the misconceptions that tempt people into the weak lines.
class ReasonPrompt {
  const ReasonPrompt({required this.line, required this.reasons});

  /// What the interviewer asks ("Why lead with that?").
  final SceneLine line;
  final List<Reason> reasons;
}

/// One reason the player can give for a pick.
class Reason implements Identified {
  const Reason({
    required this.id,
    required this.text,
    this.soundFor = const {},
    this.tempts = const {},
  });

  @override
  final String id;
  final String text;

  /// The option ids this reason correctly explains: only the beat's strongest line(s). Empty: a
  /// misconception, never sound.
  final Set<String> soundFor;

  /// The weak option ids this misconception leads people to, so the debrief can say "You fell
  /// for: …". Empty on the sound reason.
  final Set<String> tempts;

  /// Whether this is the right reasoning for [optionId].
  bool isSoundFor(String optionId) => soundFor.contains(optionId);

  /// Kept for compatibility. The mission player uses [Beat.reasonPick], which also knows
  /// whether the reason can cost the pick anything.
  ReasonPick pickFor(String optionId) =>
      ReasonPick(reasonId: id, sound: isSoundFor(optionId));
}

/// What the interviewer says straight after a pick, for each [PickQuality].
class BeatReaction {
  const BeatReaction({
    required this.strong,
    required this.weak,
    required this.guessed,
  });

  final SceneLine strong;
  final SceneLine weak;

  /// For a pick made before the player could have read the options.
  final SceneLine guessed;

  SceneLine forQuality(PickQuality quality) => switch (quality) {
    PickQuality.strong => strong,
    PickQuality.weak => weak,
    PickQuality.guessed => guessed,
  };
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
