import 'dart:async';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/profile/profile_repository.dart';
import '../../core/progress/progress_repository.dart';
import 'mission_lookup.dart';
import 'mission_resume.dart';

/// A new attempt's shuffle seed. The only randomness in a mission, drawn once per attempt and
/// stored with it; tests override it to pin the order.
final attemptSeedProvider = Provider<int Function()>((ref) {
  final random = math.Random();
  return () => random.nextInt(_seedRange);
});

/// Seeds are 31-bit, so they're the same number on the VM and the web.
const int _seedRange = 0x7FFFFFFF;

/// Reasons shuffle with their own salts, clear of the beats' (0–2) and the reply's (3).
const int _reasonSalt = 10;

/// And a built beat's fragments with theirs, clear of the reasons'.
const int _buildSalt = 20;

/// One beat as played: the line, how long the player took to pick it once the cards were up,
/// and the reason they gave when asked "why that line?".
class BeatPlay {
  const BeatPlay({required this.option, this.decidedIn, this.reason});

  final AnswerOption option;
  final Duration? decidedIn;

  /// Null until given, and for good on a beat with no why step.
  final Reason? reason;

  /// The engine's view of this play in [beat]. The beat builds the reason pick, so the wrong
  /// principle only costs a strongest line (brief 19's `reasonPick`).
  BeatPick pick(Beat beat) => BeatPick(
    beat: beat.kind,
    choice: option.scored,
    decidedIn: decidedIn,
    reason: switch (reason) {
      final r? => beat.reasonPick(r, option.id),
      null => null,
    },
  );

  BeatPlay _withReason(Reason reason) =>
      BeatPlay(option: option, decidedIn: decidedIn, reason: reason);
}

/// One attempt at a mission, as far as it has got. Everything here is game state: the scene's
/// camera, typing and timing are the screen's own.
class MissionState {
  const MissionState({
    required this.mission,
    required this.seed,
    required this.attemptNumber,
    required this.scene,
    required this.question,
    this.playerName = PlayerProfile.fallbackName,
    this.plays = const [],
    this.resumed = false,
    this.saved,
    this.draft,
    this.earlierDraft,
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

  /// The mission's question, addressed to the player like [scene].
  final SceneLine question;

  /// What the interviewers call the player (the profile's first name).
  final String playerName;

  /// The player's own words from the draft-first step, or null (skipped, or not offered).
  final String? draft;

  /// The words from the player's first attempt at this mission that has any, for a replay.
  final String? earlierDraft;

  /// What the dossier shows as "Your first try": this attempt's words, else an earlier one's.
  String? get firstTry => draft ?? earlierDraft;

  /// The beats played so far, in beat order.
  final List<BeatPlay> plays;

  /// This attempt was picked up where the player left it.
  final bool resumed;

  /// A part-played attempt the player left earlier: the screen offers to continue it.
  final SavedAttempt? saved;

  /// The lines locked in so far, one per beat, in beat order.
  List<AnswerOption> get picks => [for (final p in plays) p.option];

  /// The engine's picks so far, with the time taken and the reasons given.
  List<BeatPick> get beatPicks => [
    for (var i = 0; i < plays.length; i++) plays[i].pick(mission.beats[i]),
  ];

  /// The last line is picked and its beat asks why, but no reason is given yet.
  bool get awaitingWhy =>
      plays.isNotEmpty &&
      plays.last.reason == null &&
      mission.beats[plays.length - 1].asksWhy;
  final bool draftDone;
  final FollowUp? followUp;
  final AnswerOption? reply;
  final MissionScore? score;

  /// The beat being answered: 0 open, 1 evidence, 2 land; 3 once all are locked.
  int get beatIndex => plays.length;

  /// Every beat has its line and, where asked, its reason.
  bool get beatsDone => plays.length == mission.beats.length && !awaitingWhy;
  Beat? get beat => beatsDone ? null : mission.beats[beatIndex];

  /// The current beat's options in this attempt's order, never the file's. None on a built
  /// beat: the player builds its answer from [fragmentsForBeat].
  List<AnswerOption> get beatOptions =>
      plays.length == mission.beats.length ||
          awaitingWhy ||
          mission.beats[beatIndex].build != null
      ? const []
      : optionsForBeat(beatIndex);

  /// The current beat is built from fragments (brief 27) and waiting for its answer.
  BuildBeat? get building => beatsDone || awaitingWhy ? null : beat?.build;

  /// Beat [index]'s fragments in this attempt's order (never the file's, where the parts sit in
  /// their right order). Empty on a beat that isn't built.
  List<Fragment> fragmentsForBeat(int index) {
    final build = mission.beats[index].build;
    if (build == null) return const [];
    return shuffled(build.fragments, seed: seed, salt: _buildSalt + index);
  }

  /// Beat [index]'s options in this attempt's order: the same order every time it's asked,
  /// so the screen can keep showing a beat after its line is locked.
  List<AnswerOption> optionsForBeat(int index) =>
      shuffled(mission.beats[index].options, seed: seed, salt: index);

  /// Beat [index]'s reasons for "why that line?", in this attempt's order (never the file's,
  /// where the right one could sit in the same place every time).
  List<Reason> reasonsForBeat(int index) {
    final why = mission.beats[index].why;
    if (why == null) return const [];
    return shuffled(why.reasons, seed: seed, salt: _reasonSalt + index);
  }

  /// How the interviewer takes beat [index]'s play (strong, weak or a guess).
  PickQuality qualityOf(int index) {
    final beat = mission.beats[index];
    final play = plays[index];
    return judgePick(
      play.pick(beat),
      strongestOption: beat.isStrongest(play.option.id),
    );
  }

  /// The follow-up's replies in this attempt's order.
  List<AnswerOption> get replyOptions {
    final followUp = this.followUp;
    if (followUp == null) return const [];
    return shuffled(followUp.replies, seed: seed, salt: mission.beats.length);
  }

  /// The trust meter, from the engine (`trustAfterPicks`): guesses and unsound reasons cost
  /// trust.
  int get trust => trustAfterPicks(beatPicks);

  /// The follow-up's line, addressed to the player.
  SceneLine? get followUpLine => followUp?.line.addressedTo(playerName);

  MissionState _copy({
    List<BeatPlay>? plays,
    String? draft,
    bool? draftDone,
    FollowUp? followUp,
    AnswerOption? reply,
    MissionScore? score,
  }) => MissionState(
    mission: mission,
    seed: seed,
    attemptNumber: attemptNumber,
    scene: scene,
    question: question,
    playerName: playerName,
    draft: draft ?? this.draft,
    earlierDraft: earlierDraft,
    plays: plays ?? this.plays,
    resumed: resumed,
    saved: saved,
    draftDone: draftDone ?? this.draftDone,
    followUp: followUp ?? this.followUp,
    reply: reply ?? this.reply,
    score: score ?? this.score,
  );
}

/// The mission that must be finished before mission [number] opens (the tower's rule: rooms open
/// in order), or null when it's open. Mission 1 is always open; an unknown number is the
/// controller's to report.
final missionBlockerProvider = FutureProvider.autoDispose.family<Mission?, int>(
  (ref, number) async {
    final catalog = ref.read(missionCatalogProvider);
    final mission = missionByNumber(number, catalog: catalog);
    if (mission == null) return null;
    final i = catalog.indexOf(mission);
    if (i <= 0) return null;
    final before = catalog[i - 1];
    final played = await ref
        .read(progressRepositoryProvider)
        .attempts(missionId: before.id);
    return played.isEmpty ? before : null;
  },
);

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

  Analytics get _analytics => ref.read(analyticsProvider);
  ProgressRepository get _progress => ref.read(progressRepositoryProvider);

  @override
  Future<MissionState> build() async {
    // A rebuild is a new attempt (Riverpod keeps the notifier between builds).
    _started = false;
    _completing = false;
    final mission = missionByNumber(
      number,
      catalog: ref.read(missionCatalogProvider),
    );
    if (mission == null) throw MissionNotFound(number);
    final saved = await _loadSaved(mission);
    final previous = await _progress.attempts(missionId: mission.id);
    final name = (await ref.read(profileProvider.future)).displayName;
    return MissionState(
      mission: mission,
      seed: ref.read(attemptSeedProvider)(),
      attemptNumber: previous.length + 1,
      scene: [
        for (final line in [...mission.scene, ?await _continuityLine(mission)])
          line.addressedTo(name),
      ],
      question: mission.question.addressedTo(name),
      playerName: name,
      earlierDraft: previous.map((a) => a.draft).nonNulls.firstOrNull,
      saved: saved == null ? null : _validated(mission, saved),
    );
  }

  /// Runs a resume-store write; a failure is logged, never thrown at the player.
  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error) {
      ref.read(logProvider).warn('resume store unwritable', {
        'error': '${error.runtimeType}',
      });
    }
  }

  /// The attempt left part-way, if any. The store is a convenience: if it can't be read the
  /// player simply starts afresh, never stuck at a closed door.
  Future<SavedAttempt?> _loadSaved(Mission mission) async {
    try {
      return await ref.read(resumeStoreProvider).load(mission.id);
    } on Object catch (error) {
      ref.read(logProvider).warn('resume store unreadable', {
        'error': '${error.runtimeType}',
      });
      return null;
    }
  }

  /// [saved] if every id in it still exists in [mission] (content can change between versions);
  /// otherwise null, and the player starts afresh.
  SavedAttempt? _validated(Mission mission, SavedAttempt saved) {
    if (saved.plays.length > mission.beats.length) return null;
    for (var i = 0; i < saved.plays.length; i++) {
      final beat = mission.beats[i];
      final play = saved.plays[i];
      if (beat.optionById(play.optionId) == null) return null;
      final reasonId = play.reasonId;
      if (reasonId != null &&
          !(beat.why?.reasons.any((r) => r.id == reasonId) ?? false)) {
        return null;
      }
    }
    return saved;
  }

  /// "Continue where you left off": the saved attempt replaces this fresh one, with its seed
  /// (the same card order), its picks and its draft.
  void resume() {
    final now = _now;
    final saved = now.saved;
    if (saved == null) return;
    final plays = [
      for (var i = 0; i < saved.plays.length; i++)
        BeatPlay(
          option: now.mission.beats[i].optionById(saved.plays[i].optionId)!,
          decidedIn: saved.plays[i].decidedIn,
          reason: now.mission.beats[i].why?.reasons
              .where((r) => r.id == saved.plays[i].reasonId)
              .firstOrNull,
        ),
    ];
    _started = true;
    state = AsyncData(
      MissionState(
        mission: now.mission,
        seed: saved.seed,
        attemptNumber: saved.attemptNumber,
        scene: now.scene,
        question: now.question,
        playerName: now.playerName,
        earlierDraft: now.earlierDraft,
        draft: saved.draft,
        draftDone: saved.draftDone,
        plays: plays,
        resumed: true,
        followUp: _followUpFor(now.mission, plays),
      ),
    );
    _analytics.track(AnalyticsEvent.missionResumed, {
      'mission_id': EventValue.id(now.mission),
      'beat': EventValue.count(plays.length),
    });
  }

  /// "Start again": the saved attempt is dropped.
  Future<void> startAfresh() async {
    final now = _now;
    if (now.saved == null) return;
    state = AsyncData(
      MissionState(
        mission: now.mission,
        seed: now.seed,
        attemptNumber: now.attemptNumber,
        scene: now.scene,
        question: now.question,
        playerName: now.playerName,
        earlierDraft: now.earlierDraft,
      ),
    );
    await _guarded(() => ref.read(resumeStoreProvider).clear(now.mission.id));
  }

  /// "Leave the interview?" → Leave: the attempt so far is kept on the device.
  Future<void> leave() async {
    final now = _now;
    if (_completing || now.score != null) return;
    await _guarded(
      () => ref
          .read(resumeStoreProvider)
          .save(
            SavedAttempt(
              missionId: now.mission.id,
              seed: now.seed,
              attemptNumber: now.attemptNumber,
              draft: now.draft,
              draftDone: now.draftDone,
              plays: [
                for (final p in now.plays)
                  SavedPlay(
                    optionId: p.option.id,
                    decidedIn: p.decidedIn,
                    reasonId: p.reason?.id,
                  ),
              ],
            ),
          ),
    );
    _analytics.track(AnalyticsEvent.missionLeft, {
      'mission_id': EventValue.id(now.mission),
      'beat': EventValue.count(now.plays.length),
    });
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
    final trimmed = text?.trim();
    final draft = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _analytics.track(AnalyticsEvent.draftCompleted, {
      'mission_id': EventValue.id(_now.mission),
      'skipped': EventValue.flag(draft == null),
    });
    state = AsyncData(_now._copy(draft: draft, draftDone: true));
  }

  /// Locks [option] in as the current beat's line, picked [decidedIn] after the cards were up.
  /// When the beat asks why, the reason comes next ([giveReason]); after the last beat the
  /// engine picks the interviewer's follow-up from the weakest line.
  void lock(AnswerOption option, {Duration? decidedIn}) {
    final now = _now;
    if (!now.beatOptions.contains(option)) return;
    final plays = [
      ...now.plays,
      BeatPlay(option: option, decidedIn: decidedIn),
    ];
    state = AsyncData(
      now._copy(plays: plays, followUp: _followUpFor(now.mission, plays)),
    );
  }

  /// Locks in the answer the player built on the current beat from [placed] (fragment ids, in
  /// the order tapped), [decidedIn] after the fragments were up. It's a line like any other from
  /// here on: a built beat asks no why, so her reaction comes next.
  void lockBuilt(List<String> placed, {Duration? decidedIn}) {
    final now = _now;
    final build = now.building;
    if (build == null || placed.isEmpty) return;
    final result = scoreBuild(build.spec, placed);
    final plays = [
      ...now.plays,
      BeatPlay(option: build.answerFor(placed), decidedIn: decidedIn),
    ];
    state = AsyncData(
      now._copy(plays: plays, followUp: _followUpFor(now.mission, plays)),
    );
    _analytics.track(AnalyticsEvent.answerBuilt, {
      'mission_id': EventValue.id(now.mission),
      'beat': EventValue.name(now.beat!.kind),
      'fragments': EventValue.count(placed.length),
      'missing': EventValue.count(result.missing),
      'out_of_order': EventValue.count(result.outOfOrder),
      'decoy_used': EventValue.flag(result.decoysUsed.isNotEmpty),
      'guessed': EventValue.flag(isGuess(decidedIn)),
    });
  }

  /// The player's answer to "why that line?" for the beat just picked.
  void giveReason(Reason reason) {
    final now = _now;
    if (!now.awaitingWhy) return;
    final beat = now.mission.beats[now.plays.length - 1];
    if (!beat.why!.reasons.contains(reason)) return;
    final plays = [
      ...now.plays.take(now.plays.length - 1),
      now.plays.last._withReason(reason),
    ];
    state = AsyncData(
      now._copy(plays: plays, followUp: _followUpFor(now.mission, plays)),
    );
  }

  /// The engine's follow-up once every beat is played and explained; null before.
  FollowUp? _followUpFor(Mission mission, List<BeatPlay> plays) {
    if (plays.length != mission.beats.length) return null;
    final last = plays.last;
    if (mission.beats.last.asksWhy && last.reason == null) return null;
    return mission.followUpById(
      selectFollowUp(
        picks: [
          for (var i = 0; i < plays.length; i++)
            plays[i].pick(mission.beats[i]),
        ],
        candidates: [for (final f in mission.followUps) f.candidate],
      ),
    );
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
        picks: now.beatPicks,
        followUpReply: reply.scored,
        hinted: now.mission.hinted,
      ),
    );
    // The dossier shows at once; storing never holds the scene up.
    state = AsyncData(now._copy(reply: reply, score: score));

    await _guarded(() => ref.read(resumeStoreProvider).clear(now.mission.id));
    final firstEver = (await _progress.attempts()).isEmpty;
    final baseline = await _progress.baseline();
    final firstBaseline = now.mission.isBaseline && baseline == null;
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
        draft: now.draft,
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
    // The chapter's review, first time through: how far the player has come since Mission 1.
    if (now.mission.closesChapter &&
        now.attemptNumber == 1 &&
        baseline != null) {
      _analytics.track(AnalyticsEvent.chapterCompleted, {
        'chapter': EventValue.count(now.mission.chapter),
        'score_delta_bucket': EventValue.name(
          ScoreDeltaBucket.of(
            compareToBaseline(
              baseline: baseline.score,
              latest: score,
            ).totalDelta,
          ),
        ),
      });
    }
  }
}

/// The route named a mission that doesn't exist (a stale deep link).
class MissionNotFound implements Exception {
  const MissionNotFound(this.number);

  final int number;

  @override
  String toString() => 'MissionNotFound($number)';
}
