import 'package:content/content.dart';
import 'package:engine/engine.dart';

/// One way through a mission: the beat picks, the follow-up the engine asks for them, the
/// reply, and the score.
typedef MissionPath = ({
  List<AnswerOption> picks,
  FollowUp followUp,
  AnswerOption reply,
  MissionScore score,
});

/// Every way through [mission]: each beat combination, the follow-up `selectFollowUp` picks
/// for it, and each reply to that follow-up.
List<MissionPath> allPaths(Mission mission) => [
  for (final open in mission.beats[0].options)
    for (final evidence in mission.beats[1].options)
      for (final land in mission.beats[2].options)
        ..._pathsFor(mission, [open, evidence, land]),
];

List<MissionPath> _pathsFor(Mission mission, List<AnswerOption> picks) {
  final beatPicks = [
    for (var i = 0; i < picks.length; i++)
      BeatPick(beat: BeatKind.values[i], choice: picks[i].scored),
  ];
  final followUpId = selectFollowUp(
    picks: beatPicks,
    candidates: [for (final f in mission.followUps) f.candidate],
  );
  final followUp = mission.followUps.singleWhere((f) => f.id == followUpId);
  return [
    for (final reply in followUp.replies)
      (
        picks: picks,
        followUp: followUp,
        reply: reply,
        score: scoreAttempt(
          AttemptInput(
            picks: beatPicks,
            followUpReply: reply.scored,
            hinted: mission.hinted,
          ),
        ),
      ),
  ];
}

/// Every set of lines the player chooses from in [mission]: three beats, then each follow-up's
/// replies.
List<List<AnswerOption>> optionSets(Mission mission) => [
  for (final beat in mission.beats) beat.options,
  for (final followUp in mission.followUps) followUp.replies,
];

/// Every line the player can pick in [mission].
List<AnswerOption> allOptions(Mission mission) => [
  for (final options in optionSets(mission)) ...options,
];

/// An option's points on all four dimensions.
int pointsOf(AnswerOption option) =>
    Dimension.values.fold(0, (sum, d) => sum + option.scores[d]);
