import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A flat ground's texture: 5% noise in the ground's shadow tone over [child], never a
/// gradient. Seeded, so every frame (and every golden) is the same; painted once behind a
/// [RepaintBoundary].
class Grain extends StatelessWidget {
  const Grain({
    super.key,
    required this.child,
    this.opacity = DaylightElevation.grain,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _GrainPainter(opacity)),
          ),
        ),
      ),
    ],
  );
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.opacity);

  final double opacity;

  /// Grains per 100 × 100 logical pixels.
  static const int _density = 500;
  static const int _seed = 4;
  static const double _grain = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(_seed);
    final count = (size.width * size.height / 10000 * _density).round();
    final dark = <Offset>[];
    final light = <Offset>[];
    for (var i = 0; i < count; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      (random.nextBool() ? dark : light).add(p);
    }
    canvas
      ..drawRawPoints(
        PointMode.points,
        _floats(dark),
        Paint()
          ..strokeWidth = _grain
          ..color = DaylightColors.shadow.withValues(alpha: opacity),
      )
      ..drawRawPoints(
        PointMode.points,
        _floats(light),
        Paint()
          ..strokeWidth = _grain
          ..color = DaylightColors.raised.withValues(alpha: opacity),
      );
  }

  static Float32List _floats(List<Offset> points) => Float32List.fromList([
    for (final p in points) ...[p.dx, p.dy],
  ]);

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
