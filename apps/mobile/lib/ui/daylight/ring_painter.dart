import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A ring: a full [track] and an arc of [value] (0…1) in [fill], from twelve o'clock clockwise
/// with round ends. Shared by the score dial and the weekly ring.
class RingPainter extends CustomPainter {
  const RingPainter({
    required this.value,
    required this.fill,
    required this.track,
    required this.stroke,
  });

  final double value;
  final Color fill;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(rect, paint..color = track);
    final v = value.clamp(0.0, 1.0);
    if (v <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      v * 2 * math.pi,
      false,
      paint
        ..color = fill
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.fill != fill ||
      oldDelegate.track != track ||
      oldDelegate.stroke != stroke;
}
