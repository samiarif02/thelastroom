import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/game_sounds.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/film_kit.dart';
import '../debrief/debrief_facts.dart';
import '../debrief/debrief_view.dart';
import 'mission_controller.dart';
import 'mission_lookup.dart';
import 'scene/lower_third.dart';
import 'scene/mission_card.dart';
import 'scene/mission_set.dart';
import 'scene/scene_scrim.dart';
import 'widgets/beat_timer.dart';
import 'widgets/draft_panel.dart';
import 'widgets/next_control.dart';
import 'widgets/scene_notes.dart';
import 'widgets/trust_meter.dart';

/// Where the scene is. The order matters: later stages never go back.
enum SceneStage {
  /// The mission's title card.
  card,

  /// The letterbox bars slide in on the wide shot.
  opening,

  /// The setup lines, then the question, typing out.
  lines,

  /// The question has landed: the dolly push.
  push,

  /// Draft first, on the missions that offer it.
  draft,

  /// Open, evidence, land.
  beats,

  /// The interviewer's follow-up, after the hard cut.
  followUp,

  /// The replies to the follow-up.
  replies,

  /// The dossier.
  debrief,
}

/// Where a beat is: the cards are up, the interviewer asks why, the player gives a reason, or
/// the interviewer reacts.
enum BeatPhase { cards, why, reasons, reaction }

/// When a pick was made: the frame clock, so a test's pumped time is the player's time. The
/// engine never reads a clock (the contract): the player measures `decidedIn` here.
final decisionClockProvider = Provider<Duration Function()>(
  (ref) =>
      () => SchedulerBinding.instance.currentSystemFrameTimeStamp,
);

/// One mission, played as a film scene (FR-10–FR-15): title card, letterbox, the interviewer's
/// lines and question, the push in, draft first, three beats on answer cards with the trust
/// meter beating, the follow-up on a hard cut, the reply, then the dossier.
///
/// The game state (picks, the follow-up, the score) is [MissionController]'s; this widget only
/// runs the camera, the subtitles and the timing, and says what happened to [GameSounds].
class MissionPlayer extends ConsumerStatefulWidget {
  const MissionPlayer({
    super.key,
    required this.number,
    required this.onExit,
    required this.onLeave,
  });

  final int number;

  /// After the dossier: back to the Tower.
  final VoidCallback onExit;

  /// "Leave the interview?" → Leave, once the attempt is saved.
  final VoidCallback onLeave;

  static const String continueLabel = 'Continue the scene';

  /// After a tap picks a card, another tap can still change it for this long; then it's said.
  /// A tap on the picked card says it at once.
  static const Duration changeWindow = Duration(seconds: 2);

  /// How long "Too fast" stays up after a guess.
  static const Duration guessCueFor = Duration(milliseconds: 2600);

  /// A reaction holds this long once typed before the next beat's cards come up.
  static const Duration reactionHold = Duration(milliseconds: 1400);

  /// A typed interviewer line moves on by itself after this (owner, 2026-10-30), unless the
  /// player has paused it or switched auto-advance off. Never applies to choosing an answer.
  static const Duration autoAdvanceAfter = Duration(seconds: 6);

  @override
  ConsumerState<MissionPlayer> createState() => _MissionPlayerState();
}

class _MissionPlayerState extends ConsumerState<MissionPlayer>
    with SingleTickerProviderStateMixin {
  // Rests between beats, so each one lands before the next starts.
  static const Duration _beforeLines = Duration(milliseconds: 350);
  static const Duration _afterLock = Duration(milliseconds: 900);
  static const Duration _beforeFollowUp = Duration(milliseconds: 700);
  static const Duration _beforeDebrief = Duration(milliseconds: 1100);

  final TypewriterController _typer = TypewriterController();
  late final AppLifecycleListener _lifecycle;
  late final AnimationController _countdown =
      AnimationController(vsync: this, duration: MissionPlayer.autoAdvanceAfter)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _nextLine();
        });

  /// A touch on the scene paused this line's countdown.
  bool _paused = false;

  SceneStage _stage = SceneStage.card;
  int _line = 0;

  /// The beat on screen. It trails the controller's by the rest after a lock, so the locked
  /// line stays lit before the next beat's cards arrive.
  int _beatShown = 0;
  bool _bars = false;
  bool _closeUp = false;
  bool _tight = false;
  bool _lineTyped = false;
  BeatPhase _phase = BeatPhase.cards;

  /// When the cards on screen finished arriving: the stopwatch's zero. Null until then, so a
  /// tap on a card still sliding in is timed at zero (a guess).
  Duration? _shownAt;

  /// The card picked, while it can still be changed ([MissionPlayer.changeWindow]).
  AnswerOption? _selected;
  Duration? _decidedIn;
  Timer? _changeTimer;

  /// The card said: locked in, the others dark.
  AnswerOption? _locked;
  Reason? _reason;

  /// The interviewer's reaction on screen, and how the pick landed.
  SceneLine? _reaction;
  PickQuality? _quality;
  VoidCallback? _afterReaction;

  /// This beat's pick was a guess, and she has already said so.
  bool _calledOut = false;
  bool _guessCue = false;
  bool _leaving = false;

  MissionController get _controller =>
      ref.read(missionControllerProvider(widget.number).notifier);
  MissionState get _game =>
      ref.read(missionControllerProvider(widget.number)).requireValue;
  // Kept from the start: `dispose` stops the sound, when `ref` can no longer be read.
  late final GameSounds _sounds = ref.read(gameSoundsProvider);

  PlayerProfile get _profile =>
      ref.read(profileProvider).value ?? const PlayerProfile();

  /// The setup lines, then the question.
  List<SceneLine> get _lines => [..._game.scene, _game.question];
  bool get _onQuestion => _line == _lines.length - 1;

  Duration _now() => ref.read(decisionClockProvider)();

  @override
  void initState() {
    super.initState();
    if (_game.resumed) _resumeScene();
    _lifecycle = AppLifecycleListener(
      onPause: () => _sounds.stopAll(),
      onResume: () => _sounds.ambience(_game.mission.chapter),
    );
    final mission = _game.mission;
    if (mission.opensChapter) _sounds.chapterCard(mission.chapter);
  }

  /// Picks up a left attempt: straight to the close-up, at the beat (or the why) it stopped at.
  void _resumeScene() {
    final game = _game;
    _closeUp = true;
    _lineTyped = true;
    if (game.beatsDone) {
      _stage = SceneStage.followUp;
      _tight = true;
      _lineTyped = false;
    } else if (game.plays.isEmpty &&
        game.mission.offersDraft &&
        !game.draftDone) {
      _stage = SceneStage.draft;
    } else {
      _stage = SceneStage.beats;
      _beatShown = game.awaitingWhy ? game.plays.length - 1 : game.beatIndex;
      _phase = game.awaitingWhy ? BeatPhase.why : BeatPhase.cards;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sounds.ambience(_game.mission.chapter);
    });
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _lifecycle.dispose();
    _countdown.dispose();
    _typer.dispose();
    _sounds.stopAll();
    super.dispose();
  }

  void _go(SceneStage stage) {
    if (!mounted || stage.index <= _stage.index) return;
    setState(() => _stage = stage);
  }

  Future<void> _after(Duration rest, VoidCallback then) async {
    final still = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(still ? Duration.zero : rest);
    if (mounted) then();
  }

  // The scene's beats, in order.

  void _cardDone() {
    if (_stage != SceneStage.card) return;
    _sounds.ambience(_game.mission.chapter);
    _go(SceneStage.opening);
    setState(() => _bars = true);
  }

  void _barsSettled() {
    if (_bars && _stage == SceneStage.opening) {
      unawaited(_after(_beforeLines, _startLines));
    }
  }

  void _startLines() {
    if (_stage != SceneStage.opening) return;
    _go(SceneStage.lines);
    _controller.sceneStarted();
  }

  void _lineDone() {
    setState(() => _lineTyped = true);
    if (_stage != SceneStage.lines) return;
    if (_onQuestion) {
      _sounds.questionLands();
      _go(SceneStage.push);
      setState(() => _closeUp = true);
    } else if (_profile.autoAdvance) {
      _paused = false;
      unawaited(_countdown.forward(from: 0));
    }
  }

  /// On to the next setup line (the Next control, a tap, or the countdown running out).
  void _nextLine() {
    if (_stage != SceneStage.lines || _onQuestion || !_typer.isComplete) {
      return;
    }
    _countdown.reset();
    setState(() {
      _line++;
      _lineTyped = false;
      _paused = false;
    });
  }

  /// A tap in the lower third, where the line and the Next control are: completes the typing
  /// line, or moves on. The whole region answers, so the first tap never misses.
  void _tapLowerThird() {
    if (!_typer.isComplete) {
      _completeLine();
    } else if (_stage == SceneStage.beats && _phase == BeatPhase.reaction) {
      _reactionDone();
    } else if (_stage == SceneStage.lines && !_onQuestion) {
      _sounds.uiTap();
      _nextLine();
    }
  }

  void _completeLine() {
    _typer.complete();
    _sounds.subtitleCompleted();
  }

  void _pushDone() {
    if (_stage != SceneStage.push) return;
    setState(() => _bars = false);
    final game = _game;
    _go(
      game.mission.offersDraft && !game.draftDone
          ? SceneStage.draft
          : SceneStage.beats,
    );
  }

  void _draftDone(String? draft) {
    _controller.finishDraft(draft);
    _go(SceneStage.beats);
  }

  /// A tap on the scene above the lower third: completes the typing line, pauses its
  /// countdown, or moves on to the next one.
  void _tap() {
    switch (_stage) {
      case SceneStage.card:
        _cardDone();
      case SceneStage.opening:
        _startLines();
      case SceneStage.lines || SceneStage.followUp when !_typer.isComplete:
        _completeLine();
      case SceneStage.beats
          when _phase != BeatPhase.cards && !_typer.isComplete:
        _completeLine();
      case SceneStage.beats when _phase == BeatPhase.reaction:
        _reactionDone();
      // A touch on the scene while the line counts down pauses it; the next one moves on.
      case SceneStage.lines when !_onQuestion && _countdown.isAnimating:
        _countdown.stop();
        setState(() => _paused = true);
      case SceneStage.lines when !_onQuestion:
        _nextLine();
      case _:
        break;
    }
  }

  /// The last card arrived: the player can read them all, and the stopwatch starts.
  void _cardsArrived() => _shownAt ??= _now();

  /// One tap picks a line. For [MissionPlayer.changeWindow] a tap on another card changes it;
  /// a tap on the same card says it now.
  void _pick(AnswerOption option, {required bool reply}) {
    if (_locked != null) return;
    if (_selected == option) {
      _say(reply: reply);
      return;
    }
    final shownAt = _shownAt;
    _sounds.choiceTapped();
    setState(() {
      _selected = option;
      _decidedIn = shownAt == null ? Duration.zero : _now() - shownAt;
    });
    _changeTimer?.cancel();
    _changeTimer = Timer(MissionPlayer.changeWindow, () => _say(reply: reply));
  }

  /// The picked line is said: locked in, timed, and handed to the controller.
  void _say({required bool reply}) {
    final option = _selected;
    if (option == null || _locked != null || !mounted) return;
    _changeTimer?.cancel();
    _sounds.answerLocked();
    stampThud();
    setState(() => _locked = option);
    if (reply) {
      unawaited(_controller.answerFollowUp(option));
      unawaited(_after(_beforeDebrief, () => _go(SceneStage.debrief)));
      return;
    }
    final before = _game.trust;
    _controller.lock(option, decidedIn: _decidedIn);
    _trustMoved(before);
    if (isGuess(_decidedIn)) {
      // Caught guessing: called out on screen and in her words, before anything else.
      setState(() => _guessCue = true);
      unawaited(
        _after(
          MissionPlayer.guessCueFor,
          () => setState(() => _guessCue = false),
        ),
      );
      unawaited(
        _after(_afterLock, () {
          _calledOut = true;
          _react(PickQuality.guessed, then: _askWhy);
        }),
      );
    } else {
      unawaited(_after(_afterLock, _askWhy));
    }
  }

  void _trustMoved(int before) {
    final after = _game.trust;
    if (after != before) _sounds.trustChanged(rising: after > before);
  }

  /// "Why that line?", when the beat asks it; otherwise straight to her reaction.
  void _askWhy() {
    if (_game.awaitingWhy) {
      setState(() {
        _phase = BeatPhase.why;
        _lineTyped = false;
      });
    } else {
      _reactToBeat();
    }
  }

  void _whyTyped() {
    if (_phase != BeatPhase.why) return;
    setState(() {
      _lineTyped = true;
      _phase = BeatPhase.reasons;
    });
  }

  /// One tap gives a reason: there's nothing to change once the line is said.
  void _giveReason(Reason reason) {
    if (_reason != null) return;
    _sounds.answerLocked();
    stampThud();
    setState(() => _reason = reason);
    final before = _game.trust;
    _controller.giveReason(reason);
    _trustMoved(before);
    unawaited(_after(_afterLock, _reactToBeat));
  }

  /// Her reaction to the beat (once per beat: a guess was already called out).
  void _reactToBeat() {
    if (_calledOut) {
      _nextBeat();
      return;
    }
    _react(_game.qualityOf(_beatShown), then: _nextBeat);
  }

  /// The interviewer says how [quality] landed, then [then]. A beat with no reaction content
  /// moves straight on.
  void _react(PickQuality quality, {required VoidCallback then}) {
    final line = _game.mission.beats[_beatShown].reaction?.forQuality(quality);
    if (line == null) {
      then();
      return;
    }
    setState(() {
      _phase = BeatPhase.reaction;
      _reaction = line.addressedTo(_game.playerName);
      _quality = quality;
      _afterReaction = then;
      _lineTyped = false;
    });
  }

  void _reactionTyped() {
    setState(() => _lineTyped = true);
    unawaited(_after(MissionPlayer.reactionHold, _reactionDone));
  }

  /// On from the reaction (its hold ran out, or a tap).
  void _reactionDone() {
    final then = _afterReaction;
    if (_phase != BeatPhase.reaction || then == null) return;
    _afterReaction = null;
    then();
  }

  void _nextBeat() {
    if (_game.beatsDone) {
      unawaited(_after(_beforeFollowUp, _cutToFollowUp));
      return;
    }
    setState(() {
      _beatShown = _game.beatIndex;
      _phase = BeatPhase.cards;
      _shownAt = null;
      _selected = null;
      _decidedIn = null;
      _locked = null;
      _reason = null;
      _reaction = null;
      _quality = null;
      _calledOut = false;
      _lineTyped = false;
    });
  }

  void _cutToFollowUp() {
    _go(SceneStage.followUp);
    setState(() {
      _tight = true;
      _lineTyped = false;
      _selected = null;
      _decidedIn = null;
      _locked = null;
      _shownAt = null;
      _reaction = null;
    });
  }

  void _followUpTyped() {
    setState(() => _lineTyped = true);
    _go(SceneStage.replies);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref
        .watch(missionControllerProvider(widget.number))
        .requireValue;
    final mission = game.mission;
    final lead = mission.lead;
    final grade = mission.grade;
    final size = MediaQuery.sizeOf(context);
    final regionTop =
        MissionSet.faceBottom(size, _shotsFor(_stage)) + BrandSpace.sm;

    if (_stage == SceneStage.debrief && game.score != null) {
      return DebriefView(
        mission: mission,
        score: game.score!,
        trust: game.trust,
        firstTry: game.firstTry,
        reasoning: reasoningOf(mission, game.plays),
        onContinue: widget.onExit,
      );
    }

    return PopScope<Object?>(
      // Back mid-mission never just closes the scene: it asks first, and keeps the attempt.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_leaving) setState(() => _leaving = true);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: BrandVivid.night),
          FilmOverlay(
            grain: 0,
            vignetteColor: grade.shadow,
            child: HardCut(
              shot: _tight,
              onCut: () =>
                  _sounds.followUpChallenge(game.followUp!.line.speakerId),
              child: DollyCamera(
                closeUp: _closeUp,
                onPushEnd: _pushDone,
                layers: MissionSet.layers(
                  figure:
                      SilhouetteFigure.byId[lead.id] ?? SilhouetteFigure.priya,
                  grade: grade,
                  figureLabel: '${lead.name}, the ${lead.role.toLowerCase()}',
                  tight: _tight,
                  expression: _expression,
                ),
              ),
            ),
          ),
          if (mission.timed &&
              !_profile.calmMode &&
              _stage == SceneStage.beats &&
              _phase == BeatPhase.cards)
            BeatTimer(
              key: ValueKey(_beatShown),
              running: _locked == null,
              onExpired: _controller.timerExpired,
              onPulse: _sounds.timerPulse,
              builder: (context, dim, left) =>
                  _TimerShade(dim: dim, left: left),
            ),
          SceneScrim(from: regionTop / size.height, grade: grade),
          // Taps on the scene itself (anywhere the cards and the draft aren't).
          Semantics(
            button: true,
            label: MissionPlayer.continueLabel,
            onTap: _tap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tap,
            ),
          ),
          AnimatedLetterbox(
            shown: _bars,
            color: BrandVivid.night,
            onSettled: _barsSettled,
          ),
          _Overlay(
            regionTop: regionTop,
            trust: _stage.index >= SceneStage.beats.index ? game.trust : null,
            grade: grade,
            onTapLowerThird:
                _stage.index <= SceneStage.push.index ||
                    _stage == SceneStage.followUp ||
                    (_stage == SceneStage.beats &&
                        (_phase == BeatPhase.why ||
                            _phase == BeatPhase.reaction))
                ? _tapLowerThird
                : null,
            guessCue: _guessCue,
            children: _lowerThird(game, lead, grade),
          ),
          if (_stage == SceneStage.card)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _cardDone,
              child: MissionCard(mission: mission, onFinished: _cardDone),
            ),
          if (_leaving)
            LeaveSheet(
              grade: grade,
              onResume: () => setState(() => _leaving = false),
              onLeave: _leave,
            ),
        ],
      ),
    );
  }

  Future<void> _leave() async {
    _changeTimer?.cancel();
    _sounds.stopAll();
    await _controller.leave();
    if (mounted) widget.onLeave();
  }

  /// What sits in the lower third, under the face, at this stage.
  List<Widget> _lowerThird(
    MissionState game,
    Interviewer lead,
    ChapterGrade grade,
  ) {
    final sounds = _sounds;
    Widget subtitle(SceneLine line, {required VoidCallback onComplete}) =>
        IgnorePointer(
          child: TypewriterSubtitle(
            speaker: interviewerById(line.speakerId).name,
            line: line.text,
            grade: grade,
            controller: _typer,
            onCharacter: (c, _) => sounds.subtitleCharacter(line.speakerId, c),
            onComplete: onComplete,
          ),
        );

    switch (_stage) {
      case SceneStage.card || SceneStage.opening || SceneStage.debrief:
        return const [];
      case SceneStage.lines || SceneStage.push:
        return [
          subtitle(_lines[_line], onComplete: _lineDone),
          if (_lineTyped && !_onQuestion)
            AnimatedBuilder(
              animation: _countdown,
              builder: (context, _) {
                final counting = _profile.autoAdvance;
                final left = 1 - _countdown.value;
                return NextControl(
                  grade: grade,
                  onPressed: () {
                    _sounds.uiTap();
                    _nextLine();
                  },
                  remaining: counting ? left : null,
                  secondsLeft: counting
                      ? (left * MissionPlayer.autoAdvanceAfter.inSeconds).ceil()
                      : null,
                  paused: _paused,
                );
              },
            ),
        ];
      case SceneStage.draft:
        return [
          QuestionReminder(text: game.question.text, grade: grade),
          const SizedBox(height: BrandSpace.sm),
          DraftPanel(grade: grade, onDone: _draftDone),
        ];
      case SceneStage.beats:
        final beat = game.mission.beats[_beatShown];
        return switch (_phase) {
          BeatPhase.cards => [
            QuestionReminder(text: game.question.text, grade: grade),
            AnswerCards<AnswerOption>(
              key: ValueKey('beat-$_beatShown'),
              label: _selected != null && _locked == null
                  ? changeHint
                  : beatLabel(beat.kind, _beatShown, game.mission.beats.length),
              items: game.optionsForBeat(_beatShown),
              textOf: (o) => o.text,
              grade: grade,
              selected: _selected,
              locked: _locked,
              onArrived: _cardsArrived,
              onPick: (o) => _pick(o, reply: false),
            ),
          ],
          BeatPhase.why || BeatPhase.reasons => [
            subtitle(
              beat.why!.line.addressedTo(game.playerName),
              onComplete: _whyTyped,
            ),
            if (_phase == BeatPhase.reasons) ...[
              const SizedBox(height: BrandSpace.md),
              AnswerCards<Reason>(
                key: ValueKey('why-$_beatShown'),
                label: reasonLabel,
                items: game.reasonsForBeat(_beatShown),
                textOf: (r) => r.text,
                grade: grade,
                selected: _reason,
                locked: _reason,
                onPick: _giveReason,
              ),
            ],
          ],
          BeatPhase.reaction => [
            subtitle(_reaction!, onComplete: _reactionTyped),
          ],
        };
      case SceneStage.followUp || SceneStage.replies:
        return [
          subtitle(game.followUpLine!, onComplete: _followUpTyped),
          if (_stage == SceneStage.replies) ...[
            const SizedBox(height: BrandSpace.md),
            AnswerCards<AnswerOption>(
              key: const ValueKey('replies'),
              label: _selected != null && _locked == null
                  ? changeHint
                  : replyLabel,
              items: game.replyOptions,
              textOf: (o) => o.text,
              grade: grade,
              selected: _selected,
              locked: _locked,
              onArrived: _cardsArrived,
              onPick: (o) => _pick(o, reply: true),
            ),
          ],
        ];
    }
  }

  /// The interviewer's face at this point of the scene (brief 16): a smile while she talks,
  /// listening while you draft, thinking while you read the cards, a nod when you lock one in,
  /// "hmm" on the follow-up, and a smile again at the dossier.
  InterviewerExpression get _expression => switch (_stage) {
    SceneStage.card ||
    SceneStage.opening ||
    SceneStage.lines ||
    SceneStage.push ||
    SceneStage.debrief => InterviewerExpression.smile,
    SceneStage.draft => InterviewerExpression.neutral,
    // Her reaction: warm on a strong line, cooler on a weak one, sceptical of a guess.
    SceneStage.beats when _phase == BeatPhase.reaction => switch (_quality) {
      PickQuality.strong => InterviewerExpression.smile,
      PickQuality.weak => InterviewerExpression.thinking,
      PickQuality.guessed || null => InterviewerExpression.hmm,
    },
    SceneStage.beats when _phase != BeatPhase.cards =>
      InterviewerExpression.hmm,
    SceneStage.beats ||
    SceneStage.replies when _locked != null => InterviewerExpression.nod,
    SceneStage.beats => InterviewerExpression.thinking,
    SceneStage.followUp || SceneStage.replies => InterviewerExpression.hmm,
  };

  /// The framings the camera moves through at [stage]: the subtitles start below the lowest
  /// the face gets in any of them.
  static List<SceneShot> _shotsFor(SceneStage stage) => switch (stage) {
    SceneStage.card ||
    SceneStage.opening ||
    SceneStage.lines ||
    SceneStage.push => const [SceneShot.wide, SceneShot.close],
    SceneStage.draft || SceneStage.beats => const [SceneShot.close],
    SceneStage.followUp ||
    SceneStage.replies ||
    SceneStage.debrief => const [SceneShot.tight],
  };
}

/// The overlay: the trust meter at the top, clear of the status bar, and the lower third,
/// starting at [regionTop] (below the face) and clear of the navigation bar.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.regionTop,
    required this.trust,
    required this.grade,
    required this.children,
    this.onTapLowerThird,
    this.guessCue = false,
  });

  /// "Too fast": shown under the trust meter after a guess.
  final bool guessCue;

  final double regionTop;
  final int? trust;
  final ChapterGrade grade;
  final List<Widget> children;

  /// Taps anywhere in the lower third, while it holds only a line (no cards, no draft).
  final VoidCallback? onTapLowerThird;

  static const double _meterWidth = 0.55;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final trust = this.trust;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (trust != null)
          Positioned(
            top: insets.top + BrandSpace.sm,
            left: BrandSpace.lg,
            width: MediaQuery.sizeOf(context).width * _meterWidth,
            child: TrustMeter(trust: trust, grade: grade),
          ),
        Positioned(
          top: insets.top + BrandSpace.sm + TrustMeter.height + BrandSpace.sm,
          left: insets.left + BrandSpace.lg,
          right: insets.right + BrandSpace.lg,
          child: Center(child: GuessCue(shown: guessCue)),
        ),
        // A narrower margin than the meter's: the cards' lines are long, and one line fewer per
        // card is what lets a whole beat fit without scrolling (brief 18).
        Positioned(
          top: regionTop,
          left: insets.left + BrandSpace.md,
          right: insets.right + BrandSpace.md,
          bottom: insets.bottom + BrandSpace.sm,
          child: onTapLowerThird == null
              ? LowerThird(children: children)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapLowerThird,
                  child: LowerThird(children: children),
                ),
        ),
      ],
    );
  }
}

/// The timer's dimming of the room, and its number in the last seconds.
class _TimerShade extends StatelessWidget {
  const _TimerShade({required this.dim, required this.left});

  final double dim;
  final int? left;

  @override
  Widget build(BuildContext context) {
    final left = this.left;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: BrandVivid.night.withValues(alpha: dim)),
          if (left != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + BrandSpace.sm,
              right: BrandSpace.lg,
              child: Semantics(
                liveRegion: true,
                label: '$left seconds',
                excludeSemantics: true,
                child: Text(
                  '$left',
                  style: BrandType.score.copyWith(color: BrandVivid.onDeep),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
