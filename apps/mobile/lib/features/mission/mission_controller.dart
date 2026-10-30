import 'dart:async';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/progress/progress_repository.dart';
import 'mission_lookup.dart';

/// A new attempt's shuffle seed. The only randomness in a mission, drawn once per attempt and
/// stored with it; tests override it to pin the order.
final attemptSeedProvider = Provider<int Function()>((ref) {
  final random = math.Random();
  return () => random.nextInt(_seedRange);
});

/// Seeds are 31-bit, so they're the same number on the VM and the web.
const int _seedRange = 0x7FFFFFFF;

/// One attempt at a mission, as far as it has got. Everything here is game state: the scene's
/// camera, typing and timing are the screen's own.
class MissionState {
  const MissionState({
    required this.mission,
    required this.seed,
    required this.attemptNumber,
    required this.scene,
    this.picks = const [],
    this.draftDone = false,
    this.followUp,
    this.reply,
    this.score,
  });

  final Mission mission;
  final int seed;

  /// 1 on the player's first attempt at this mission.
  final int attemptNumber;

  /// The setup lines, plus Mission 6's callback to an earlier answer when there is one.
  final List<SceneLine> scene;

  /// The lines locked in so far, one per beat, in beat order.
  final List<AnswerOption> picks;
  final bool draftDone;
  final FollowUp? followUp;
  final AnswerOption? reply;
  final MissionScore? score;

  /// The beat being answered: 0 open, 1 evidence, 2 land; 3 once all are locked.
  int get beatIndex => picks.length;
  bool get beatsDone => picks.length == mission.beats.length;
  Beat? get beat => beatsDone ? null : mission.beats[beatIndex];

  /// The current beat's options in this attempt's order, never the file's.
  List<AnswerOption> get beatOptions =>
      beatsDone ? const [] : optionsForBeat(beatIndex);

  /// Beat [index]'s options in this attempt's order: the same order every time it's asked,
  /// so the screen can keep showing a beat after its line is locked.
  List<AnswerOption> optionsForBeat(int index) =>
      shuffled(mission.beats[index].options, seed: seed, salt: index);

  /// The follow-up's replies in this attempt's order.
  List<AnswerOption> get replyOptions {
    final followUp = this.followUp;
    if (followUp == null) return const [];
    return shuffled(followUp.replies, seed: seed, salt: mission.beats.length);
  }

  /// The trust meter, from the engine (`trustAfter`).
  int get trust => trustAfter([for (final p in picks) p.scored]);

  MissionState _copy({
    List<AnswerOption>? picks,
    bool? draftDone,
    FollowUp? followUp,
    AnswerOption? reply,
    MissionScore? score,
  }) => MissionState(
    mission: mission,
    seed: seed,
    attemptNumber: attemptNumber,
    scene: scene,
    picks: picks ?? this.picks,
    draftDone: draftDone ?? this.draftDone,
    followUp: followUp ?? this.followUp,
    reply: reply ?? this.reply,
    score: score ?? this.score,
  );
}

/// The mission being played, keyed by campaign number. The engine scores, picks the follow-up
/// and moves the trust meter; this only keeps the picks, stores the attempt and records events.
final missionControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MissionController, MissionState, int>(
      MissionController.new,
      // A missing mission or a failed load won't fix itself by retrying.
      retry: (_, _) => null,
    );

class MissionController extends AsyncNotifier<MissionState> {
  MissionController(this.number);

  final int number;

  bool _started = false;
  bool _completing = false;
  String? _draft;

  Analytics get _analytics => ref.read(analyticsProvider);
  ProgressRepository get _progress => ref.read(progressRepositoryProvider);

  @override
  Future<MissionState> build() async {
    // A rebuild is a new attempt (Riverpod keeps the notifier between builds).
    _started = false;
    _completing = false;
    _draft = null;
    final mission = missionByNumber(number);
    if (mission == null) throw MissionNotFound(number);
    final previous = await _progress.attempts(missionId: mission.id);
    return MissionState(
      mission: mission,
      seed: ref.read(attemptSeedProvider)(),
      attemptNumber: previous.length + 1,
      scene: [...mission.scene, ?await _continuityLine(mission)],
    );
  }

  /// Mission 6 quotes the costliest line of the latest attempt at the mission it calls back to.
  Future<SceneLine?> _continuityLine(Mission mission) async {
    final continuity = mission.continuity;
    if (continuity == null) return null;
    final earlier = await _progress.attempts(
      missionId: continuity.fromMissionId,
    );
    if (earlier.isEmpty) return null;
    return continuity.lineFor(earlier.last.score.optionIdsByCost);
  }

  MissionState get _now => state.requireValue;

  /// The first line starts: `mission_started`, once per attempt.
  void sceneStarted() {
    if (_started || !state.hasValue) return;
    _started = true;
    _analytics.track(AnalyticsEvent.missionStarted, {
      'mission_id': EventValue.id(_now.mission),
      'chapter': EventValue.count(_now.mission.chapter),
      'attempt_number': EventValue.count(_now.attemptNumber),
    });
  }

  /// The draft-first step is left (FR-11). [text] null or blank is a skip. The words stay in
  /// the attempt on the device; the event says only whether it was skipped.
  void finishDraft(String? text) {
    if (_now.draftDone) return;
    final draft = text?.trim();
    _draft = draft == null || draft.isEmpty ? null : draft;
    _analytics.track(AnalyticsEvent.draftCompleted, {
      'mission_id': EventValue.id(_now.mission),
      'skipped': EventValue.flag(_draft == null),
    });
    state = AsyncData(_now._copy(draftDone: true));
  }

  /// Locks [option] in as the current beat's line. After the third, the engine picks the
  /// interviewer's follow-up from the weakest line.
  void lock(AnswerOption option) {
    final now = _now;
    if (now.beatsDone || !now.beatOptions.contains(option)) return;
    final picks = [...now.picks, option];
    FollowUp? followUp;
    if (picks.length == now.mission.beats.length) {
      followUp = now.mission.followUpById(
        selectFollowUp(
          picks: _beatPicks(now.mission, picks),
          candidates: [for (final f in now.mission.followUps) f.candidate],
        ),
      );
    }
    state = AsyncData(now._copy(picks: picks, followUp: followUp));
  }

  /// The soft timer ran out on the current beat (FR-13). Nothing is forced and no score moves.
  void timerExpired() {
    final beat = _now.beat;
    if (beat == null || !_now.mission.timed) return;
    _analytics.track(AnalyticsEvent.answerTimerExpired, {
      'mission_id': EventValue.id(_now.mission),
      'beat': EventValue.name(beat.kind),
    });
  }

  /// The reply to the follow-up is locked: the engine scores the attempt, the attempt is stored
  /// and the debrief's events fire.
  Future<void> answerFollowUp(AnswerOption reply) async {
    final now = _now;
    final followUp = now.followUp;
    if (_completing || followUp == null || !now.replyOptions.contains(reply)) {
      return;
    }
    _completing = true;
    _analytics.track(AnalyticsEvent.followUpAnswered, {
      'mission_id': EventValue.id(now.mission),
      'follow_up_id': EventValue.id(followUp),
    });
    final score = scoreAttempt(
      AttemptInput(
        picks: _beatPicks(now.mission, now.picks),
        followUpReply: reply.scored,
        hinted: now.mission.hinted,
      ),
    );
    // The dossier shows at once; storing never holds the scene up.
    state = AsyncData(now._copy(reply: reply, score: score));

    final firstEver = (await _progress.attempts()).isEmpty;
    final firstBaseline =
        now.mission.isBaseline && await _progress.baseline() == null;
    await _progress.recordAttempt(
      AttemptRecord(
        missionId: now.mission.id,
        attemptNumber: now.attemptNumber,
        seed: now.seed,
        beatOptionIds: [for (final p in now.picks) p.id],
        followUpId: followUp.id,
        replyOptionId: reply.id,
        score: score,
        hinted: now.mission.hinted,
        draft: _draft,
      ),
    );
    final bucket = EventValue.name(ScoreBucket.of(score.total));
    _analytics.track(AnalyticsEvent.missionCompleted, {
      'mission_id': EventValue.id(now.mission),
      'chapter': EventValue.count(now.mission.chapter),
      'score_bucket': bucket,
      'attempt_number': EventValue.count(now.attemptNumber),
    });
    if (firstBaseline) {
      _analytics.track(AnalyticsEvent.baselineRecorded, {
        'score_bucket': bucket,
      });
    }
    if (firstEver) _analytics.track(AnalyticsEvent.userActivated);
  }
}

List<BeatPick> _beatPicks(Mission mission, List<AnswerOption> picks) => [
  for (var i = 0; i < picks.length; i++)
    BeatPick(beat: mission.beats[i].kind, choice: picks[i].scored),
];

/// The route named a mission that doesn't exist (a stale deep link).
class MissionNotFound implements Exception {
  const MissionNotFound(this.number);

  final int number;

  @override
  String toString() => 'MissionNotFound($number)';
}
