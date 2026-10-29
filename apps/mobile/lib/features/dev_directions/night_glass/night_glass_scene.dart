import 'dart:ui' show ImageFilter;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/answer_cards.dart';
import '../shared/camera_rig.dart';
import '../shared/city_lights.dart';
import '../shared/cue.dart';
import '../shared/dust.dart';
import '../shared/letterbox.dart';
import '../shared/priya_silhouette.dart';
import '../shared/scene_director.dart';
import '../shared/typewriter_text.dart';

/// A · scene. Priya stands backlit against a glass wall, the city sharp behind her. When the
/// question lands the camera pushes in and racks focus: the city melts, she sharpens.
class NightGlassScene extends StatelessWidget {
  const NightGlassScene({super.key});

  static const CinematicDirection _d = nightGlass;

  static const CameraShot _wide = CameraShot();
  // Close on her face, lifted into the top third so the subtitles and cards don't cover it.
  static const CameraShot _close = CameraShot(
    scale: 1.9,
    focus: Alignment(0.16, 0.1),
    target: Alignment(0.05, -0.42),
  );

  // Depth of field: the city's blur in the wide shot and in the close-up.
  static const double _wideBlur = 0.6;
  static const double _closeBlur = 9;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.surface,
      child: SceneDirector(
        motion: _d.motion,
        line: MissionOne.line,
        builder: (context, s) {
          final blur = mix(_wideBlur, _closeBlur, s.cut);
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
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: CityLights(
                        tower: p.raised,
                        window: p.textPrimary,
                        warmWindow: grade.key,
                      ),
                    ),
                    CustomPaint(
                      painter: _RoomPainter(
                        glass: p.textPrimary,
                        mullion: p.void_,
                        light: grade.key,
                        figure: p.void_,
                        desk: p.raised,
                      ),
                    ),
                    Dust(
                      color: p.textPrimary,
                      beam: const Rect.fromLTWH(0.42, 0, 0.34, 0.7),
                    ),
                  ],
                ),
              ),
              // Scrim under the subtitles and cards, so text over the image holds AA.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.void_.withValues(alpha: 0.7),
                      p.void_.withValues(alpha: 0),
                      p.void_.withValues(alpha: 0),
                      p.void_.withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.2, 0.45, 0.85],
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

  static const CinematicDirection _d = nightGlass;

  @override
  Widget build(BuildContext context) {
    final type = _d.type;
    final p = _d.palette;
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
              '${MissionOne.missionIndex}   ${MissionOne.mission.toUpperCase()}',
              style: type.label,
            ),
            Expanded(
              child: AnchoredScroll(
                children: [
                  Text(
                    '${MissionOne.interviewer.toUpperCase()}  ·  ${MissionOne.interviewerRole.toUpperCase()}',
                    style: type.speaker,
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
                      arrive: (t, card) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, mix(BrandSpace.lg, 0, t)),
                          child: card,
                        ),
                      ),
                      cardBuilder: (i, answer, picked) => _GlassCard(
                        index: i,
                        answer: answer,
                        picked: picked,
                        palette: p,
                        type: type,
                        accent: _d.lobby.key,
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

/// A pane of frosted glass with a hairline edge.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.index,
    required this.answer,
    required this.picked,
    required this.palette,
    required this.type,
    required this.accent,
  });

  final int index;
  final String answer;
  final bool picked;
  final DirectionPalette palette;
  final DirectionType type;
  final Color accent;

  static const double _frost = 14;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(BrandRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _frost, sigmaY: _frost),
        child: AnimatedContainer(
          duration: BrandMotion.standard,
          curve: BrandMotion.enter,
          constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSpace.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: palette.raised.withValues(alpha: picked ? 0.85 : 0.55),
            border: Border.all(
              color: picked
                  ? accent
                  : palette.textPrimary.withValues(alpha: 0.14),
              width: picked ? 1 : 0.6,
            ),
            borderRadius: BorderRadius.circular(BrandRadius.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '0${index + 1}',
                  style: type.label.copyWith(color: picked ? accent : null),
                ),
              ),
              Expanded(child: Text(answer, style: type.choice)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The room: glass wall mullions, a downlight onto Priya, Priya backlit with a rim of warm
/// light, and the edge of a glass desk.
class _RoomPainter extends CustomPainter {
  _RoomPainter({
    required this.glass,
    required this.mullion,
    required this.light,
    required this.figure,
    required this.desk,
  });

  final Color glass;
  final Color mullion;
  final Color light;
  final Color figure;
  final Color desk;

  static const int _panes = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    // A diagonal reflection across the glass.
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          colors: [
            glass.withValues(alpha: 0),
            glass.withValues(alpha: 0.05),
            glass.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.62],
        ).createShader(full),
    );
    final m = Paint()
      ..color = mullion
      ..strokeWidth = 3;
    for (var i = 1; i < _panes; i++) {
      final x = size.width * i / _panes;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), m);
    }

    final figW = size.width * 0.46;
    final figH = figW / PriyaSilhouette.aspect;
    final deskY = size.height * 0.72;
    final box = Rect.fromLTWH(
      size.width * 0.58 - figW / 2,
      deskY - figH,
      figW,
      figH,
    );

    // The downlight: a soft cone from the ceiling onto her.
    final cone = Path()
      ..moveTo(box.center.dx - figW * 0.08, 0)
      ..lineTo(box.center.dx + figW * 0.08, 0)
      ..lineTo(box.right + figW * 0.15, deskY)
      ..lineTo(box.left - figW * 0.15, deskY)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            light.withValues(alpha: 0.22),
            light.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, deskY)),
    );

    canvas.drawPath(PriyaSilhouette.figure(box), Paint()..color = figure);
    // Top light on the crown of her hair, then a thin warm rim on the side.
    final head = PriyaSilhouette.head(box);
    canvas
      ..save()
      ..clipPath(head)
      ..drawRect(
        head.getBounds(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light.withValues(alpha: 0.35), light.withValues(alpha: 0)],
            stops: const [0, 0.35],
          ).createShader(head.getBounds()),
      )
      ..restore()
      ..drawPath(
        PriyaSilhouette.rim(box, side: 1, width: 1.4),
        Paint()..color = light.withValues(alpha: 0.85),
      )
      ..drawPath(
        PriyaSilhouette.lapels(box),
        Paint()
          ..color = glass.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke,
      )
      ..drawPath(
        PriyaSilhouette.hairSweep(box),
        Paint()
          ..color = glass.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawOval(PriyaSilhouette.earring(box), Paint()..color = light);

    // The glass desk: a slab and its bright edge.
    canvas
      ..drawRect(
        Rect.fromLTRB(0, deskY, size.width, size.height),
        Paint()..color = desk.withValues(alpha: 0.9),
      )
      ..drawLine(
        Offset(0, deskY),
        Offset(size.width, deskY),
        Paint()
          ..color = glass.withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
      );
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) =>
      oldDelegate.light != light || oldDelegate.glass != glass;
}
