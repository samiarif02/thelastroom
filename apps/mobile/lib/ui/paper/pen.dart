import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A fountain-pen line drawing itself: [path] revealed from start to end as [t] goes 0 → 1.
class PenStroke extends StatelessWidget {
  const PenStroke({
    super.key,
    required this.t,
    required this.path,
    this.color = BrandColors.redPen,
    this.width = 1.4,
  });

  final double t;

  /// Built for the size the stroke is given.
  final Path Function(Size size) path;
  final Color color;
  final double width;

  /// A hasty underline, slightly wavy, starting just before the text.
  static Path underline(Size s) => Path()
    ..moveTo(-2, s.height - 2)
    ..cubicTo(
      s.width * 0.2,
      s.height + 2,
      s.width * 0.5,
      s.height - 1,
      s.width * 0.75,
      s.height + 1,
    );

  /// A hand-drawn ring round [bounds]: one loop and a bit, slightly off-round, overshooting
  /// where it started, the way a pen circles a number.
  static Path ring(Rect bounds, {double start = -2.3, double sweep = 7.0}) {
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

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _PenPainter(t: t, path: path, color: color, width: width),
    ),
  );
}

class _PenPainter extends CustomPainter {
  _PenPainter({
    required this.t,
    required this.path,
    required this.color,
    required this.width,
  });

  final double t;
  final Path Function(Size size) path;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final metrics = path(size).computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var budget = total * t;
    final drawn = Path();
    for (final m in metrics) {
      if (budget <= 0) break;
      drawn.addPath(m.extractPath(0, budget.clamp(0, m.length)), Offset.zero);
      budget -= m.length;
    }
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_PenPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

/// The interviewer's note in the margin, in fountain-pen red italic, written left to right as
/// [t] goes 0 → 1 (an ink wipe with a soft wet edge), at a slight hand-held angle.
class PenNote extends StatelessWidget {
  const PenNote({super.key, required this.text, required this.t});

  final String text;
  final double t;

  static const double _angle = -0.05;
  static const double _wetEdge = 0.08;

  @override
  Widget build(BuildContext context) {
    final edge = t * (1 + _wetEdge);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: _angle,
        alignment: Alignment.centerLeft,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              BrandColors.redPen,
              BrandColors.redPen,
              BrandColors.clear,
            ],
            stops: [0, (edge - _wetEdge).clamp(0, 1), edge.clamp(0, 1)],
          ).createShader(bounds),
          child: Text(text, style: BrandType.note),
        ),
      ),
    );
  }
}
