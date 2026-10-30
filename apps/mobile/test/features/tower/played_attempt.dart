import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';

import '../mission/mission_harness.dart';

/// An attempt at [mission] picking option [pick] of every beat and reply, scored by the engine.
AttemptRecord playedAttempt(Mission mission, {int pick = 0, int attempt = 1}) {
  final followUp = mission.followUps.first;
  return AttemptRecord(
    missionId: mission.id,
    attemptNumber: attempt,
    seed: testSeed,
    beatOptionIds: [for (final b in mission.beats) b.options[pick].id],
    followUpId: followUp.id,
    replyOptionId: followUp.replies[pick].id,
    hinted: mission.hinted,
    score: scoreAttempt(
      AttemptInput(
        picks: [
          for (final b in mission.beats)
            BeatPick(beat: b.kind, choice: b.options[pick].scored),
        ],
        followUpReply: followUp.replies[pick].scored,
        hinted: mission.hinted,
      ),
    ),
  );
}
