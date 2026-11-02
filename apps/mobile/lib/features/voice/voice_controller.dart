import 'dart:async';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/profile/profile_repository.dart';
import '../../core/progress/attempt_score.dart';
import '../../core/progress/progress_repository.dart';
import '../debrief/ai_score_store.dart';
import '../mission/mission_controller.dart';
import '../mission/mission_lookup.dart';
import '../progression/progression.dart';
import 'recorder/take_recorder.dart';
import 'voice_scoring.dart';

/// One attempt at a voice mission, as far as it has got (brief 35). The scene's camera, typing
/// and speech are the player widget's; this holds the takes, the verdict and the score.
class VoiceState {
  const VoiceState({
    required this.mission,
    required this.attemptNumber,
    required this.playerName,
    required this.scene,
    required this.question,
    required this.followUp,
    this.answer,
    this.reply,
    this.answered = false,
    this.replied = false,
    this.scoring = false,
    this.selfCheck,
    this.verdict,
    this.score,
    this.source,
    this.made = const {},
  });

  final Mission mission;

  /// 1 on the player's first attempt at this mission.
  final int attemptNumber;
  final String playerName;

  /// The setup lines and the question, addressed to the player.
  final List<SceneLine> scene;
  final SceneLine question;

  /// The interviewer's push-back, addressed to the player.
  final SceneLine followUp;

  /// The recordings. Null when answered without the microphone (refused), and dropped once the
  /// debrief is done ([VoiceController.discardTakes]).
  final Take? answer;
  final Take? reply;

  /// The question has been answered (recorded, or out loud with no microphone).
  final bool answered;

  /// The follow-up has been answered.
  final bool replied;

  /// The recruiter is listening (the deliberating card is up).
  final bool scoring;

  /// Why the player is ticking their own points; null unless the self-check is up.
  final SelfCheckReason? selfCheck;

  /// The AI's verdict, when it scored.
  final VoiceVerdict? verdict;

  /// The engine's score from the points made (the AI's, or the ticks). Null until scored.
  final VoiceScore? score;
  final VoiceScoreSource? source;

  VoicePrompt get voice => mission.voice!;

  /// Every point the mission listens for: the question's, then the follow-up's.
  List<ListenFor> get points => [
    ...voice.listenFor,
    ...voice.followUpListenFor,
  ];

  /// The ids of the points made, as scored (the AI's, or the ticks).
  final Set<String> made;

  /// The total the dossier shows: the AI's when it scored, else the engine's.
  int? get shownTotal => verdict?.score.overall.score ?? score?.score.total;

  VoiceState copyWith({
    Take? answer,
    Take? reply,
    bool? answered,
    bool? replied,
    bool? scoring,
    SelfCheckReason? selfCheck,
    bool clearSelfCheck = false,
    VoiceVerdict? verdict,
    VoiceScore? score,
    VoiceScoreSource? source,
    Set<String>? made,
    bool dropTakes = false,
  }) => VoiceState(
    mission: mission,
    attemptNumber: attemptNumber,
    playerName: playerName,
    scene: scene,
    question: question,
    followUp: followUp,
    answer: dropTakes ? null : answer ?? this.answer,
    reply: dropTakes ? null : reply ?? this.reply,
    answered: answered ?? this.answered,
    replied: replied ?? this.replied,
    scoring: scoring ?? this.scoring,
    selfCheck: clearSelfCheck ? null : selfCheck ?? this.selfCheck,
    verdict: verdict ?? this.verdict,
    score: score ?? this.score,
    source: source ?? this.source,
    made: made ?? this.made,
  );
}

/// The voice mission being played, keyed by campaign number.
final voiceControllerProvider = AsyncNotifierProvider.autoDispose
    .family<VoiceController, VoiceState, int>(
      VoiceController.new,
      retry: (_, _) => null,
    );

class VoiceController extends AsyncNotifier<VoiceState> {
  VoiceController(this.number);

  final int number;

  bool _started = false;
  bool _completing = false;

  Analytics get _analytics => ref.read(analyticsProvider);
  ProgressRepository get _progress => ref.read(progressRepositoryProvider);
  VoiceState get _now => state.requireValue;

  @override
  Future<VoiceState> build() async {
    _started = false;
    _completing = false;
    final mission = missionByNumber(
      number,
      catalog: ref.read(missionCatalogProvider),
    );
    if (mission == null || mission.voice == null) {
      throw MissionNotFound(number);
    }
    final previous = await _progress.attempts(missionId: mission.id);
    final name = (await ref.read(profileProvider.future)).displayName;
    return VoiceState(
      mission: mission,
      attemptNumber: previous.length + 1,
      playerName: name,
      scene: [for (final line in mission.scene) line.addressedTo(name)],
      question: mission.question.addressedTo(name),
      followUp: mission.voice!.followUp.addressedTo(name),
    );
  }

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

  /// The question is answered: [take], or null when it was said with no microphone.
  void answered(Take? take) {
    if (_now.answered) return;
    _recorded(take);
    state = AsyncData(_now.copyWith(answer: take, answered: true));
  }

  /// The follow-up is answered; scoring starts.
  Future<void> replied(Take? take) async {
    if (!_now.answered || _now.replied) return;
    _recorded(take);
    state = AsyncData(_now.copyWith(reply: take, replied: true));
    await _score();
  }

  void _recorded(Take? take) {
    if (take == null) return;
    _analytics.track(AnalyticsEvent.voiceAnswerRecorded, {
      'mission_id': EventValue.id(_now.mission),
      'seconds': EventValue.count(take.seconds),
      'paused_count': EventValue.count(take.pausedCount),
      'retakes': EventValue.count(take.retakes),
    });
  }

  /// The recruiter listens, or the self-check comes up (no recording, no backend, a timeout…).
  Future<void> _score() async {
    final now = _now;
    final answer = now.answer;
    final reply = now.reply;
    if (answer == null || reply == null) {
      state = AsyncData(now.copyWith(selfCheck: SelfCheckReason.noMicrophone));
      return;
    }
    final scorer = ref.read(voiceScorerProvider);
    if (scorer.unavailable case final reason?) {
      // Known at once (the zero-setup run): no waiting.
      state = AsyncData(now.copyWith(selfCheck: reason));
      return;
    }
    state = AsyncData(now.copyWith(scoring: true));
    final outcome = await scorer.score(
      VoiceScoreRequest(mission: now.mission, answer: answer, reply: reply),
    );
    if (!ref.mounted) return;
    switch (outcome) {
      case VoiceScored(:final verdict):
        unawaited(
          ref
              .read(aiScoreStoreProvider)
              .save(
                SavedAiScore(
                  missionId: now.mission.id,
                  at: DateTime.now().toUtc(),
                  score: verdict.score,
                ),
              )
              // Kept for "Your file"; a store failure never touches the debrief.
              .catchError((Object _) {}),
        );
        await _complete(
          verdict.pointsMade,
          VoiceScoreSource.ai,
          verdict: verdict,
        );
      case VoiceSelfCheck(:final reason):
        state = AsyncData(_now.copyWith(scoring: false, selfCheck: reason));
    }
  }

  /// The self-check is ticked: the engine scores the ticks.
  Future<void> selfChecked(Set<String> ticked) async {
    if (_now.selfCheck == null) return;
    await _complete([
      for (final p in _now.points)
        if (ticked.contains(p.id)) p.id,
    ], VoiceScoreSource.selfCheck);
  }

  /// Scores [made] with the engine, shows the debrief at once, then stores the attempt and
  /// fires the debrief's events. The room lights either way.
  Future<void> _complete(
    List<String> made,
    VoiceScoreSource source, {
    VoiceVerdict? verdict,
  }) async {
    if (_completing) return;
    _completing = true;
    final now = _now;
    final scored = voiceScoreFor(now.mission, made)!;
    state = AsyncData(
      now.copyWith(
        scoring: false,
        clearSelfCheck: true,
        verdict: verdict,
        score: scored,
        source: source,
        made: made.toSet(),
      ),
    );
    final firstEver = (await _progress.attempts()).isEmpty;
    final baseline = await _progress.baseline();
    final seconds = (now.answer?.seconds ?? 0) + (now.reply?.seconds ?? 0);
    await _progress.recordAttempt(
      AttemptRecord.voice(
        missionId: now.mission.id,
        attemptNumber: now.attemptNumber,
        score: scored.score,
        hinted: now.mission.hinted,
        voice: VoiceAnswerRecord(
          madePointIds: made,
          source: source,
          seconds: seconds,
        ),
      ),
    );
    // Read XP and skills again (see `MissionController`): the debrief shows this attempt's.
    if (ref.mounted) ref.invalidate(progressionProvider);
    final shown = verdict?.score.overall.score ?? scored.score.total;
    _analytics
      ..track(AnalyticsEvent.voiceAnswerScored, {
        'mission_id': EventValue.id(now.mission),
        'score_bucket': EventValue.name(ScoreBucket.of(shown)),
        'source': EventValue.name(source),
      })
      ..track(AnalyticsEvent.missionCompleted, {
        'mission_id': EventValue.id(now.mission),
        'chapter': EventValue.count(now.mission.chapter),
        'score_bucket': EventValue.name(ScoreBucket.of(scored.score.total)),
        'attempt_number': EventValue.count(now.attemptNumber),
      });
    if (firstEver) _analytics.track(AnalyticsEvent.userActivated);
    // A chapter closed by voice (Missions 14 and 21), first time through: like Mission 7's,
    // how far the player has come since Mission 1 (brief 44: it never fired for them).
    if (now.mission.closesChapter &&
        now.attemptNumber == 1 &&
        baseline != null) {
      _analytics.track(AnalyticsEvent.chapterCompleted, {
        'chapter': EventValue.count(now.mission.chapter),
        'score_delta_bucket': EventValue.name(
          ScoreDeltaBucket.of(
            compareToBaseline(
              baseline: baseline.score,
              latest: scored.score,
            ).totalDelta,
          ),
        ),
      });
    }
  }

  /// After the debrief: the recordings leave memory (they were never on disk).
  void discardTakes() {
    if (!state.hasValue) return;
    state = AsyncData(_now.copyWith(dropTakes: true));
  }
}
