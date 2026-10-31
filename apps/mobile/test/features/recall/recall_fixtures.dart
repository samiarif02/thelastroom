import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';

const Mission m1 = missionTheOpportunity;

/// The default follow-up of Mission 1 and its weak, lesson-teaching reply.
FollowUp get m1Default => m1.followUps.firstWhere((f) => f.trigger == null);
AnswerOption get m1WeakReply =>
    m1Default.replies.firstWhere((r) => r.lessonId != null);
AnswerOption get m1BestReply =>
    m1Default.replies.firstWhere((r) => r.lessonId == null);

String strongestOf(Beat beat) =>
    beat.options.firstWhere((o) => beat.isStrongest(o.id)).id;

/// The first weak line of [beat], and the misconception that tempts it.
(String, Reason) weakOf(Beat beat) {
  final weak = beat.options.firstWhere((o) => !beat.isStrongest(o.id)).id;
  final trap = beat.why!.reasons.firstWhere((r) => r.tempts.contains(weak));
  return (weak, trap);
}

const MissionScore _anyScore = MissionScore(
  dimensions: {},
  total: 0,
  optionIdsByCost: [],
  flags: {},
);

/// A Mission 1 attempt with the given beat picks and reply.
AttemptRecord m1Attempt(
  List<String> beatOptionIds, {
  String? replyOptionId,
  int number = 1,
}) => AttemptRecord(
  missionId: m1.id,
  attemptNumber: number,
  seed: 1,
  beatOptionIds: beatOptionIds,
  followUpId: m1Default.id,
  replyOptionId: replyOptionId ?? m1BestReply.id,
  score: _anyScore,
  hinted: false,
);
