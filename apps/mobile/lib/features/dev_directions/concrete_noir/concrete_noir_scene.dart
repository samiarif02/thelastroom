import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/answer_cards.dart';
import '../shared/camera_rig.dart';
import '../shared/dust.dart';
import '../shared/letterbox.dart';
import '../shared/priya_silhouette.dart';
import '../shared/scene_director.dart';
import '../shared/typewriter_text.dart';

/// B · scene. A concrete wall, her name in letters two storeys tall behind her, hard light cut
/// into bars by a blind. The camera doesn't drift: it snaps to her face, through one black
/// frame, like an edit.
class ConcreteNoirScene extends StatelessWidget {
  const ConcreteNoirScene({super.key});

  static const CinematicDirection _d = concreteNoir;

  static const CameraShot _wide = CameraShot();
  static const CameraShot _close = CameraShot(
    scale: 1.6,
    focus: Alignment(-0.1, 0.12),
    target: Alignment(0.05, -0.3),
  );

  /// The black frame of the edit sits at the middle of the cut.
  static const double _blackFrom = 0.42;
  static const double _blackTo = 0.58;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final grade = _d.lobby;
    final still = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: p.surface,
      child: SceneDirector(
        motion: _d.motion,
        line: MissionOne.line,
        builder: (context, s) {
          final black = !still && s.cut > _blackFrom && s.cut < _blackTo;
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraRig(
                t: s.cut,
                wide: _wide,
                close: _close,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Her name, as architecture.
                    Align(
                      alignment: const Alignment(-1.4, -0.2),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: ExcludeSemantics(
                          child: Text(
                            MissionOne.interviewer.toUpperCase(),
                            maxLines: 1,
                            style: _d.type.titleCard.copyWith(
                              fontSize: 260,
                              color: p.raised,
                            ),
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: _InterrogationPainter(
                        light: grade.key,
                        figure: p.void_,
                        wall: p.raised,
                      ),
                    ),
                    Dust(
                      color: grade.key,
                      beam: const Rect.fromLTWH(0.2, 0.05, 0.7, 0.6),
                      count: 30,
                      seed: 3,
                    ),
                  ],
                ),
              ),
              if (black) ColoredBox(color: p.void_),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.void_.withValues(alpha: 0.75),
                      p.void_.withValues(alpha: 0),
                      p.void_.withValues(alpha: 0),
                      p.void_.withValues(alpha: 0.95),
                    ],
                    stops: const [0, 0.16, 0.5, 0.82],
                  ),
                ),
              ),
              Letterbox(t: s.bars, color: p.void_),
              _Overlay(scene: s),
            ],
          );
        },
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.scene});

  final SceneState scene;

  static const CinematicDirection _d = concreteNoir;

  @override
  Widget build(BuildContext context) {
    final type = _d.type;
    final p = _d.palette;
    final grade = _d.lobby;
    final barHeight = MediaQuery.sizeOf(context).height * 0.13 * scene.bars;
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: BrandSpace.md),
      child: Padding(
        padding: EdgeInsets.only(top: barHeight, bottom: barHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BrandSpace.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'INT. NORTHSTAR LABS — LOBBY — NIGHT',
                    style: type.label,
                  ),
                ),
                Text('M.${MissionOne.missionIndex}', style: type.label),
              ],
            ),
            Expanded(
              child: AnchoredScroll(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(MissionOne.interviewer, style: type.speaker),
                      const SizedBox(width: BrandSpace.sm),
                      Flexible(
                        child: Text(
                          '/ ${MissionOne.interviewerRole.toUpperCase()}',
                          style: type.label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  TypewriterText(
                    text: MissionOne.line,
                    characters: scene.characters,
                    style: type.subtitle,
                  ),
                  if (scene.choices > 0) ...[
                    const SizedBox(height: BrandSpace.lg),
                    AnswerCards(
                      t: scene.choices,
                      answers: MissionOne.answers,
                      gap: 2,
                      arrive: (t, card) => ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: t,
                          child: card,
                        ),
                      ),
                      cardBuilder: (i, answer, picked) => _Slab(
                        letter: String.fromCharCode('A'.codeUnitAt(0) + i),
                        answer: answer,
                        picked: picked,
                        palette: p,
                        type: type,
                        accent: grade.key,
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
}

/// A hard-edged slab: a big condensed letter, a rule, the line.
class _Slab extends StatelessWidget {
  const _Slab({
    required this.letter,
    required this.answer,
    required this.picked,
    required this.palette,
    required this.type,
    required this.accent,
  });

  final String letter;
  final String answer;
  final bool picked;
  final DirectionPalette palette;
  final DirectionType type;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BrandMotion.quick,
      constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
      decoration: BoxDecoration(
        color: picked ? palette.raised : palette.void_.withValues(alpha: 0.88),
        border: Border(
          left: BorderSide(color: picked ? accent : palette.line, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.md,
        BrandSpace.sm,
        BrandSpace.md,
        BrandSpace.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              letter,
              style: type.display.copyWith(
                fontSize: 30,
                color: picked ? accent : palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(answer, style: type.choice),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blind-light on concrete: diagonal bars of hard light over the wall and over Priya, a hard
/// top light, and her as a black cut-out.
class _InterrogationPainter extends CustomPainter {
  _InterrogationPainter({
    required this.light,
    required this.figure,
    required this.wall,
  });

  final Color light;
  final Color figure;
  final Color wall;

  static const int _slats = 9;
  static const double _tilt = -0.32;

  @override
  void paint(Canvas canvas, Size size) {
    final figW = size.width * 0.62;
    final figH = figW / PriyaSilhouette.aspect;
    final floor = size.height * 0.78;
    final box = Rect.fromLTWH(
      size.width * 0.44 - figW / 2,
      floor - figH,
      figW,
      figH,
    );

    final slats = _slatPath(size);
    // The blind's light on the wall.
    canvas.drawPath(
      slats,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.4, -0.5),
          radius: 1.1,
          colors: [light.withValues(alpha: 0.42), light.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    final body = PriyaSilhouette.figure(box);
    canvas.drawPath(body, Paint()..color = figure);
    // The same bars falling across her, dimmer: she's nearer the window than the wall is.
    canvas
      ..save()
      ..clipPath(body)
      ..drawPath(slats, Paint()..color = light.withValues(alpha: 0.18))
      ..restore()
      ..drawPath(
        PriyaSilhouette.rim(box, side: -1, width: 1.2),
        Paint()..color = light.withValues(alpha: 0.9),
      )
      ..drawPath(
        PriyaSilhouette.hairSweep(box),
        Paint()
          ..color = light.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      )
      ..drawOval(PriyaSilhouette.earring(box), Paint()..color = light);

    // The floor line.
    canvas.drawRect(
      Rect.fromLTRB(0, floor, size.width, size.height),
      Paint()..color = wall.withValues(alpha: 0.6),
    );
  }

  Path _slatPath(Size size) {
    final path = Path();
    final pitch = size.height / _slats;
    for (var i = 0; i < _slats + 4; i++) {
      final y = i * pitch - size.height * 0.2;
      path.addRect(Rect.fromLTWH(-size.width, y, size.width * 3, pitch * 0.46));
    }
    final m = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..rotateZ(_tilt * math.pi / 4)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
    return path.transform(m.storage);
  }

  @override
  bool shouldRepaint(_InterrogationPainter oldDelegate) =>
      oldDelegate.light != light;
}
