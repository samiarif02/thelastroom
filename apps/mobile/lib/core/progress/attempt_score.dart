import 'package:content/content.dart';
import 'package:engine/engine.dart';

import 'progress_repository.dart';

/// Recomputes an attempt's score from its picks with the engine. A stored or restored attempt
/// keeps only what the player chose and how ([beatPlays]: the reasons and the time taken, which
/// wave 5's credits depend on); its score is always the engine's (explainable, reproducible
/// offline), and the same as the one the debrief showed. Null when the picks no longer match
/// the content (an option removed by a later content version), so a stale row is skipped,
/// never mis-scored.
MissionScore? scoreFromPicks({
  required String missionId,
  required List<String> beatOptionIds,
  required String followUpId,
  required String replyOptionId,
  required bool hinted,
  List<BeatPlayRecord> beatPlays = const [],
}) {
  final mission = _mission(missionId);
  if (mission == null || beatOptionIds.length != mission.beats.length) {
    return null;
  }
  final picks = <BeatPick>[];
  for (var i = 0; i < mission.beats.length; i++) {
    final beat = mission.beats[i];
    final option = beat.optionById(beatOptionIds[i]);
    if (option == null) return null;
    final play = i < beatPlays.length ? beatPlays[i] : const BeatPlayRecord();
    final reason = beat.why?.reasons
        .where((r) => r.id == play.reasonId)
        .firstOrNull;
    picks.add(
      BeatPick(
        beat: beat.kind,
        choice: option.scored,
        decidedIn: play.decidedIn,
        reason: switch (reason) {
          null => null,
          // A built beat asks no why; an older build could still store a reason on one (QA 51).
          // It scores as it did, so the past result never changes, but earns no reason XP.
          final r when beat.build != null =>
            beat.reasonPick(r, option.id).unasked(),
          final r => beat.reasonPick(r, option.id),
        },
      ),
    );
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

/// The engine's points for [voice]: the question's, then the follow-up's.
List<VoicePoint> voicePoints(VoicePrompt voice) => [
  for (final p in [...voice.listenFor, ...voice.followUpListenFor])
    VoicePoint(id: p.id, dimension: p.dimension),
];

/// Scores a spoken answer to [mission] that made [madePointIds], with the engine. Null when
/// [mission] isn't a voice mission.
VoiceScore? voiceScoreFor(Mission mission, Iterable<String> madePointIds) {
  final voice = mission.voice;
  if (voice == null) return null;
  return scoreVoiceAnswer(
    points: voicePoints(voice),
    made: madePointIds.toSet(),
  );
}

/// [voiceScoreFor] by mission id, for a stored voice attempt. Null when the mission is gone or
/// is no longer a voice mission (a later content version), so a stale row is skipped.
MissionScore? scoreFromVoice({
  required String missionId,
  required List<String> madePointIds,
  List<Mission> catalog = missions,
}) {
  final mission = _mission(missionId, catalog);
  if (mission == null) return null;
  return voiceScoreFor(mission, madePointIds)?.score;
}

Mission? _mission(String id, [List<Mission> catalog = missions]) {
  for (final m in catalog) {
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
