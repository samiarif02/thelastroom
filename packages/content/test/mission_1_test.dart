import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  const mission = missionTheOpportunity;

  /// Every way through the mission: each beat combination, the follow-up the engine picks for
  /// it, and each reply to that follow-up.
  final paths = [
    for (final open in mission.beats[0].options)
      for (final evidence in mission.beats[1].options)
        for (final land in mission.beats[2].options)
          ...() {
            final picks = [
              BeatPick(beat: BeatKind.open, choice: open.scored),
              BeatPick(beat: BeatKind.evidence, choice: evidence.scored),
              BeatPick(beat: BeatKind.land, choice: land.scored),
            ];
            final followUpId = selectFollowUp(
              picks: picks,
              candidates: [for (final f in mission.followUps) f.candidate],
            );
            final followUp = mission.followUps.singleWhere(
              (f) => f.id == followUpId,
            );
            return [
              for (final reply in followUp.replies)
                (
                  followUpId: followUpId,
                  score: scoreAttempt(
                    AttemptInput(
                      picks: picks,
                      followUpReply: reply.scored,
                      hinted: mission.hinted,
                    ),
                  ),
                ),
            ];
          }(),
  ];
  final totals = [for (final p in paths) p.score.total];

  final allOptions = [
    for (final beat in mission.beats) ...beat.options,
    for (final followUp in mission.followUps) ...followUp.replies,
  ];

  test('the shipped content passes validateContent', () {
    expect(validateContent(gameContent), isEmpty);
  });

  test('Mission 1 is the unhinted, untimed baseline (FR-13, FR-30)', () {
    expect(mission.isBaseline, isTrue);
    expect(mission.hinted, isFalse);
    expect(mission.timed, isFalse);
    expect(mission.chapter, 1);
    expect(mission.number, 1);
    expect(gameContent.missions.first, same(mission));
  });

  test('Priya says every line', () {
    final speakers = {
      for (final line in mission.scene) line.speakerId,
      mission.question.speakerId,
      for (final followUp in mission.followUps) followUp.line.speakerId,
    };
    expect(speakers, {priya.id});
  });

  test('the best line scores at least 90, the worst at most 30', () {
    // So the baseline has room to show growth either way.
    expect(totals.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(90));
    expect(totals.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(30));
  });

  test('every follow-up can actually be asked', () {
    final asked = {for (final p in paths) p.followUpId};
    expect(asked, {for (final f in mission.followUps) f.id});
  });

  test('every flag the mission can raise has its lesson', () {
    // The lesson each flag teaches in Chapter 1. A line with two flags teaches the first.
    const lessonFor = {
      Flag.generic: 'lesson_why_this_role',
      Flag.offQuestion: 'lesson_answer_the_question',
      Flag.memorized: 'lesson_talk_like_yourself',
      Flag.weNotI: 'lesson_name_your_part',
      Flag.vague: 'lesson_be_concrete',
      Flag.rambling: 'lesson_one_story',
    };
    final raised = {for (final o in allOptions) ...o.flags};
    expect(lessonFor.keys, containsAll(raised));
    final lessonIds = {for (final l in gameContent.lessons) l.id};
    for (final flag in raised) {
      expect(lessonIds, contains(lessonFor[flag]));
      expect(
        allOptions.any(
          (o) => o.flags.contains(flag) && o.lessonId == lessonFor[flag],
        ),
        isTrue,
        reason: '${flag.wireName} is never taught',
      );
    }
    for (final option in allOptions.where((o) => o.flags.isNotEmpty)) {
      expect(option.lessonId, lessonFor[option.flags.first], reason: option.id);
    }
  });

  test('every beat and follow-up offers one unflagged best line', () {
    for (final options in [
      for (final beat in mission.beats) beat.options,
      for (final followUp in mission.followUps) followUp.replies,
    ]) {
      final unflagged = options.where((o) => o.flags.isEmpty).toList();
      expect(unflagged, hasLength(1));
      int sum(AnswerOption o) =>
          Dimension.values.fold(0, (s, d) => s + o.scores[d]);
      for (final distractor in options.where((o) => o.flags.isNotEmpty)) {
        expect(sum(distractor), lessThan(sum(unflagged.single)));
      }
    }
  });

  test('beat lines carry no adaptability: only the reply earns it', () {
    for (final beat in mission.beats) {
      for (final option in beat.options) {
        expect(option.scores.adaptability, 0, reason: option.id);
      }
    }
  });
}
