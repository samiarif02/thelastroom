import 'package:content/content.dart';
import 'package:engine/engine.dart';

/// Recomputes an attempt's score from its picks with the engine. A stored or restored attempt
/// keeps only what the player chose; its score is always the engine's (explainable,
/// reproducible offline). Null when the picks no longer match the content (an option removed by
/// a later content version), so a stale row is skipped, never mis-scored.
MissionScore? scoreFromPicks({
  required String missionId,
  required List<String> beatOptionIds,
  required String followUpId,
  required String replyOptionId,
  required bool hinted,
}) {
  final mission = _mission(missionId);
  if (mission == null || beatOptionIds.length != mission.beats.length) {
    return null;
  }
  final picks = <BeatPick>[];
  for (var i = 0; i < mission.beats.length; i++) {
    final beat = mission.beats[i];
    final option = _option(beat.options, beatOptionIds[i]);
    if (option == null) return null;
    picks.add(BeatPick(beat: beat.kind, choice: option.scored));
  }
  FollowUp? followUp;
  for (final f in mission.followUps) {
    if (f.id == followUpId) followUp = f;
  }
  final reply = followUp == null
      ? null
      : _option(followUp.replies, replyOptionId);
  if (reply == null) return null;
  return scoreAttempt(
    AttemptInput(picks: picks, followUpReply: reply.scored, hinted: hinted),
  );
}

Mission? _mission(String id) {
  for (final m in missions) {
    if (m.id == id) return m;
  }
  return null;
}

AnswerOption? _option(List<AnswerOption> options, String id) {
  for (final o in options) {
    if (o.id == id) return o;
  }
  return null;
}
