import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/film_kit.dart';
import '../debrief/debrief_view.dart';
import '../mission/mission_lookup.dart';
import '../mission/scene/epilogue_scene.dart';
import '../mission/scene/lower_third.dart';
import '../mission/scene/mission_card.dart';
import '../mission/scene/mission_set.dart';
import '../mission/scene/scene_scrim.dart';
import '../mission/widgets/leave_control.dart';
import 'recorder/recorder_panel.dart';
import 'recorder/take_recorder.dart';
import 'speech/interviewer_voice.dart';
import 'voice_controller.dart';
import 'voice_debrief.dart';
import 'voice_providers.dart';
import 'widgets/scene_controls.dart';
import 'widgets/self_check_panel.dart';
import 'widgets/voice_sheet.dart';

/// Where a voice mission's scene is. Later stages never go back.
enum VoiceStage {
  /// The mission's title card.
  card,

  /// The letterbox bars slide in.
  opening,

  /// The setup lines and the question, typed and spoken.
  lines,

  /// The question has landed: the push in.
  push,

  /// The player answers out loud.
  answer,

  /// The interviewer pushes back, after the hard cut.
  followUp,

  /// The player answers the follow-up.
  reply,

  /// Mission 7-style cliffhanger lines after the debrief, when the mission has them.
  epilogue,
}

/// A voice mission (brief 35): the interviewer's lines spoken aloud as they type, the player's
/// answer recorded, the spoken follow-up and the recorded reply, then the recruiter listening
/// (or the self-check), then the debrief. The takes, the verdict and the score are
/// [VoiceController]'s; this widget runs the camera, the subtitles, the voice and the recorders.
class VoicePlayer extends ConsumerStatefulWidget {
  const VoicePlayer({
    super.key,
    required this.number,
    required this.onExit,
    required this.onLeave,
  });

  final int number;
  final VoidCallback onExit;
  final VoidCallback onLeave;

  static const String continueLabel = 'Continue the scene';
  static const String leaveTitle = 'Leave the interview?';
  static const String leaveLine =
      "Your recording isn't kept. You can start this room again whenever you like.";
  static const String stay = 'Stay';
  static const String leave = 'Leave';

  /// A spoken, typed line holds this long before the next one starts.
  static const Duration lineRest = Duration(milliseconds: 700);

  @override
  ConsumerState<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends ConsumerState<VoicePlayer> {
  static const Duration _beforeLines = Duration(milliseconds: 350);
  static const Duration _beforeFollowUp = Duration(milliseconds: 700);

  final TypewriterController _typer = TypewriterController();
  VoiceStage _stage = VoiceStage.card;
  int _line = 0;
  bool _bars = false;
  bool _closeUp = false;
  bool _tight = false;
  bool _typed = false;
  bool _spoken = false;
  bool _leaving = false;

  /// The microphone was refused or skipped: the reply is said aloud too, with no recorder.
  bool _noMicrophone = false;

  /// Bumped for every new line, so a slow `say` for an old line can't move a new one on.
  int _lineToken = 0;
  TakeRecorder? _recorder;

  VoiceController get _controller =>
      ref.read(voiceControllerProvider(widget.number).notifier);
  VoiceState get _game =>
      ref.read(voiceControllerProvider(widget.number)).requireValue;
  late final GameSounds _sounds = ref.read(gameSoundsProvider);
  late final InterviewerVoice _voice = ref.read(interviewerVoiceProvider);

  List<SceneLine> get _lines => [..._game.scene, _game.question];
  bool get _onQuestion => _line == _lines.length - 1;
  bool get _muted => ref.read(interviewerMutedProvider);

  @override
  void initState() {
    super.initState();
    final mission = _game.mission;
    if (mission.opensChapter) _sounds.chapterCard(mission.chapter);
  }

  @override
  void dispose() {
    _recorder?.dispose();
    unawaited(_voice.stop());
    _typer.dispose();
    _sounds.stopAll();
    super.dispose();
  }

  void _go(VoiceStage stage) {
    if (!mounted || stage.index <= _stage.index) return;
    setState(() => _stage = stage);
  }

  Future<void> _after(Duration rest, VoidCallback then) async {
    final still = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(still ? Duration.zero : rest);
    if (mounted) then();
  }

  // The interviewer's lines: each typed and spoken; both done, the scene moves on.

  /// Starts saying [line]; [_spoken] turns true when it's said (at once when muted).
  void _say(SceneLine line) {
    final token = ++_lineToken;
    _typed = false;
    _spoken = _muted;
    if (_muted) return;
    unawaited(
      _voice.say(line).then((_) {
        if (!mounted || token != _lineToken) return;
        setState(() => _spoken = true);
        _maybeMoveOn();
      }),
    );
  }

  void _lineTyped() {
    setState(() => _typed = true);
    _maybeMoveOn();
  }

  /// A line typed and said: on to the next line, the push, or the reply.
  void _maybeMoveOn() {
    if (!_typed || !_spoken) return;
    final token = _lineToken;
    unawaited(
      _after(VoicePlayer.lineRest, () {
        if (token == _lineToken) _advance();
      }),
    );
  }

  void _advance() {
    switch (_stage) {
      case VoiceStage.lines when _onQuestion:
        _sounds.questionLands();
        _go(VoiceStage.push);
        setState(() => _closeUp = true);
      case VoiceStage.lines:
        setState(() => _line++);
        _say(_lines[_line]);
      case VoiceStage.followUp:
        _startRecorder();
        _go(VoiceStage.reply);
      case _:
        break;
    }
  }

  void _cardDone() {
    if (_stage != VoiceStage.card) return;
    _sounds.ambience(_game.mission.chapter);
    _go(VoiceStage.opening);
    setState(() => _bars = true);
  }

  void _barsSettled() {
    if (_bars && _stage == VoiceStage.opening) {
      unawaited(_after(_beforeLines, _startLines));
    }
  }

  void _startLines() {
    if (_stage != VoiceStage.opening) return;
    _go(VoiceStage.lines);
    _controller.sceneStarted();
    _say(_lines[_line]);
  }

  void _pushDone() {
    if (_stage != VoiceStage.push) return;
    setState(() => _bars = false);
    _startRecorder();
    _go(VoiceStage.answer);
  }

  /// A tap on the scene: completes the typing line, or moves on from a typed one.
  void _tap() {
    switch (_stage) {
      case VoiceStage.card:
        _cardDone();
      case VoiceStage.opening:
        _startLines();
      case VoiceStage.lines || VoiceStage.followUp when !_typer.isComplete:
        _typer.complete();
        _sounds.subtitleCompleted();
      case VoiceStage.lines || VoiceStage.followUp when _typed:
        // The player has read it: stop the voice and go on.
        _lineToken++;
        unawaited(_voice.stop());
        _advance();
      case _:
        break;
    }
  }

  void _toggleMute() {
    ref.read(interviewerMutedProvider.notifier).toggle();
    if (_muted) {
      unawaited(_voice.stop());
      setState(() => _spoken = true);
      _maybeMoveOn();
    }
  }

  // The answers.

  void _startRecorder() {
    _recorder?.dispose();
    _recorder = null;
    if (_noMicrophone) return;
    final recorder = TakeRecorder(
      microphone: ref.read(microphoneFactoryProvider)(),
      maxLength: Duration(seconds: _game.voice.maxSeconds),
      log: ref.read(logProvider),
    );
    _recorder = recorder;
    unawaited(_voice.stop());
    unawaited(recorder.start());
  }

  void _answered(Take? take) {
    if (_stage != VoiceStage.answer) return;
    _sounds.answerLocked();
    _controller.answered(take);
    _recorder?.dispose();
    _recorder = null;
    unawaited(_after(_beforeFollowUp, _cutToFollowUp));
  }

  void _cutToFollowUp() {
    _go(VoiceStage.followUp);
    setState(() => _tight = true);
    _say(_game.followUp);
  }

  void _replied(Take? take) {
    if (_stage != VoiceStage.reply) return;
    _sounds.answerLocked();
    _recorder?.dispose();
    setState(() => _recorder = null);
    unawaited(_controller.replied(take));
  }

  void _withoutMicrophone() {
    setState(() => _noMicrophone = true);
    _recorder?.dispose();
    _recorder = null;
  }

  void _afterDebrief() {
    _controller.discardTakes();
    if (_game.mission.epilogue.isEmpty) {
      widget.onExit();
      return;
    }
    setState(() => _stage = VoiceStage.epilogue);
  }

  Future<void> _leave() async {
    _sounds.stopAll();
    await _voice.stop();
    if (mounted) widget.onLeave();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(voiceControllerProvider(widget.number)).requireValue;
    final muted = ref.watch(interviewerMutedProvider);
    final mission = game.mission;
    final grade = mission.grade;

    if (_stage == VoiceStage.epilogue) {
      return EpilogueScene(
        lines: [
          for (final line in mission.epilogue)
            line.addressedTo(game.playerName),
        ],
        grade: grade,
        sounds: _sounds,
        doneLabel: DebriefView.reportLabel,
        onDone: widget.onExit,
      );
    }
    if (game.score case final score?) {
      return VoiceDebrief(
        mission: mission,
        score: score,
        source: game.source!,
        made: game.made,
        verdict: game.verdict,
        onContinue: _afterDebrief,
      );
    }
    if (game.selfCheck case final reason?) {
      return _Backdrop(
        grade: grade,
        child: SelfCheckPanel(
          reason: reason,
          voice: game.voice,
          answer: game.answer,
          reply: game.reply,
          grade: grade,
          onListen: (take) =>
              unawaited(ref.read(takePlaybackProvider).play(take.wav)),
          onScore: (ticked) {
            unawaited(ref.read(takePlaybackProvider).stop());
            unawaited(_controller.selfChecked(ticked));
          },
        ),
      );
    }
    if (game.scoring) {
      return _Backdrop(
        grade: grade,
        child: ListeningCard(grade: grade),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final regionTop =
        MissionSet.faceBottom(size, _shotsFor(_stage)) + BrandSpace.sm;
    final insets = MediaQuery.paddingOf(context);
    final lead = mission.lead;
    final recorder = _recorder;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_leaving) setState(() => _leaving = true);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: BrandVivid.night),
          FilmOverlay(
            grain: 0,
            vignetteColor: grade.shadow,
            child: HardCut(
              shot: _tight,
              onCut: () => _sounds.followUpChallenge(game.followUp.speakerId),
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
          SceneScrim(from: regionTop / size.height, grade: grade),
          Semantics(
            button: true,
            label: VoicePlayer.continueLabel,
            onTap: _tap,
            excludeSemantics: true,
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
          Positioned(
            top: regionTop,
            left: insets.left + BrandSpace.md,
            right: insets.right + BrandSpace.md,
            bottom: insets.bottom + BrandSpace.sm,
            child: LowerThird(children: _lowerThird(game, grade, recorder)),
          ),
          if (_stage == VoiceStage.card)
            Semantics(
              button: true,
              label: VoicePlayer.continueLabel,
              onTap: _cardDone,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: _cardDone,
                child: MissionCard(mission: mission, onFinished: _cardDone),
              ),
            ),
          if (_stage != VoiceStage.card && !_leaving) ...[
            Positioned(
              top: insets.top + BrandSpace.xs,
              left: insets.left + BrandSpace.sm,
              child: MuteControl(muted: muted, onPressed: _toggleMute),
            ),
            Positioned(
              top: insets.top + BrandSpace.xs,
              right: insets.right + BrandSpace.sm,
              child: LeaveControl(
                onPressed: () => setState(() => _leaving = true),
              ),
            ),
          ],
          if (recorder != null)
            ListenableBuilder(
              listenable: recorder,
              builder: (context, _) => recorder.confirmingDelete
                  ? DeleteTakeSheet(recorder: recorder, grade: grade)
                  : const SizedBox.shrink(),
            ),
          if (_leaving)
            VoiceSheet(
              title: VoicePlayer.leaveTitle,
              line: VoicePlayer.leaveLine,
              primary: VoicePlayer.stay,
              onPrimary: () => setState(() => _leaving = false),
              secondary: VoicePlayer.leave,
              onSecondary: () => unawaited(_leave()),
              grade: grade,
            ),
        ],
      ),
    );
  }

  List<Widget> _lowerThird(
    VoiceState game,
    ChapterGrade grade,
    TakeRecorder? recorder,
  ) {
    Widget subtitle(SceneLine line, {required VoidCallback onComplete}) =>
        IgnorePointer(
          child: TypewriterSubtitle(
            key: ValueKey('line-$_lineToken'),
            speaker: interviewerById(line.speakerId).name,
            line: line.text,
            grade: grade,
            controller: _typer,
            // The interviewer's own voice says the line; the typing blips only stand in for
            // it when the voice is off.
            onCharacter: (c, _) {
              if (_muted) _sounds.subtitleCharacter(line.speakerId, c);
            },
            onComplete: onComplete,
          ),
        );
    Widget answering({
      required ValueChanged<Take?> onDone,
      required String question,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionReminder(text: question, grade: grade),
        if (recorder != null)
          RecorderPanel(
            recorder: recorder,
            grade: grade,
            onDone: onDone,
            onWithoutMicrophone: _withoutMicrophone,
          )
        else
          SpokenAloudPanel(grade: grade, onDone: () => onDone(null)),
      ],
    );

    return switch (_stage) {
      VoiceStage.card || VoiceStage.opening || VoiceStage.epilogue => const [],
      VoiceStage.lines ||
      VoiceStage.push => [subtitle(_lines[_line], onComplete: _lineTyped)],
      // Once a take is in, nothing until the cut: never a flash of the next panel.
      VoiceStage.answer when game.answered => const [],
      VoiceStage.answer => [
        answering(onDone: _answered, question: game.question.text),
      ],
      VoiceStage.followUp => [subtitle(game.followUp, onComplete: _lineTyped)],
      VoiceStage.reply when game.replied => const [],
      VoiceStage.reply => [
        answering(onDone: _replied, question: game.followUp.text),
      ],
    };
  }

  /// Her face: talking, then listening while you answer, sceptical on the push-back.
  InterviewerExpression get _expression => switch (_stage) {
    VoiceStage.answer || VoiceStage.reply => InterviewerExpression.neutral,
    VoiceStage.followUp => InterviewerExpression.hmm,
    _ => InterviewerExpression.smile,
  };

  static List<SceneShot> _shotsFor(VoiceStage stage) => switch (stage) {
    VoiceStage.card ||
    VoiceStage.opening ||
    VoiceStage.lines ||
    VoiceStage.push => const [SceneShot.wide, SceneShot.close],
    VoiceStage.answer => const [SceneShot.close],
    VoiceStage.followUp ||
    VoiceStage.reply ||
    VoiceStage.epilogue => const [SceneShot.tight],
  };
}

/// The evening sky with one card centred on it: listening, and the self-check.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.grade, required this.child});

  final ChapterGrade grade;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      VividBackdrop(grade: grade),
      SafeArea(
        child: AnchoredScroll(
          alignment: MainAxisAlignment.center,
          padding: const EdgeInsets.all(BrandSpace.lg),
          children: [child],
        ),
      ),
    ],
  );
}
