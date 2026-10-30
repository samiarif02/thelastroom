import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/game_sounds.dart';
import '../../ui/film_kit.dart';
import '../debrief/debrief_view.dart';
import 'mission_controller.dart';
import 'mission_lookup.dart';
import 'scene/lower_third.dart';
import 'scene/mission_card.dart';
import 'scene/mission_set.dart';
import 'scene/scene_scrim.dart';
import 'widgets/beat_timer.dart';
import 'widgets/draft_panel.dart';
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

/// One mission, played as a film scene (FR-10–FR-15): title card, letterbox, the interviewer's
/// lines and question, the push in, draft first, three beats on answer cards with the trust
/// meter beating, the follow-up on a hard cut, the reply, then the dossier.
///
/// The game state (picks, the follow-up, the score) is [MissionController]'s; this widget only
/// runs the camera, the subtitles and the timing, and says what happened to [GameSounds].
class MissionPlayer extends ConsumerStatefulWidget {
  const MissionPlayer({super.key, required this.number, required this.onExit});

  final int number;

  /// After the dossier: on to [next] (null after the last mission).
  final void Function(Mission? next) onExit;

  static const String continueLabel = 'Continue the scene';

  /// Shown under a selected card until it's locked.
  static const String lockHint = 'Tap it again to say it';

  @override
  ConsumerState<MissionPlayer> createState() => _MissionPlayerState();
}

class _MissionPlayerState extends ConsumerState<MissionPlayer> {
  // Rests between beats, so each one lands before the next starts.
  static const Duration _beforeLines = Duration(milliseconds: 350);
  static const Duration _afterLock = Duration(milliseconds: 900);
  static const Duration _beforeFollowUp = Duration(milliseconds: 700);
  static const Duration _beforeDebrief = Duration(milliseconds: 1100);

  final TypewriterController _typer = TypewriterController();
  late final AppLifecycleListener _lifecycle;

  SceneStage _stage = SceneStage.card;
  int _line = 0;

  /// The beat on screen. It trails the controller's by the rest after a lock, so the locked
  /// line stays lit before the next beat's cards arrive.
  int _beatShown = 0;
  bool _bars = false;
  bool _closeUp = false;
  bool _tight = false;
  bool _lineTyped = false;
  AnswerOption? _selected;
  AnswerOption? _locked;

  MissionController get _controller =>
      ref.read(missionControllerProvider(widget.number).notifier);
  MissionState get _game =>
      ref.read(missionControllerProvider(widget.number)).requireValue;
  // Kept from the start: `dispose` stops the sound, when `ref` can no longer be read.
  late final GameSounds _sounds = ref.read(gameSoundsProvider);

  /// The setup lines, then the question.
  List<SceneLine> get _lines => [..._game.scene, _game.mission.question];
  bool get _onQuestion => _line == _lines.length - 1;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => _sounds.stopAll(),
      onResume: () => _sounds.ambience(_game.mission.chapter),
    );
    final mission = _game.mission;
    if (mission.opensChapter) _sounds.chapterCard(mission.chapter);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
    if (_stage == SceneStage.lines && _onQuestion) {
      _sounds.questionLands();
      _go(SceneStage.push);
      setState(() => _closeUp = true);
    }
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

  /// A tap on the scene: completes the typing line, or moves on to the next one.
  void _tap() {
    switch (_stage) {
      case SceneStage.card:
        _cardDone();
      case SceneStage.opening:
        _startLines();
      case SceneStage.lines || SceneStage.followUp when !_typer.isComplete:
        _typer.complete();
        _sounds.subtitleCompleted();
      case SceneStage.lines when !_onQuestion:
        setState(() {
          _line++;
          _lineTyped = false;
        });
      case _:
        break;
    }
  }

  void _pick(AnswerOption option, {required bool reply}) {
    if (_locked != null) return;
    if (_selected != option) {
      _sounds.choiceTapped();
      setState(() => _selected = option);
      return;
    }
    _sounds.answerLocked();
    stampThud();
    setState(() => _locked = option);
    if (reply) {
      unawaited(_controller.answerFollowUp(option));
      unawaited(_after(_beforeDebrief, () => _go(SceneStage.debrief)));
      return;
    }
    final before = _game.trust;
    _controller.lock(option);
    final after = _game.trust;
    if (after != before) _sounds.trustChanged(rising: after > before);
    unawaited(_after(_afterLock, _nextBeat));
  }

  void _nextBeat() {
    if (_game.beatsDone) {
      unawaited(_after(_beforeFollowUp, _cutToFollowUp));
      return;
    }
    setState(() {
      _beatShown = _game.beatIndex;
      _selected = null;
      _locked = null;
    });
  }

  void _cutToFollowUp() {
    _go(SceneStage.followUp);
    setState(() {
      _tight = true;
      _lineTyped = false;
      _selected = null;
      _locked = null;
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
        MissionSet.faceBottom(size, _shotsFor(_stage)) + BrandSpace.md;

    if (_stage == SceneStage.debrief && game.score != null) {
      return DebriefView(
        mission: mission,
        score: game.score!,
        trust: game.trust,
        onContinue: () => widget.onExit(mission.next),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: BrandColors.void_),
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
              ),
            ),
          ),
        ),
        if (mission.timed && _stage == SceneStage.beats)
          BeatTimer(
            key: ValueKey(_beatShown),
            running: _locked == null,
            onExpired: _controller.timerExpired,
            onPulse: _sounds.timerPulse,
            builder: (context, dim, left) => _TimerShade(dim: dim, left: left),
          ),
        SceneScrim(from: regionTop / size.height),
        // Taps on the scene itself (anywhere the cards and the draft aren't).
        Semantics(
          button: true,
          label: MissionPlayer.continueLabel,
          onTap: _tap,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap),
        ),
        AnimatedLetterbox(shown: _bars, onSettled: _barsSettled),
        _Overlay(
          regionTop: regionTop,
          trust: _stage.index >= SceneStage.beats.index ? game.trust : null,
          grade: grade,
          children: _lowerThird(game, lead, grade),
        ),
        if (_stage == SceneStage.card)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cardDone,
            child: MissionCard(mission: mission, onFinished: _cardDone),
          ),
      ],
    );
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
          if (_lineTyped && !_onQuestion) const _NextCue(),
        ];
      case SceneStage.draft:
        return [
          QuestionReminder(text: game.mission.question.text, grade: grade),
          const SizedBox(height: BrandSpace.sm),
          DraftPanel(grade: grade, onDone: _draftDone),
        ];
      case SceneStage.beats:
        final beats = game.mission.beats;
        return [
          QuestionReminder(text: game.mission.question.text, grade: grade),
          AnswerCards(
            key: ValueKey('beat-$_beatShown'),
            label: beatLabel(beats[_beatShown].kind, _beatShown, beats.length),
            options: game.optionsForBeat(_beatShown),
            grade: grade,
            selected: _selected,
            locked: _locked,
            hint: _selected != null && _locked == null
                ? MissionPlayer.lockHint
                : null,
            onPick: (o) => _pick(o, reply: false),
          ),
        ];
      case SceneStage.followUp || SceneStage.replies:
        final followUp = game.followUp!;
        return [
          subtitle(followUp.line, onComplete: _followUpTyped),
          if (_stage == SceneStage.replies) ...[
            const SizedBox(height: BrandSpace.md),
            AnswerCards(
              key: const ValueKey('replies'),
              label: replyLabel,
              options: game.replyOptions,
              grade: grade,
              selected: _selected,
              locked: _locked,
              hint: _selected != null && _locked == null
                  ? MissionPlayer.lockHint
                  : null,
              onPick: (o) => _pick(o, reply: true),
            ),
          ],
        ];
    }
  }

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
  });

  final double regionTop;
  final int? trust;
  final ChapterGrade grade;
  final List<Widget> children;

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
          top: regionTop,
          left: insets.left + BrandSpace.lg,
          right: insets.right + BrandSpace.lg,
          bottom: insets.bottom + BrandSpace.md,
          child: LowerThird(children: children),
        ),
      ],
    );
  }
}

/// "▸" after a typed setup line: a tap moves on.
class _NextCue extends StatelessWidget {
  const _NextCue();

  static const String glyph = '▸';

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.only(top: BrandSpace.xs),
      child: ExcludeSemantics(
        child: Text(
          glyph,
          textAlign: TextAlign.center,
          style: BrandType.label.copyWith(color: BrandColors.textSecondary),
        ),
      ),
    ),
  );
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
          ColoredBox(color: BrandColors.void_.withValues(alpha: dim)),
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
                  style: BrandType.score.copyWith(
                    color: BrandColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
