import 'dart:ui' show ImageFilter;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/cue.dart';
import '../shared/timeline.dart';

/// A · title card. Almost nothing on screen: one tower far off, the lobby lit, one window lit
/// at the very top (the last room), and the title pulling into focus as it tracks in.
class NightGlassTitle extends StatelessWidget {
  const NightGlassTitle({super.key});

  static const CinematicDirection _d = nightGlass;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.void_,
      child: Timeline(
        duration: _d.motion.titleCard,
        builder: (context, t, _) {
          final tower = cue(t, 0, 0.4, BrandMotion.enter);
          final eyebrow = cue(t, 0.15, 0.45, BrandMotion.enter);
          final title = cue(t, 0.22, 0.9, _d.motion.cutCurve);
          final rule = cue(t, 0.5, 0.85, BrandMotion.camera);
          final footer = cue(t, 0.7, 1, BrandMotion.enter);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: tower,
                child: CustomPaint(
                  painter: _DistantTower(
                    body: p.raised,
                    edge: p.line,
                    lit: grade.key,
                    haze: grade.tint,
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(BrandSpace.lg),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: _maxTitleScale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnchoredScroll(
                          children: [
                            Opacity(
                              opacity: eyebrow,
                              child: Text(
                                '${MissionOne.chapterNumber}  ·  ${MissionOne.missionIndex}',
                                style: type.eyebrow,
                              ),
                            ),
                            const SizedBox(height: BrandSpace.md),
                            Semantics(
                              header: true,
                              label:
                                  '${MissionOne.chapterNumber}: ${MissionOne.chapterTitle}',
                              child: ExcludeSemantics(
                                child: Opacity(
                                  opacity: title,
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: mix(_focusBlur, 0, title),
                                      sigmaY: mix(_focusBlur, 0, title),
                                    ),
                                    child: Text(
                                      'Get through\nthe door.',
                                      style: type.titleCard.copyWith(
                                        letterSpacing: mix(
                                          _trackFrom,
                                          type.titleCard.letterSpacing!,
                                          title,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: BrandSpace.lg),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.42 * rule,
                                child: SizedBox(
                                  height: 1,
                                  child: ColoredBox(color: grade.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: BrandSpace.xxl + BrandSpace.lg),
                      Opacity(
                        opacity: footer,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                MissionOne.company,
                                style: type.label,
                              ),
                            ),
                            Text(
                              MissionOne.mission.toUpperCase(),
                              style: type.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static const double _focusBlur = 10;
  static const double _trackFrom = 10;
  static const double _maxTitleScale = 1.5;
}

/// One tower, far away, at the right edge of frame.
class _DistantTower extends CustomPainter {
  _DistantTower({
    required this.body,
    required this.edge,
    required this.lit,
    required this.haze,
  });

  final Color body;
  final Color edge;
  final Color lit;
  final Color haze;

  static const int _floors = 22;
  static const double _glow = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.12;
    final rect = Rect.fromLTWH(
      size.width * 0.74,
      size.height * 0.1,
      w,
      size.height * 0.7,
    );
    // Haze rising from the lit lobby.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.55, 1.1),
          radius: 0.9,
          colors: [haze.withValues(alpha: 0.55), haze.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas
      ..drawRect(rect, Paint()..color = body)
      ..drawLine(rect.topLeft, rect.bottomLeft, Paint()..color = edge);
    final floor = rect.height / _floors;
    final window = Paint()..color = lit;
    final glow = Paint()
      ..color = lit.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glow);
    // The lobby (Chapter 1, now) and the last room (the top floor) are the only lights on.
    final lobby = Rect.fromLTWH(
      rect.left + w * 0.12,
      rect.bottom - floor * 1.4,
      w * 0.76,
      floor * 0.9,
    );
    final lastRoom = Rect.fromLTWH(
      rect.left + w * 0.58,
      rect.top + floor * 0.6,
      w * 0.2,
      floor * 0.45,
    );
    canvas
      ..drawRect(lobby, glow)
      ..drawRect(lobby, window)
      ..drawRect(lastRoom, glow)
      ..drawRect(lastRoom, window);
    final faint = Paint()..color = edge;
    for (var i = 2; i < _floors - 1; i++) {
      final y = rect.top + floor * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), faint);
    }
  }

  @override
  bool shouldRepaint(_DistantTower oldDelegate) => false;
}
