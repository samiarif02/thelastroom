import 'package:flutter/widgets.dart';

/// A drawn tick or cross: the bundled fonts have no ✓ or ✗, and a glyph from a system fallback
/// would look different on every device. Decorative; the row it sits in carries the semantics.
class PointMark extends StatelessWidget {
  const PointMark({
    super.key,
    required this.made,
    required this.color,
    this.size = defaultSize,
  });

  final bool made;
  final Color color;
  final double size;

  static const double defaultSize = 16;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(made: made, color: color),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.made, required this.color});

  final bool made;
  final Color color;

  static const double _stroke = 0.16;

  // The tick's three points and the cross's inset, as fractions of the box.
  static const Offset _tickStart = Offset(0.14, 0.54);
  static const Offset _tickTurn = Offset(0.4, 0.8);
  static const Offset _tickEnd = Offset(0.88, 0.22);
  static const double _crossInset = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    if (made) {
      canvas.drawPath(
        Path()
          ..moveTo(at(_tickStart).dx, at(_tickStart).dy)
          ..lineTo(at(_tickTurn).dx, at(_tickTurn).dy)
          ..lineTo(at(_tickEnd).dx, at(_tickEnd).dy),
        paint,
      );
      return;
    }
    const lo = _crossInset;
    const hi = 1 - _crossInset;
    canvas
      ..drawLine(at(const Offset(lo, lo)), at(const Offset(hi, hi)), paint)
      ..drawLine(at(const Offset(hi, lo)), at(const Offset(lo, hi)), paint);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.made != made || old.color != color;
}
