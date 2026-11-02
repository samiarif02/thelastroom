import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The tower's way into Settings (brief 20): a round outlined button with a gear drawn in code.
class SettingsGear extends StatelessWidget {
  const SettingsGear({super.key, required this.onTap});

  final VoidCallback onTap;

  static const String label = 'Settings';

  static const double _size = BrandSpace.minTarget;
  static const double _glyph = 22;
  static const double _ringAlpha = 0.5;

  @override
  Widget build(BuildContext context) => Pressable(
    label: label,
    onTap: onTap,
    child: Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: BrandVivid.hairline(_ringAlpha)),
      ),
      child: CustomPaint(
        size: const Size.square(_glyph),
        painter: _GearPainter(color: BrandVivid.onDeep),
      ),
    ),
  );
}

class _GearPainter extends CustomPainter {
  const _GearPainter({required this.color});

  final Color color;

  static const int _teeth = 8;
  static const double _outer = 0.5;
  static const double _inner = 0.36;
  static const double _hole = 0.15;
  static const double _toothHalf = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide;
    final gear = Path();
    for (var i = 0; i < _teeth * 4; i++) {
      // Each tooth: up the flank, across the top, down the flank, along the root.
      final tooth = i ~/ 4;
      final step = i % 4;
      final base = 2 * math.pi * tooth / _teeth;
      const spread = 2 * math.pi / _teeth * _toothHalf;
      final (angle, radius) = switch (step) {
        0 => (base - spread * 1.6, _inner),
        1 => (base - spread, _outer),
        2 => (base + spread, _outer),
        _ => (base + spread * 1.6, _inner),
      };
      final p = c + Offset.fromDirection(angle, r * radius);
      i == 0 ? gear.moveTo(p.dx, p.dy) : gear.lineTo(p.dx, p.dy);
    }
    gear
      ..close()
      ..addOval(Rect.fromCircle(center: c, radius: r * _hole))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(gear, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GearPainter old) => old.color != color;
}
