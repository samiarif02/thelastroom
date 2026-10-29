import 'dart:math' as math;
import 'dart:ui';

/// A hand-drawn ring around [bounds]: one loop and a bit, slightly off-round, overshooting where
/// it started, the way a pen circles a number.
Path penRing(Rect bounds, {double start = -2.3, double sweep = 7.0}) {
  const steps = 64;
  final c = bounds.center;
  final path = Path();
  for (var i = 0; i <= steps; i++) {
    final f = i / steps;
    final a = start + sweep * f;
    // The loop drifts outward as it goes round, so the overshoot doesn't sit on the start.
    final drift = 1 + 0.08 * f;
    final p = Offset(
      c.dx + math.cos(a) * bounds.width / 2 * drift,
      c.dy + math.sin(a) * bounds.height / 2 * drift,
    );
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path;
}
