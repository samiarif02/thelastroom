import 'dart:async';
import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/game_sounds.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/daylight/daylight_route.dart' show routeSettled;
import '../../ui/haptics.dart';
import '../../ui/subtitle/typewriter_subtitle.dart';
import '../debrief/ai_score.dart';
import '../debrief/debrief_facts.dart';
import '../debrief/debrief_view.dart';
import '../tips/tip_overlay.dart';
import '../tips/tips.dart';
import 'mission_controller.dart';
import 'mission_lookup.dart';
import 'scene/epilogue_scene.dart';
import 'scene/lower_third.dart';
import 'scene/mission_card.dart';
import 'scene/room_layout.dart';
import 'widgets/beat_timer.dart';
import 'widgets/build_panel.dart';
import 'widgets/choice_card.dart';
import 'widgets/draft_panel.dart';
import 'widgets/leave_control.dart';
import 'widgets/next_control.dart';
import 'widgets/scene_notes.dart';

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

  /// Mission 7's cliffhanger (FR-30), after the debrief and before the chapter report.
  epilogue,
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

/// One mission, played in its room (FR-10–FR-15; Daylight in brief 46, direction.md §2–3): the
/// title card, the interviewer's lines and question typing out in the speech bubble over the
/// room, draft first, three beats on pick cards with "Lock in line B", "why that line?" with
/// the feedback sheet, the follow-up, the reply, then the dossier (kept as it is, owner's
/// rule). Whoever is speaking is the one in the room: a panel's second interviewer takes the
/// lead's place while they talk, never over their face (the playthrough's note).
///
/// The game state (picks, the follow-up, the score) is [MissionController]'s; this widget only
/// runs the scene, the bubble and the timing, and says what happened to [GameSounds].
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
  static const String cardContinueLabel = 'Continue';

  /// After a tap picks a card, another tap can still change it for this long; then it's said.
  /// A tap on the picked card says it at once.
  static const Duration changeWindow = Duration(seconds: 2);

  /// How long "Too fast" stays up after a guess.
  static const Duration guessCueFor = Duration(milliseconds: 2600);

  /// The feedback sheet holds this long before the next beat's cards come up, unless its
  /// "Next" is tapped first.
  static const Duration reactionHold = Duration(milliseconds: 3200);

  /// "Lock in line B", or before a pick.
  static String lockLabel(String? letter) =>
      letter == null ? 'Lock in a line' : 'Lock in line $letter';

  /// The feedback sheet's verdicts (direction.md §3).
  static const String soundTitle = "That's the principle.";
  static const String closeTitle = 'Close, but not quite.';
  static const String guessTitle = 'You barely looked at those.';

  /// A built answer that's every piece, in order: no principle was asked for (QA 51).
  static const String builtTitle = 'Every piece, in order.';

  /// The sheet's next step.
  static String nextStep(BeatKind? next) => switch (next) {
    null => 'Next: the follow-up',
    BeatKind.open => 'Next: open the answer',
    BeatKind.evidence => 'Next: back it up',
    BeatKind.land => 'Next: land the answer',
  };
  static const String sayWhy = 'Next: say why';
  static const String yourLine = 'Your line';

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
  static const Duration _questionRest = Duration(milliseconds: 700);

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
  bool _lineTyped = false;
  BeatPhase _phase = BeatPhase.cards;

  /// When the cards on screen finished arriving: the stopwatch's zero. Null until then, so a
  /// tap on a card still sliding in is timed at zero (a guess).
  Duration? _shownAt;

  /// The card picked, while it can still be changed ([MissionPlayer.changeWindow]).
  AnswerOption? _selected;
  Duration? _decidedIn;
  Timer? _changeTimer;

  /// The card said: locked in, the others dark. On a built beat, the built answer.
  AnswerOption? _locked;

  /// A built beat's fragments placed so far, in the order tapped (brief 27).
  List<String> _placed = const [];
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

  /// Kept from the start: `dispose` hands back a tip still up, when `ref` can't be read.
  late final TipsController _tips = ref.read(tipsProvider.notifier);

  /// The first-time tip over the cards or the reasons, and where its target is.
  Tip? _tip;
  Rect? _tipAt;
  final GlobalKey _scene = GlobalKey();
  final GlobalKey _cardsKey = GlobalKey();
  final GlobalKey _dockKey = GlobalKey();
  final GlobalKey _reasonsKey = GlobalKey();

  PlayerProfile get _profile =>
      ref.read(profileProvider).value ?? const PlayerProfile();

  /// The setup lines, then the question.
  List<SceneLine> get _lines => [..._game.scene, _game.question];
  bool get _onQuestion => _line == _lines.length - 1;

  Duration _now() => ref.read(decisionClockProvider)();

  @override
  void initState() {
    super.initState();
    // Resolved now, not lazily: `dispose` stops the sound, and `ref` can't be read by then.
    _sounds;
    _tips;
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
    _lineTyped = true;
    if (game.beatsDone) {
      _stage = SceneStage.followUp;
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
    if (_tip case final tip?) _tips.release(tip);
    _changeTimer?.cancel();
    _reactionTimer?.cancel();
    for (final t in _rests) {
      t.cancel();
    }
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

  /// The scene's rests, as timers: leaving the room cancels the ones still to run.
  final Set<Timer> _rests = {};

  Future<void> _after(Duration rest, VoidCallback then) async {
    final still = MediaQuery.disableAnimationsOf(context);
    final done = Completer<void>();
    late final Timer timer;
    timer = Timer(still ? Duration.zero : rest, () {
      _rests.remove(timer);
      if (mounted) then();
      done.complete();
    });
    _rests.add(timer);
    return done.future;
  }

  // The scene's beats, in order.

  void _cardDone() {
    if (_stage != SceneStage.card) return;
    _sounds.ambience(_game.mission.chapter);
    _go(SceneStage.opening);
    // No letterbox in the daylit room: the lines start after a breath.
    unawaited(_after(_beforeLines, _startLines));
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
      // The question has landed: a beat to read it, then the draft or the cards.
      unawaited(_after(_questionRest, _pushDone));
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
      case SceneStage.push:
        _pushDone();
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

  /// The last card arrived: the player can read them all, and the stopwatch starts. The first
  /// time, a tip says what to do with them.
  void _cardsArrived() {
    _shownAt ??= _now();
    _offerTip(Tip.answerCards);
  }

  /// Whether [tip] still belongs on screen: the first beat's cards, nothing picked yet (never a
  /// built answer or the follow-up's replies), or the reasons, none given yet.
  bool _tipFits(Tip tip) {
    if (_stage != SceneStage.beats || _leaving) return false;
    return switch (tip) {
      Tip.answerCards =>
        _phase == BeatPhase.cards &&
            _selected == null &&
            _locked == null &&
            _game.mission.beats[_beatShown].build == null,
      Tip.whyStep => _phase == BeatPhase.reasons && _reason == null,
      _ => false,
    };
  }

  /// Puts [tip] up over its target, once it has arrived, when it's due and nothing else is up.
  /// A target that isn't on screen skips it this time.
  void _offerTip(Tip tip) {
    if (_tip != null || !_tips.canShow(tip) || !_tipFits(tip)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Measure where the target rests, once the room has opened (brief 50's transitions).
      if (!mounted) return;
      await routeSettled(context);
      final scene = _scene.currentContext;
      if (!mounted ||
          scene == null ||
          !scene.mounted ||
          _tip != null ||
          !_tipFits(tip)) {
        return;
      }
      var at = tipTarget(
        tip == Tip.answerCards ? _cardsKey : _reasonsKey,
        scene,
      );
      // The cards and the "Lock in" under them: the line, then locking it in.
      final dock = tip == Tip.answerCards ? tipTarget(_dockKey, scene) : null;
      if (at != null && dock != null) at = at.expandToInclude(dock);
      if (at == null || !_tips.shown(tip)) return;
      setState(() {
        _tip = tip;
        _tipAt = at;
      });
    });
  }

  void _endTip(TipAction action) {
    final tip = _tip;
    if (tip == null) return;
    setState(() {
      _tip = null;
      _tipAt = null;
    });
    unawaited(_tips.done(tip, action));
  }

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
    // Nothing locked: the scene showed a beat the attempt isn't on (QA 51, BUG-2). Go to the
    // beat (or the why step) it's really at, never react to an old beat's line and skip on.
    if (!_controller.lock(option, decidedIn: _decidedIn)) {
      _nextBeat();
      return;
    }
    _trustMoved(before);
    _beatLocked();
  }

  /// A fragment tapped on a built beat: placed at the end of the answer, or taken out.
  void _toggleFragment(Fragment fragment) {
    if (_locked != null) return;
    _sounds.choiceTapped();
    setState(
      () => _placed = _placed.contains(fragment.id)
          ? [..._placed.where((id) => id != fragment.id)]
          : [..._placed, fragment.id],
    );
  }

  /// "Lock it in" on a built beat: the answer is said, timed from when the chips were up.
  void _lockBuilt() {
    if (_locked != null || _placed.isEmpty || !mounted) return;
    final shownAt = _shownAt;
    _decidedIn = shownAt == null ? Duration.zero : _now() - shownAt;
    _sounds.answerLocked();
    stampThud();
    final before = _game.trust;
    if (!_controller.lockBuilt(_placed, decidedIn: _decidedIn)) {
      _nextBeat(); // out of step, as in [_say]
      return;
    }
    setState(() => _locked = _game.plays.last.option);
    _trustMoved(before);
    _beatLocked();
  }

  /// After a beat's line is locked: a guess is called out first, then the why step or her
  /// reaction.
  void _beatLocked() {
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
    final line = _game.reactionFor(_beatShown, quality);
    if (line == null) {
      then();
      return;
    }
    if (quality == PickQuality.strong) successTap();
    setState(() {
      _phase = BeatPhase.reaction;
      _reaction = line.addressedTo(_game.playerName);
      _quality = quality;
      _afterReaction = then;
    });
    // Reading time, kept under reduced motion too: only movement goes, never the time to read.
    _reactionTimer?.cancel();
    _reactionTimer = Timer(MissionPlayer.reactionHold, () {
      if (mounted) _reactionDone();
    });
  }

  Timer? _reactionTimer;

  /// On from the reaction (its hold ran out, or a tap).
  void _reactionDone() {
    final then = _afterReaction;
    if (_phase != BeatPhase.reaction || then == null) return;
    _reactionTimer?.cancel();
    _afterReaction = null;
    then();
  }

  /// On to the beat the attempt is at: the next one's cards, or a why step still owed.
  void _nextBeat() {
    final game = _game;
    if (game.beatsDone) {
      unawaited(_after(_beforeFollowUp, _cutToFollowUp));
      return;
    }
    setState(() {
      _beatShown = game.awaitingWhy ? game.plays.length - 1 : game.beatIndex;
      _phase = game.awaitingWhy ? BeatPhase.why : BeatPhase.cards;
      _shownAt = null;
      _selected = null;
      _decidedIn = null;
      _locked = null;
      _placed = const [];
      _reason = null;
      _reaction = null;
      _quality = null;
      _calledOut = false;
      _lineTyped = false;
    });
  }

  void _cutToFollowUp() {
    _go(SceneStage.followUp);
    final line = _game.followUpLine;
    if (line != null) _sounds.followUpChallenge(line.speakerId);
    setState(() {
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

  /// On from the dossier: the chapter's cliffhanger first when the mission has one (Mission 7),
  /// then out.
  void _afterDebrief() {
    if (_game.mission.epilogue.isEmpty) {
      widget.onExit();
      return;
    }
    _go(SceneStage.epilogue);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref
        .watch(missionControllerProvider(widget.number))
        .requireValue;
    final mission = game.mission;
    final grade = mission.grade;

    if (_stage == SceneStage.debrief && game.score != null) {
      // The Candidate assessment, exactly as it was (the owner's rule), on Daylight's ground.
      return DebriefView(
        mission: mission,
        score: game.score!,
        trust: game.trust,
        firstTry: game.firstTry,
        reasoning: reasoningOf(mission, game.plays),
        baselineDraft: game.baselineDraft,
        // The answer for the AI recruiter (brief 22); the dossier falls back by itself.
        scoreRequest: game.followUp != null && game.reply != null
            ? ScoreRequest(
                mission: mission,
                plays: game.plays,
                followUp: game.followUp!,
                reply: game.reply!,
              )
            : null,
        onContinue: _afterDebrief,
      );
    }
    if (_stage == SceneStage.epilogue) {
      // Daylight (brief 48): the epilogue draws its own ground, no film grain over it.
      return EpilogueScene(
        lines: [
          for (final line in mission.epilogue)
            line.addressedTo(game.playerName),
        ],
        grade: grade,
        sounds: _sounds,
        doneLabel: mission.leadsToReport
            ? DebriefView.reportLabel
            : DebriefView.continueLabel,
        onDone: widget.onExit,
      );
    }

    final f = grade.floor;
    final insets = MediaQuery.paddingOf(context);
    // The system's gesture bar, even where an inset has been consumed above us (QA 51: the
    // build's "Lock it in" sat on it).
    final bottomSafe = math.max(
      insets.bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    // At large text the room shrinks to a strip, so all the cards still fit above the dock.
    final compact =
        MediaQuery.textScalerOf(context).scale(DaylightSpace.s16) >
        DaylightSpace.s16 * _compactAt;
    final dock = _dock(game);
    // Four lines to pick from: the room steps back to a strip, so every card fits above the
    // dock without scrolling (brief 18: one tap per choice).
    final fits = MediaQuery.sizeOf(context).height >= _roomFitsFrom
        ? _cardsThatFit
        : _cardsThatFit - 1;
    final many =
        (_stage == SceneStage.beats &&
            _phase == BeatPhase.cards &&
            game.optionsForBeat(_beatShown).length > fits) ||
        (_stage == SceneStage.replies && game.replyOptions.length > fits);
    return PopScope<Object?>(
      // Back mid-mission never just closes the scene: it asks first, and keeps the attempt.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_leaving) setState(() => _leaving = true);
      },
      child: DaylightGround(
        color: f.tint,
        floor: f,
        child: Stack(
          key: _scene,
          fit: StackFit.expand,
          children: [
            // Taps on the room itself (anywhere the cards, the draft and the dock aren't).
            Positioned.fill(
              child: Semantics(
                button: true,
                label: MissionPlayer.continueLabel,
                onTap: _tap,
                // One labelled node: the detector adds no second, unlabelled tap.
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(game),
                  if (mission.timed &&
                      !_profile.calmMode &&
                      _stage == SceneStage.beats &&
                      _phase == BeatPhase.cards &&
                      mission.beats[_beatShown].build == null)
                    BeatTimer(
                      key: ValueKey(_beatShown),
                      // Paused under a tip: never a countdown while the player reads one.
                      running: _locked == null && _tip == null,
                      onExpired: _controller.timerExpired,
                      onPulse: _sounds.timerPulse,
                      builder: (context, dim, left) => TimerLine(
                        elapsed: dim / BeatTimer.maxDim,
                        secondsLeft: left,
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      hitTestBehavior: HitTestBehavior.deferToChild,
                      padding: EdgeInsets.fromLTRB(
                        DaylightSpace.s16,
                        DaylightSpace.s12,
                        DaylightSpace.s16,
                        dock == null
                            ? bottomSafe + DaylightSpace.s24
                            : DaylightSpace.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _room(game, compact: compact, many: many),
                      ),
                    ),
                  ),
                  if (dock != null)
                    Padding(
                      key: _dockKey,
                      padding: EdgeInsets.fromLTRB(
                        DaylightSpace.s16,
                        DaylightSpace.s8,
                        DaylightSpace.s16,
                        bottomSafe + DaylightSpace.s16,
                      ),
                      child: dock,
                    ),
                ],
              ),
            ),
            Positioned(
              top: insets.top + DaylightSize.hit + DaylightSpace.s16,
              left: DaylightSpace.s16,
              right: DaylightSpace.s16,
              child: Center(child: GuessCue(shown: _guessCue)),
            ),
            if (_stage == SceneStage.beats &&
                _phase == BeatPhase.reaction &&
                _reaction != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _feedback(game, _reaction!),
              ),
            if ((_tip, _tipAt) case (final tip?, final at?) when !_leaving)
              TipOverlay(
                key: ValueKey(tip),
                voice: TipVoice.inRoom(
                  CastPeople.byId(_speaker(game).id),
                  grade.floor,
                ),
                line: tip.line,
                target: at,
                // Cards to choose between: a tap on them only puts the tip away (BUG-2).
                kind: TipTarget.choice,
                onTarget: () => _endTip(TipAction.followed),
                onDismiss: () => _endTip(TipAction.dismissed),
              ),
            if (_stage == SceneStage.card)
              // The card's title stays readable; the tap on it is one labelled button.
              Semantics(
                button: true,
                label: MissionPlayer.cardContinueLabel,
                onTap: _cardDone,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: _cardDone,
                  child: MissionCard(mission: mission, onFinished: _cardDone),
                ),
              ),
            if (_leaving)
              LeaveSheet(
                grade: grade,
                onResume: () => setState(() => _leaving = false),
                onLeave: _leave,
              ),
          ],
        ),
      ),
    );
  }

  /// Text this much larger than default shrinks the room to a strip.
  static const double _compactAt = 1.3;

  /// Cards that fit under the full room (direction.md §2: three at 390 × 844), and the
  /// height from which they do; on a shorter phone, two.
  static const int _cardsThatFit = 3;
  static const double _roomFitsFrom = 840;

  Future<void> _leave() async {
    _changeTimer?.cancel();
    _sounds.stopAll();
    await _controller.leave();
    if (mounted) widget.onLeave();
  }

  /// The top bar: the way out, then where the answer stands (the beats once they start; the
  /// floor and the room before), then trust.
  Widget _topBar(MissionState game) {
    final mission = game.mission;
    final inBeats = _stage.index >= SceneStage.beats.index;
    final beats = [for (final b in mission.beats) beatName(b.kind)];
    final current = _stage.index > SceneStage.beats.index
        ? beats.length
        : _beatShown;
    final within = switch (_phase) {
      BeatPhase.cards => _locked == null ? 0.2 : 0.5,
      BeatPhase.why || BeatPhase.reasons => 0.6,
      BeatPhase.reaction => 0.9,
    };
    return DaylightTopBar(
      leadingLabel: LeaveControl.label,
      onLeading: _stage == SceneStage.card || _leaving
          ? null
          : () => setState(() => _leaving = true),
      kicker: inBeats ? null : MissionCard.kicker(mission),
      title: inBeats ? null : mission.title,
      middle: inBeats
          ? BeatProgress(
              beats: beats,
              current: current,
              progress: _stage == SceneStage.beats ? within : 0,
            )
          : null,
      trailing: inBeats
          ? TrustPips(trust: _pips(game.trust), icon: PhosphorFill.handshake)
          : null,
    );
  }

  /// Trust (0–100) as the five pips.
  static int _pips(int trust) => (trust / _perPip).round().clamp(0, _maxPips);
  static const int _perPip = 20;
  static const int _maxPips = 5;

  /// Who's speaking now: the one the room shows (a panel's second interviewer takes the
  /// lead's place while they talk).
  Interviewer _speaker(MissionState game) {
    final mission = game.mission;
    final id = switch (_stage) {
      SceneStage.lines || SceneStage.push => _lines[_line].speakerId,
      SceneStage.followUp || SceneStage.replies => game.followUpLine?.speakerId,
      SceneStage.beats when _phase == BeatPhase.reaction =>
        _reaction?.speakerId,
      SceneStage.beats when _phase != BeatPhase.cards =>
        mission.beats[_beatShown].why?.line.speakerId,
      _ => null,
    };
    return id == null ? mission.lead : interviewerById(id);
  }

  /// The bubble: the line typing out ([onComplete] when it's whole), or [line] already said.
  Widget _bubble(
    SceneLine line, {
    VoidCallback? onComplete,
    bool typed = false,
    bool side = false,
    TextStyle? style,
  }) {
    final who = interviewerById(line.speakerId);
    final sounds = _sounds;
    // The room around it takes the tap (complete the line, or move on): one region, so the
    // first tap never misses (brief 18).
    return IgnorePointer(
      child: TypewriterSubtitle(
        // A line already said and the same line typing are different bubbles: each starts fresh.
        key: ValueKey('${line.speakerId}-${line.text}-$typed'),
        daylight: true,
        tailLeft: side,
        floor: _game.mission.grade.floor,
        lineStyle: style,
        speaker: side ? who.name : '${who.name} · ${who.role.toLowerCase()}',
        line: line.text,
        play: !typed,
        controller: typed ? null : _typer,
        onCharacter: typed
            ? null
            : (c, _) => sounds.subtitleCharacter(line.speakerId, c),
        onComplete: onComplete,
      ),
    );
  }

  /// What's in the room at this point, top to bottom.
  List<Widget> _room(
    MissionState game, {
    required bool compact,
    bool many = false,
  }) {
    final mission = game.mission;
    final who = _speaker(game);
    final person = CastPeople.byId(who.id);
    final label = '${who.name}, the ${who.role.toLowerCase()}';
    final tapRoom =
        _stage.index <= SceneStage.push.index ||
            _stage == SceneStage.followUp ||
            (_stage == SceneStage.beats &&
                (_phase == BeatPhase.why || _phase == BeatPhase.reaction))
        ? _tapLowerThird
        : _tap;
    Widget room(Widget bubble) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: tapRoom,
      child: RoomWithBubble(
        person: person,
        expression: _expression,
        bubble: bubble,
        semanticLabel: label,
        compact: compact,
      ),
    );
    // Four cards to fit: the interviewer steps out of the room into a small arch beside her
    // question, so every card is on screen at once.
    Widget asked(
      SceneLine line, {
      VoidCallback? onComplete,
      bool typed = true,
    }) => many
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: tapRoom,
            child: WhyHeader(
              person: person,
              expression: _expression,
              semanticLabel: label,
              compact: true,
              bubble: _bubble(
                line,
                typed: typed,
                onComplete: onComplete,
                side: true,
                style: DaylightType.body1,
              ),
            ),
          )
        : room(_bubble(line, typed: typed, onComplete: onComplete));
    final question = game.question;
    switch (_stage) {
      case SceneStage.card || SceneStage.opening:
        // The room, before anyone speaks.
        return [room(const SizedBox(height: RoomWithBubble.overlap))];
      case SceneStage.debrief || SceneStage.epilogue:
        return const [];
      case SceneStage.lines || SceneStage.push:
        return [room(_bubble(_lines[_line], onComplete: _lineDone))];
      case SceneStage.draft:
        return [
          room(_bubble(question, typed: true)),
          const SizedBox(height: DaylightSpace.s16),
          DraftPanel(grade: mission.grade, onDone: _draftDone),
        ];
      case SceneStage.beats:
        final beat = mission.beats[_beatShown];
        final build = beat.build;
        final before = _beatShown == 0 ? null : game.plays[_beatShown - 1];
        final soFar = before == null
            ? null
            : QuestionReminder(
                label: beatName(mission.beats[_beatShown - 1].kind),
                text: before.option.text,
                grade: mission.grade,
              );
        final whyAsked = _phase != BeatPhase.reaction || !game.awaitingWhy;
        if (_phase == BeatPhase.cards) {
          return [
            asked(question),
            if (soFar != null && !many) ...[
              const SizedBox(height: DaylightSpace.s12),
              soFar,
            ],
            const SizedBox(height: DaylightSpace.s16),
            if (build != null)
              BuildPanel(
                key: ValueKey('build-$_beatShown'),
                label: buildLabel(_beatShown, mission.beats.length),
                fragments: game.fragmentsForBeat(_beatShown),
                placed: _placed,
                grade: mission.grade,
                locked: _locked != null,
                onArrived: _cardsArrived,
                onToggle: _toggleFragment,
                // "Lock it in" is pinned in the dock, above the gesture bar.
              )
            else
              KeyedSubtree(
                key: _cardsKey,
                child: AnswerCards<AnswerOption>(
                  key: ValueKey('beat-$_beatShown'),
                  label: beatLabel(beat.kind, _beatShown, mission.beats.length),
                  helper: _selected != null && _locked == null
                      ? changeHint
                      : pickHelper,
                  items: game.optionsForBeat(_beatShown),
                  textOf: (o) => o.text,
                  grade: mission.grade,
                  selected: _selected,
                  locked: _locked,
                  onArrived: _cardsArrived,
                  onPick: (o) => _pick(o, reply: false),
                ),
              ),
          ];
        }
        // "Why that line?": the interviewer beside the question, the line said, the reasons.
        // A guess is called out *before* she asks why (the feedback sheet over the room): her
        // why line must not start typing under that sheet, or it finishes while nobody is
        // listening for it and the reasons never come (the owner's stuck "Why that example?").
        // A built beat asks no why: its reasons stay in the content for the Recall Room only,
        // never under her reaction (QA 51: reason cards and "That's the principle." with none
        // picked).
        final why = whyAsked && build == null ? beat.why : null;
        final said = game.plays.length > _beatShown
            ? game.plays[_beatShown].option.text
            : _locked?.text;
        return [
          if (why != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: tapRoom,
              child: WhyHeader(
                person: person,
                expression: _expression,
                semanticLabel: label,
                compact: compact,
                bubble: _bubble(
                  why.line.addressedTo(game.playerName),
                  onComplete: _whyTyped,
                  side: true,
                  style: DaylightType.heading5,
                ),
              ),
            )
          else
            room(_bubble(question, typed: true)),
          if (said != null) ...[
            const SizedBox(height: DaylightSpace.s16),
            YourLine(label: MissionPlayer.yourLine, text: said),
          ],
          if (_phase != BeatPhase.why && why != null) ...[
            const SizedBox(height: DaylightSpace.s24),
            KeyedSubtree(
              key: _reasonsKey,
              child: AnswerCards<Reason>(
                key: ValueKey('why-$_beatShown'),
                label: reasonLabel,
                helper: reasonHelper,
                items: game.reasonsForBeat(_beatShown),
                textOf: (r) => r.text,
                iconOf: (r) => principleIcon(r.text),
                grade: mission.grade,
                selected: _reason,
                locked: _reason,
                onArrived: () => _offerTip(Tip.whyStep),
                onPick: _giveReason,
              ),
            ),
          ],
          // Room under the cards for the sheet that rises over them.
          if (_phase == BeatPhase.reaction)
            const SizedBox(height: DaylightSpace.s96 * 2),
        ];
      case SceneStage.followUp || SceneStage.replies:
        final line = game.followUpLine!;
        return [
          if (_stage == SceneStage.replies)
            asked(line)
          else
            room(_bubble(line, onComplete: _followUpTyped)),
          if (_stage == SceneStage.replies) ...[
            const SizedBox(height: DaylightSpace.s16),
            AnswerCards<AnswerOption>(
              key: const ValueKey('replies'),
              label: replyLabel,
              helper: _selected != null && _locked == null
                  ? changeHint
                  : pickHelper,
              items: game.replyOptions,
              textOf: (o) => o.text,
              grade: mission.grade,
              selected: _selected,
              locked: _locked,
              onArrived: _cardsArrived,
              onPick: (o) => _pick(o, reply: true),
            ),
          ],
        ];
    }
  }

  /// The dock under the room: "Next" under a typed setup line, "Lock in line B" under the
  /// cards (disabled until a pick). Null when there's nothing to press there.
  Widget? _dock(MissionState game) {
    final mission = game.mission;
    final onCards =
        (_stage == SceneStage.beats &&
            _phase == BeatPhase.cards &&
            mission.beats[_beatShown].build == null) ||
        _stage == SceneStage.replies;
    // A built beat's "Lock it in": pinned like the cards' button, so a long build never pushes
    // it down under the system's gesture bar (QA 51).
    if (_stage == SceneStage.beats &&
        _phase == BeatPhase.cards &&
        mission.beats[_beatShown].build != null) {
      return TactileButton(
        label: BuildPanel.lockIn,
        icon: PhosphorBold.lockSimple,
        onPressed: _placed.isEmpty || _locked != null ? null : _lockBuilt,
      );
    }
    if (onCards) {
      final items = _stage == SceneStage.replies
          ? game.replyOptions
          : game.optionsForBeat(_beatShown);
      final picked = _selected;
      final i = picked == null ? -1 : items.indexOf(picked);
      return TactileButton(
        label: MissionPlayer.lockLabel(i < 0 ? null : ChoiceCard.letterFor(i)),
        icon: PhosphorBold.lockSimple,
        onPressed: picked == null || _locked != null
            ? null
            : () => _say(reply: _stage == SceneStage.replies),
      );
    }
    if (_stage == SceneStage.lines && _lineTyped && !_onQuestion) {
      return AnimatedBuilder(
        animation: _countdown,
        builder: (context, _) {
          final counting = _profile.autoAdvance;
          final left = 1 - _countdown.value;
          return NextControl(
            grade: mission.grade,
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
      );
    }
    return null;
  }

  /// The sheet after a beat (motion 3): her reaction, how it landed, and the next step.
  Widget _feedback(MissionState game, SceneLine reaction) {
    final mission = game.mission;
    final who = interviewerById(reaction.speakerId);
    final guessedFirst = _calledOut && _game.awaitingWhy;
    final (tone, title) = switch (_quality) {
      PickQuality.strong => (
        FeedbackTone.sound,
        mission.beats[_beatShown].build == null
            ? MissionPlayer.soundTitle
            : MissionPlayer.builtTitle,
      ),
      PickQuality.weak => (FeedbackTone.close, MissionPlayer.closeTitle),
      PickQuality.guessed ||
      null => (FeedbackTone.guess, MissionPlayer.guessTitle),
    };
    final nextIndex = _beatShown + 1;
    final next = guessedFirst
        ? MissionPlayer.sayWhy
        : MissionPlayer.nextStep(
            nextIndex < mission.beats.length
                ? mission.beats[nextIndex].kind
                : null,
          );
    return FeedbackSheet(
      key: ValueKey('feedback-$_beatShown-${reaction.text}'),
      person: CastPeople.byId(who.id),
      tone: tone,
      title: title,
      // Her words, as she says them (the arch shows who).
      note: reaction.text,
      actionLabel: next,
      onAction: _reactionDone,
    );
  }

  /// The interviewer's face at this point (direction.md, the cast's states): talking while a
  /// line types, listening while the player chooses or drafts, a nod when a line is locked in,
  /// thinking on "why?", and the reaction's face after: a smile on a strong line, "hmm" on a
  /// weak one or a guess.
  CastExpression get _expression => switch (_stage) {
    SceneStage.card || SceneStage.opening => CastExpression.smile,
    SceneStage.lines || SceneStage.push || SceneStage.followUp =>
      _lineTyped ? CastExpression.neutral : CastExpression.talk,
    SceneStage.debrief || SceneStage.epilogue => CastExpression.smile,
    SceneStage.draft => CastExpression.listening,
    SceneStage.beats when _phase == BeatPhase.reaction => switch (_quality) {
      PickQuality.strong => CastExpression.smile,
      PickQuality.weak || PickQuality.guessed || null => CastExpression.hmm,
    },
    SceneStage.beats when _phase != BeatPhase.cards =>
      _reason == null ? CastExpression.thinking : CastExpression.nod,
    SceneStage.beats ||
    SceneStage.replies when _locked != null => CastExpression.nod,
    SceneStage.beats || SceneStage.replies => CastExpression.listening,
  };
}
