import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/answer_cards.dart';
import '../shared/camera_rig.dart';
import '../shared/cue.dart';
import '../shared/dust.dart';
import '../shared/letterbox.dart';
import '../shared/priya_silhouette.dart';
import '../shared/scene_director.dart';
import '../shared/typewriter_text.dart';
import 'bokeh.dart';

/// C · scene. A corner office after hours: walnut panels, a brass desk lamp, the city a field of
/// warm bokeh behind the glass. The camera dollies in slowly, and the background moves less
/// than she does, so the room has depth.
class BoardroomScene extends StatelessWidget {
  const BoardroomScene({super.key});

  static const CinematicDirection _d = boardroom;

  static const CameraShot _wide = CameraShot();
  static const CameraShot _close = CameraShot(
    scale: 1.75,
    focus: Alignment(0, -0.02),
    target: Alignment(0, -0.36),
  );

  // The background travels less than the foreground: parallax.
  static const CameraShot _closeBackground = CameraShot(
    scale: 1.18,
    focus: Alignment(0, -0.2),
    target: Alignment(0, -0.32),
  );

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.surface,
      child: SceneDirector(
        motion: _d.motion,
        line: MissionOne.line,
        builder: (context, s) => Stack(
          fit: StackFit.expand,
          children: [
            CameraRig(
              t: s.cut,
              wide: _wide,
              close: _closeBackground,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _WindowPainter(
                      night: p.void_,
                      panel: p.raised,
                      mullion: p.line,
                    ),
                  ),
                  Bokeh(colors: [grade.key, p.textPrimary, grade.tint]),
                ],
              ),
            ),
            CameraRig(
              t: s.cut,
              wide: _wide,
              close: _close,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _OfficePainter(
                      lamp: grade.key,
                      warm: grade.tint,
                      figure: p.void_,
                      desk: p.raised,
                      brass: grade.key,
                    ),
                  ),
                  Dust(
                    color: grade.key,
                    beam: const Rect.fromLTWH(0, 0.35, 0.45, 0.4),
                    count: 26,
                    seed: 13,
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    p.void_.withValues(alpha: 0.6),
                    p.void_.withValues(alpha: 0),
                    p.void_.withValues(alpha: 0),
                    p.void_.withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.18, 0.5, 0.84],
                ),
              ),
            ),
            Letterbox(t: s.bars, color: p.void_),
            _Overlay(scene: s),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.scene});

  final SceneState scene;

  static const CinematicDirection _d = boardroom;

  @override
  Widget build(BuildContext context) {
    final type = _d.type;
    final p = _d.palette;
    final grade = _d.lobby;
    final barHeight = MediaQuery.sizeOf(context).height * 0.13 * scene.bars;
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: BrandSpace.lg),
      child: Padding(
        padding: EdgeInsets.only(top: barHeight, bottom: barHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BrandSpace.md),
            Text(
              '${MissionOne.company}  ·  ${MissionOne.location.toUpperCase()}',
              textAlign: TextAlign.center,
              style: type.label,
            ),
            Expanded(
              child: AnchoredScroll(
                children: [
                  Text(
                    MissionOne.interviewer,
                    textAlign: TextAlign.center,
                    style: type.speaker,
                  ),
                  const SizedBox(height: BrandSpace.xs),
                  TypewriterText(
                    text: MissionOne.line,
                    characters: scene.characters,
                    style: type.subtitle,
                    textAlign: TextAlign.center,
                  ),
                  if (scene.choices > 0) ...[
                    const SizedBox(height: BrandSpace.lg),
                    AnswerCards(
                      t: scene.choices,
                      answers: MissionOne.answers,
                      gap: BrandSpace.sm,
                      arrive: (t, card) => Opacity(
                        opacity: t,
                        child: Transform.scale(
                          scale: mix(0.97, 1, t),
                          child: card,
                        ),
                      ),
                      cardBuilder: (i, answer, picked) => _Plaque(
                        numeral: const ['i.', 'ii.', 'iii.'][i],
                        answer: answer,
                        picked: picked,
                        palette: p,
                        type: type,
                        brass: grade.key,
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

/// An engraved plaque: walnut, an inset brass hairline, an italic numeral.
class _Plaque extends StatelessWidget {
  const _Plaque({
    required this.numeral,
    required this.answer,
    required this.picked,
    required this.palette,
    required this.type,
    required this.brass,
  });

  final String numeral;
  final String answer;
  final bool picked;
  final DirectionPalette palette;
  final DirectionType type;
  final Color brass;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BrandMotion.standard,
      curve: BrandMotion.enter,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.raised.withValues(alpha: 0.92),
        border: Border.all(color: brass.withValues(alpha: picked ? 0.9 : 0.35)),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: BrandSpace.minTarget - 6),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: brass.withValues(alpha: picked ? 0.5 : 0.14),
            width: 0.6,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                numeral,
                style: type.display.copyWith(fontSize: 19, color: brass),
              ),
            ),
            Expanded(child: Text(answer, style: type.choice)),
          ],
        ),
      ),
    );
  }
}

/// The far layer: the night beyond the glass and the walnut panels either side.
class _WindowPainter extends CustomPainter {
  _WindowPainter({
    required this.night,
    required this.panel,
    required this.mullion,
  });

  final Color night;
  final Color panel;
  final Color mullion;

  @override
  void paint(Canvas canvas, Size size) {
    final glass = Rect.fromLTRB(
      size.width * 0.12,
      0,
      size.width * 0.88,
      size.height * 0.72,
    );
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = panel)
      ..drawRect(glass, Paint()..color = night);
    // Walnut grain: fine vertical lines on the panels.
    final grain = Paint()
      ..color = mullion.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < size.width; x += 3.5) {
      if (x > glass.left && x < glass.right) continue;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grain);
    }
    final m = Paint()
      ..color = mullion
      ..strokeWidth = 2;
    canvas.drawLine(glass.topCenter, glass.bottomCenter, m);
  }

  @override
  bool shouldRepaint(_WindowPainter oldDelegate) => false;
}

/// The near layer: the lamp's pool, Priya seated and lit warm from the lamp side, the desk and
/// its brass edge.
class _OfficePainter extends CustomPainter {
  _OfficePainter({
    required this.lamp,
    required this.warm,
    required this.figure,
    required this.desk,
    required this.brass,
  });

  final Color lamp;
  final Color warm;
  final Color figure;
  final Color desk;
  final Color brass;

  @override
  void paint(Canvas canvas, Size size) {
    final deskY = size.height * 0.68;
    final lampAt = Offset(size.width * 0.14, deskY - size.height * 0.1);
    canvas.drawCircle(
      lampAt,
      size.width * 0.7,
      Paint()
        ..shader =
            RadialGradient(
              colors: [warm.withValues(alpha: 0.8), warm.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(center: lampAt, radius: size.width * 0.7),
            ),
    );

    final figW = size.width * 0.5;
    final figH = figW / PriyaSilhouette.aspect;
    final box = Rect.fromLTWH(
      size.width * 0.5 - figW / 2,
      deskY - figH + figH * 0.12,
      figW,
      figH,
    );
    canvas
      ..drawPath(PriyaSilhouette.figure(box), Paint()..color = figure)
      ..drawPath(
        PriyaSilhouette.rim(box, side: -1, width: 2.2),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lamp, lamp.withValues(alpha: 0.2)],
          ).createShader(box),
      )
      ..drawPath(
        PriyaSilhouette.lapels(box),
        Paint()
          ..color = lamp.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke,
      )
      ..drawPath(
        PriyaSilhouette.hairSweep(box),
        Paint()
          ..color = lamp.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      )
      ..drawOval(PriyaSilhouette.earring(box), Paint()..color = lamp);

    // The lamp: a brass stem and a green-glass shade's glow, reduced to light.
    final shade = Rect.fromCenter(
      center: lampAt,
      width: size.width * 0.16,
      height: size.width * 0.06,
    );
    canvas
      ..drawLine(
        Offset(lampAt.dx, lampAt.dy),
        Offset(lampAt.dx, deskY),
        Paint()
          ..color = brass.withValues(alpha: 0.7)
          ..strokeWidth = 2,
      )
      ..drawOval(
        shade,
        Paint()
          ..color = lamp
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

    canvas
      ..drawRect(
        Rect.fromLTRB(0, deskY, size.width, size.height),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [desk, figure],
          ).createShader(Rect.fromLTRB(0, deskY, size.width, size.height)),
      )
      ..drawLine(
        Offset(0, deskY),
        Offset(size.width, deskY),
        Paint()
          ..color = brass.withValues(alpha: 0.6)
          ..strokeWidth = 1.2,
      );
  }

  @override
  bool shouldRepaint(_OfficePainter oldDelegate) => oldDelegate.lamp != lamp;
}
