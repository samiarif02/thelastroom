import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/film_overlay.dart';
import '../../ui/subtitle/typewriter_subtitle.dart';
import '../debrief/debrief_view.dart';
import '../mission/mission_lookup.dart';
import '../mission/scene/epilogue_scene.dart';
import '../mission/scene/mission_card.dart';
import '../mission/scene/room_layout.dart';
import '../mission/widgets/leave_control.dart';
import '../tips/tip_overlay.dart';
import '../tips/tips.dart';
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

/// A voice mission (brief 35; Daylight in brief 46, direction.md §4): the interviewer's lines
/// spoken aloud as they type in the bubble over the room, the points to cover, the player's
/// answer recorded on the floor-coloured recorder, the spoken follow-up and the recorded
/// reply, then the recruiter listening (the interviewer thinking, never a spinner) or the
/// self-check, then the debrief. Whoever speaks is the one in the room. The takes, the verdict
/// and the score are [VoiceController]'s; this widget runs the room, the bubble, the voice and
/// the recorders.
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
  static const String pointsTitle = 'Points to cover';
  static const String pointsAside = 'your own story, or the practice CV';
  static const String replyPointsTitle = 'Points for your reply';
  static const String private =
      'Nothing is scored while you talk. The audio stays on this phone.';
  static const String recording = 'Recording';
  static const String listening = 'Listening';

  /// A spoken, typed line holds this long before the next one starts.
  static const Duration lineRest = Duration(milliseconds: 700);

  @override
  ConsumerState<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends ConsumerState<VoicePlayer> {
  static const Duration _beforeLines = Duration(milliseconds: 350);
  static const Duration _beforeFollowUp = Duration(milliseconds: 700);
  static const Duration _questionRest = Duration(milliseconds: 700);

  final TypewriterController _typer = TypewriterController();
  VoiceStage _stage = VoiceStage.card;
  int _line = 0;
  bool _typed = false;
  bool _spoken = false;
  bool _leaving = false;

  /// The microphone was refused or skipped: the reply is said aloud too, with no recorder.
  bool _noMicrophone = false;

  /// Bumped for every new line, so a slow `say` for an old line can't move a new one on.
  int _lineToken = 0;
  TakeRecorder? _recorder;

  /// Kept from the start: `dispose` hands back a tip still up, when `ref` can't be read.
  late final TipsController _tips = ref.read(tipsProvider.notifier);

  /// The first voice room's tip over the record tile, and where the tile is.
  Rect? _micAt;
  final GlobalKey _scene = GlobalKey();
  final GlobalKey _mic = GlobalKey();

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
    // Resolved now, not lazily: `dispose` stops both, and `ref` can't be read by then. A
    // mission left before a line was spoken used to throw on the way out.
    _voice;
    _sounds;
    _tips;
    final mission = _game.mission;
    if (mission.opensChapter) _sounds.chapterCard(mission.chapter);
  }

  @override
  void dispose() {
    if (_micAt != null) _tips.release(Tip.voiceMic);
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
        unawaited(_after(_questionRest, _pushDone));
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
    unawaited(_after(_beforeLines, _startLines));
  }

  void _startLines() {
    if (_stage != VoiceStage.opening) return;
    _go(VoiceStage.lines);
    _controller.sceneStarted();
    _say(_lines[_line]);
  }

  void _pushDone() {
    if (_stage != VoiceStage.push) return;
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
    recorder.addListener(_recorderMoved);
    unawaited(_voice.stop());
    unawaited(recorder.start());
  }

  /// The recorder is ready to record: the first time, a tip on the record tile. Anything else
  /// it does (recording, a sheet, the explainer) takes the tip away unseen, or never shows it.
  void _recorderMoved() {
    final ready = _recorder?.phase == RecorderPhase.empty;
    if (!ready) {
      if (_micAt != null) {
        _tips.release(Tip.voiceMic);
        setState(() => _micAt = null);
      }
      return;
    }
    if (_micAt != null || !_tips.canShow(Tip.voiceMic)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scene = _scene.currentContext;
      if (!mounted ||
          scene == null ||
          _micAt != null ||
          _leaving ||
          _recorder?.phase != RecorderPhase.empty) {
        return;
      }
      final at = tipTarget(_mic, scene);
      if (at == null || !_tips.shown(Tip.voiceMic)) return;
      setState(() => _micAt = at);
    });
  }

  void _endMicTip(TipAction action) {
    if (_micAt == null) return;
    setState(() => _micAt = null);
    unawaited(_tips.done(Tip.voiceMic, action));
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
    _sounds.followUpChallenge(_game.followUp.speakerId);
    setState(() {});
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
    final f = grade.floor;

    if (_stage == VoiceStage.epilogue) {
      return FilmGrain(
        child: EpilogueScene(
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
        ),
      );
    }
    if (game.score case final score?) {
      // The Candidate assessment, exactly as it was (the owner's rule), on Daylight's ground.
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
        child: ListeningCard(
          grade: grade,
          person: CastPeople.byId(mission.lead.id),
        ),
      );
    }

    final insets = MediaQuery.paddingOf(context);
    final recorder = _recorder;
    final compact =
        MediaQuery.textScalerOf(context).scale(DaylightSpace.s16) >
        DaylightSpace.s16 * _compactAt;
    final answering =
        (_stage == VoiceStage.answer && !game.answered) ||
        (_stage == VoiceStage.reply && !game.replied);
    final dock = answering
        ? (recorder != null
              ? RecorderPanel(
                  recorder: recorder,
                  grade: grade,
                  onDone: _stage == VoiceStage.answer ? _answered : _replied,
                  onWithoutMicrophone: _withoutMicrophone,
                  recordKey: _mic,
                )
              : SpokenAloudPanel(
                  grade: grade,
                  onDone: () => _stage == VoiceStage.answer
                      ? _answered(null)
                      : _replied(null),
                ))
        : null;
    return PopScope<Object?>(
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
            Positioned.fill(
              child: Semantics(
                button: true,
                label: VoicePlayer.continueLabel,
                onTap: _tap,
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
                  DaylightTopBar(
                    leadingLabel: LeaveControl.label,
                    onLeading: _stage == VoiceStage.card || _leaving
                        ? null
                        : () => setState(() => _leaving = true),
                    kicker: MissionCard.kicker(mission),
                    title: mission.title,
                    trailing: MuteControl(muted: muted, onPressed: _toggleMute),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      hitTestBehavior: HitTestBehavior.deferToChild,
                      padding: EdgeInsets.fromLTRB(
                        DaylightSpace.s16,
                        DaylightSpace.s12,
                        DaylightSpace.s16,
                        dock == null
                            ? insets.bottom + DaylightSpace.s24
                            : DaylightSpace.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _room(game, recorder, compact: compact),
                      ),
                    ),
                  ),
                  if (dock != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        DaylightSpace.s16,
                        DaylightSpace.s8,
                        DaylightSpace.s16,
                        insets.bottom + DaylightSpace.s16,
                      ),
                      child: dock,
                    ),
                ],
              ),
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
            if (_micAt case final at? when !_leaving && recorder != null)
              TipOverlay(
                voice: TipVoice.inRoom(CastPeople.byId(_speaker(game).id), f),
                line: Tip.voiceMic.line,
                target: at,
                onTarget: () => _endMicTip(TipAction.followed),
                onDismiss: () => _endMicTip(TipAction.dismissed),
              ),
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
      ),
    );
  }

  static const double _compactAt = 1.3;

  /// Who's speaking: the one in the room (a panel's second interviewer takes the lead's place
  /// while they push back, never over their face).
  Interviewer _speaker(VoiceState game) => switch (_stage) {
    VoiceStage.lines ||
    VoiceStage.push => interviewerById(_lines[_line].speakerId),
    VoiceStage.followUp ||
    VoiceStage.reply => interviewerById(game.followUp.speakerId),
    _ => game.mission.lead,
  };

  List<Widget> _room(
    VoiceState game,
    TakeRecorder? recorder, {
    required bool compact,
  }) {
    final who = _speaker(game);
    final f = game.mission.grade.floor;
    final recordingNow =
        recorder != null && recorder.phase == RecorderPhase.recording;
    Widget bubble(SceneLine line, {bool typed = false}) => IgnorePointer(
      child: TypewriterSubtitle(
        key: ValueKey(typed ? 'said-${line.text}' : 'line-$_lineToken'),
        daylight: true,
        floor: f,
        speaker: '${who.name} · ${who.role.toLowerCase()}',
        line: line.text,
        play: !typed,
        controller: typed ? null : _typer,
        // The interviewer's own voice says the line; the typing blips only stand in for it
        // when the voice is off.
        onCharacter: typed
            ? null
            : (c, _) {
                if (_muted) _sounds.subtitleCharacter(line.speakerId, c);
              },
        onComplete: typed ? null : _lineTyped,
      ),
    );
    Widget room(Widget b, {bool live = false}) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _tap,
      child: recorder == null
          ? _roomStage(who, b, compact: compact, live: live)
          : ListenableBuilder(
              listenable: recorder,
              builder: (context, _) => _roomStage(
                who,
                b,
                compact: compact,
                live: recorder.phase == RecorderPhase.recording,
              ),
            ),
    );
    return switch (_stage) {
      VoiceStage.card ||
      VoiceStage.opening => [room(bubble(_lines.first, typed: true))],
      VoiceStage.epilogue => const [],
      VoiceStage.lines || VoiceStage.push => [room(bubble(_lines[_line]))],
      VoiceStage.answer => [
        room(bubble(game.question, typed: true), live: recordingNow),
        if (!game.answered) ...[
          const SizedBox(height: DaylightSpace.s16),
          _Points(
            title: VoicePlayer.pointsTitle,
            aside: VoicePlayer.pointsAside,
            points: [for (final p in game.voice.listenFor) p.text],
          ),
        ],
      ],
      VoiceStage.followUp => [room(bubble(game.followUp))],
      VoiceStage.reply => [
        room(bubble(game.followUp, typed: true), live: recordingNow),
        if (!game.replied) ...[
          const SizedBox(height: DaylightSpace.s16),
          _Points(
            title: VoicePlayer.replyPointsTitle,
            points: [for (final p in game.voice.followUpListenFor) p.text],
          ),
        ],
      ],
    };
  }

  Widget _roomStage(
    Interviewer who,
    Widget bubble, {
    required bool compact,
    required bool live,
  }) {
    final f = _game.mission.grade.floor;
    final answering = _stage == VoiceStage.answer || _stage == VoiceStage.reply;
    return RoomWithBubble(
      person: CastPeople.byId(who.id),
      expression: _expression,
      bubble: bubble,
      semanticLabel: '${who.name}, the ${who.role.toLowerCase()}',
      compact: compact,
      overlays: [
        if (live)
          const Positioned(
            left: DaylightSpace.s16,
            top: DaylightSpace.s16,
            child: Tag(
              label: VoicePlayer.recording,
              tone: TagTone.raised,
              dot: DaylightColors.trap,
            ),
          ),
        if (answering)
          Positioned(
            right: DaylightSpace.s16,
            top: DaylightSpace.s16,
            child: Tag(
              label: VoicePlayer.listening,
              icon: PhosphorBold.ear,
              tone: TagTone(
                DaylightColors.raised.withValues(alpha: 0.7),
                f.deep,
              ),
            ),
          ),
      ],
    );
  }

  /// Her face: talking while a line types, listening while you answer, sceptical on the
  /// push-back.
  CastExpression get _expression => switch (_stage) {
    VoiceStage.answer || VoiceStage.reply => CastExpression.listening,
    VoiceStage.followUp => _typed ? CastExpression.hmm : CastExpression.talk,
    VoiceStage.lines => _typed ? CastExpression.neutral : CastExpression.talk,
    _ => CastExpression.smile,
  };
}

/// "Points to cover" (mockup `04`): white, r24, its edge; the points a strong answer makes as
/// numbered rows (nothing ticked live: nothing is scored while you talk), then the privacy line.
class _Points extends StatelessWidget {
  const _Points({required this.title, required this.points, this.aside});

  final String title;
  final String? aside;
  final List<String> points;

  static const double _n = 24;
  static const double _lock = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: DaylightSpace.s12,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: DaylightType.body1),
              ),
              if (aside case final a?)
                Text(
                  a,
                  style: DaylightType.caption4.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s12),
          for (final (i, p) in points.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: DaylightSpace.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _n,
                    height: _n,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: f.tint,
                      borderRadius: BorderRadius.circular(DaylightRadius.tag),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: DaylightType.tabular(DaylightType.caption3)
                          .copyWith(color: f.deep),
                    ),
                  ),
                  const SizedBox(width: DaylightSpace.s12),
                  Expanded(child: Text(p, style: DaylightType.body6)),
                ],
              ),
            ),
          const SizedBox(height: DaylightSpace.s4),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: DaylightColors.sand),
          ),
          const SizedBox(height: DaylightSpace.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                PhosphorBold.lockSimple,
                size: _lock,
                color: DaylightColors.ink2,
              ),
              const SizedBox(width: DaylightSpace.s8),
              Expanded(
                child: Text(
                  VoicePlayer.private,
                  style: DaylightType.caption4.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The floor's tint with one panel on it: listening, and the self-check.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.grade, required this.child});

  final ChapterGrade grade;
  final Widget child;

  @override
  Widget build(BuildContext context) => DaylightGround(
    color: grade.floor.tint,
    floor: grade.floor,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(DaylightSpace.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.maxHeight - DaylightSpace.s48,
            ),
            child: Center(child: Entrance(child: child)),
          ),
        ),
      ),
    ),
  );
}
