import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../mission_one.dart';

/// The beats of the scene, in order.
enum _Beat { opening, line, push, choices, followUp }

/// C · scene, composed from the film kit: a reference for brief 10's mission player.
///
/// Bars slide in on the wide shot → Priya's line types → the camera dollies in → the bars
/// retract and the plaques arrive. Tap a plaque to select it, tap it again to lock it in; then
/// her follow-up lands on a hard cut to a tighter shot. A tap on the scene completes the line or
/// skips to the next beat.
class BoardroomScene extends StatefulWidget {
  const BoardroomScene({super.key});

  /// The follow-up, after an answer is locked in.
  static const String followUp = 'And what did you do, exactly?';

  @override
  State<BoardroomScene> createState() => _BoardroomSceneState();
}

class _BoardroomSceneState extends State<BoardroomScene> {
  // Rests between beats, so each one lands before the next starts.
  static const Duration _beforeLine = Duration(milliseconds: 350);
  static const Duration _questionLands = Duration(milliseconds: 650);
  static const Duration _beforeFollowUp = Duration(milliseconds: 700);

  final TypewriterController _line = TypewriterController();
  _Beat _beat = _Beat.opening;
  bool _bars = false;
  int? _picked;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _bars = true);
    });
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  void _go(_Beat beat) {
    if (!mounted || beat.index <= _beat.index) return;
    setState(() {
      _beat = beat;
      if (beat == _Beat.choices) _bars = false;
    });
  }

  Future<void> _after(Duration rest, _Beat beat) async {
    final still = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(still ? Duration.zero : rest);
    _go(beat);
  }

  void _advance() {
    switch (_beat) {
      case _Beat.opening:
        _go(_Beat.line);
      case _Beat.line when !_line.isComplete:
        _line.complete();
      case _Beat.line:
      case _Beat.push:
        _go(_Beat.choices);
      case _Beat.choices:
      case _Beat.followUp:
        break;
    }
  }

  void _pick(int i) {
    if (_locked) return;
    setState(() {
      if (_picked == i) {
        _locked = true;
      } else {
        _picked = i;
      }
    });
    if (_locked) unawaited(_after(_beforeFollowUp, _Beat.followUp));
  }

  AnswerCardState _stateOf(int i) {
    if (_locked) {
      return i == _picked ? AnswerCardState.locked : AnswerCardState.disabled;
    }
    return i == _picked ? AnswerCardState.selected : AnswerCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final followUp = _beat == _Beat.followUp;
    return Semantics(
      button: true,
      label: 'Continue the scene',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FilmOverlay(
              grain: 0,
              vignetteColor: ChapterGrade.lobby.shadow,
              child: HardCut(
                shot: followUp,
                child: DollyCamera(
                  closeUp: _beat.index >= _Beat.push.index,
                  onPushEnd: () => _go(_Beat.choices),
                  layers: BoardroomSet.layers(
                    figure: SilhouetteFigure.priya,
                    figureLabel:
                        '${MissionOne.interviewer}, the ${MissionOne.interviewerRole.toLowerCase()}',
                    tight: followUp,
                  ),
                ),
              ),
            ),
            // A scrim, so subtitles over the room keep AA contrast.
            const _Scrim(),
            AnimatedLetterbox(
              shown: _bars,
              onSettled: () {
                if (_bars && _beat == _Beat.opening) {
                  unawaited(_after(_beforeLine, _Beat.line));
                }
              },
            ),
            _Overlay(
              beat: _beat,
              bars: _bars,
              line: _line,
              onLineDone: () => unawaited(_after(_questionLands, _Beat.push)),
              cardState: _stateOf,
              onPick: _pick,
            ),
          ],
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BrandColors.void_.withValues(alpha: 0.6),
            BrandColors.void_.withValues(alpha: 0),
            BrandColors.void_.withValues(alpha: 0),
            BrandColors.void_.withValues(alpha: 0.94),
          ],
          stops: const [0, 0.18, 0.5, 0.84],
        ),
      ),
    ),
  );
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.beat,
    required this.bars,
    required this.line,
    required this.onLineDone,
    required this.cardState,
    required this.onPick,
  });

  final _Beat beat;
  final bool bars;
  final TypewriterController line;
  final VoidCallback onLineDone;
  final AnswerCardState Function(int) cardState;
  final ValueChanged<int> onPick;

  static const double _stagger = 0.18;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final followUp = beat == _Beat.followUp;
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: BrandSpace.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: bars ? 1 : 0),
        duration: BrandMotion.letterbox,
        curve: BrandMotion.letterboxCurve,
        builder: (context, t, child) {
          final bar = Letterbox.barHeight(height, t);
          return Padding(
            padding: EdgeInsets.only(top: bar, bottom: bar),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BrandSpace.md),
            Text(
              '${MissionOne.company}  ·  ${MissionOne.location.toUpperCase()}',
              textAlign: TextAlign.center,
              style: BrandType.label,
            ),
            Expanded(
              child: AnchoredScroll(
                children: [
                  if (beat.index >= _Beat.line.index)
                    TypewriterSubtitle(
                      key: ValueKey(followUp),
                      speaker: MissionOne.interviewer,
                      line: followUp
                          ? BoardroomScene.followUp
                          : MissionOne.line,
                      controller: followUp ? null : line,
                      onComplete: followUp ? null : onLineDone,
                    ),
                  if (beat.index >= _Beat.choices.index && !followUp) ...[
                    const SizedBox(height: BrandSpace.lg),
                    Timeline(
                      duration: BrandMotion.cinematic,
                      builder: (context, t, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < MissionOne.answers.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : BrandSpace.sm,
                              ),
                              child: _arrive(
                                cue(
                                  t,
                                  _stagger * i,
                                  1 - _stagger * (2 - i),
                                  BrandMotion.enter,
                                ),
                                AnswerCard(
                                  numeral: AnswerCard.numeralFor(i),
                                  text: MissionOne.answers[i],
                                  state: cardState(i),
                                  onTap: () => onPick(i),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: BrandSpace.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _arriveFrom = 0.97;

  Widget _arrive(double t, Widget card) => Opacity(
    opacity: t,
    child: Transform.scale(scale: mix(_arriveFrom, 1, t), child: card),
  );
}
