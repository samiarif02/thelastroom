import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';
import 'dust.dart';
import 'flicker.dart';

/// A pool of sunlight falling on the set at [center], breathing gently, with optional
/// dust in its beam. The grade decides its colour, so Chapter 2's pool is cold.
class Spotlight extends StatelessWidget {
  const Spotlight({
    super.key,
    this.grade = ChapterGrade.lobby,
    this.center = const Alignment(-0.7, 0.1),
    this.radius = 0.9,
    this.intensity = 0.8,
    this.dust = false,
  });

  final ChapterGrade grade;

  /// Where the lamp is.
  final Alignment center;

  /// The pool's radius, as [RadialGradient] measures it (a share of the box's longest side).
  final double radius;

  /// Peak opacity of the pool, 0–1.
  final double intensity;

  /// Motes in the beam. Off by default: in daylight they don't show.
  final bool dust;

  @override
  Widget build(BuildContext context) {
    final clock = AmbientClock.of(context);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _PoolPainter(
                clock: clock,
                grade: grade,
                center: center,
                radius: radius,
                intensity: intensity,
              ),
            ),
          ),
          if (dust)
            Dust(
              color: grade.key,
              beam: Rect.fromCenter(
                center: Offset(
                  (center.x + 1) / 2,
                  (center.y + 1) / 2 - _beamRise,
                ),
                width: _beamWidth,
                height: _beamHeight,
              ),
            ),
        ],
      ),
    );
  }

  static const double _beamRise = 0.05;
  static const double _beamWidth = 0.5;
  static const double _beamHeight = 0.45;
}

class _PoolPainter extends CustomPainter {
  _PoolPainter({
    required this.clock,
    required this.grade,
    required this.center,
    required this.radius,
    required this.intensity,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final ChapterGrade grade;
  final Alignment center;
  final double radius;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final light = intensity * lampFlicker(clock.value);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: center,
          radius: radius,
          colors: [
            grade.tint.withValues(alpha: light),
            grade.tint.withValues(alpha: light * 0.35),
            grade.tint.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PoolPainter oldDelegate) =>
      oldDelegate.grade != grade ||
      oldDelegate.center != center ||
      oldDelegate.radius != radius ||
      oldDelegate.intensity != intensity;
}
