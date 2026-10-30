import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';

/// Dust drifting in a beam of light: a few dozen seeded motes, painted on the ambient clock.
class Dust extends StatelessWidget {
  const Dust({
    super.key,
    required this.color,
    required this.beam,
    this.count = 46,
    this.seed = 7,
  });

  final Color color;

  /// Where the beam is, in 0–1 coordinates of this box. Motes outside it aren't drawn.
  final Rect beam;
  final int count;
  final int seed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _DustPainter(
          clock: AmbientClock.of(context),
          color: color,
          beam: beam,
          count: count,
          seed: seed,
        ),
      ),
    ),
  );
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.clock,
    required this.color,
    required this.beam,
    required this.count,
    required this.seed,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final Color color;
  final Rect beam;
  final int count;
  final int seed;

  static const double _drift = 0.012;
  static const double _maxRadius = 1.6;
  static const double _maxAlpha = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final t = clock.value;
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final speed = 0.3 + r.nextDouble();
      final phase = r.nextDouble() * math.pi * 2;
      final x =
          beam.left +
          beam.width *
              ((r.nextDouble() +
                      math.sin(t * 0.21 * speed + phase) * _drift * 4) %
                  1);
      final y =
          beam.top + beam.height * ((r.nextDouble() - t * _drift * speed) % 1);
      final twinkle = 0.5 + 0.5 * math.sin(t * 1.3 * speed + phase);
      paint.color = color.withValues(
        alpha: _maxAlpha * twinkle * r.nextDouble(),
      );
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        0.4 + r.nextDouble() * _maxRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.beam != beam;
}
