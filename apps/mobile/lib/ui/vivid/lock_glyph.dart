import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A small padlock, drawn: shackle and body.
class LockGlyph extends StatelessWidget {
  const LockGlyph({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size(size, size), painter: _LockPainter(color)),
  );
}

class _LockPainter extends CustomPainter {
  const _LockPainter(this.color);

  final Color color;

  static const double _stroke = 1.4;
  static const double _bodyTop = 0.45;
  static const double _shackleInset = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawRect(Rect.fromLTRB(0, h * _bodyTop, w, h), paint)
      ..drawArc(
        Rect.fromLTRB(w * _shackleInset, 0, w * (1 - _shackleInset), h * 0.8),
        math.pi,
        math.pi,
        false,
        paint,
      );
  }

  @override
  bool shouldRepaint(_LockPainter old) => old.color != color;
}
