import 'package:flutter/widgets.dart';

/// A pen line drawing itself: [path] revealed from start to end as [t] goes 0 → 1.
class PenStroke extends StatelessWidget {
  const PenStroke({
    super.key,
    required this.t,
    required this.path,
    required this.color,
    this.width = 2,
  });

  final double t;

  /// Built for the given size.
  final Path Function(Size size) path;
  final Color color;
  final double width;

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
    final full = path(size);
    final drawn = Path();
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var budget = total * t;
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
