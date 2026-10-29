import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The towers across the street: dark blocks with a seeded scatter of lit windows. Night Glass
/// keeps it crisp; the Boardroom throws it out of focus into bokeh.
class CityLights extends StatelessWidget {
  const CityLights({
    super.key,
    required this.tower,
    required this.window,
    required this.warmWindow,
    this.lit = 0.18,
    this.seed = 11,
  });

  final Color tower;
  final Color window;

  /// The odd office still working late.
  final Color warmWindow;

  /// Share of windows lit.
  final double lit;
  final int seed;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _CityPainter(
        tower: tower,
        window: window,
        warmWindow: warmWindow,
        lit: lit,
        seed: seed,
      ),
    ),
  );
}

class _CityPainter extends CustomPainter {
  _CityPainter({
    required this.tower,
    required this.window,
    required this.warmWindow,
    required this.lit,
    required this.seed,
  });

  final Color tower;
  final Color window;
  final Color warmWindow;
  final double lit;
  final int seed;

  static const int _towers = 7;
  static const double _warmShare = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final towerPaint = Paint()..color = tower;
    final windowPaint = Paint();
    var x = -size.width * 0.05;
    for (var i = 0; i < _towers && x < size.width; i++) {
      final w = size.width * (0.12 + r.nextDouble() * 0.16);
      final top = size.height * (0.08 + r.nextDouble() * 0.45);
      final rect = Rect.fromLTRB(x, top, x + w, size.height);
      canvas.drawRect(rect, towerPaint);
      final cell = 5.0 + r.nextDouble() * 3;
      for (var wy = top + cell; wy < size.height - cell; wy += cell * 1.6) {
        for (var wx = x + cell * 0.6; wx < x + w - cell; wx += cell * 1.4) {
          if (r.nextDouble() > lit) continue;
          final warm = r.nextDouble() < _warmShare;
          windowPaint.color = (warm ? warmWindow : window).withValues(
            alpha: 0.25 + r.nextDouble() * 0.55,
          );
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, cell * 0.7, cell * 0.9),
            windowPaint,
          );
        }
      }
      x += w + size.width * (0.01 + r.nextDouble() * 0.04);
    }
  }

  @override
  bool shouldRepaint(_CityPainter oldDelegate) =>
      oldDelegate.tower != tower || oldDelegate.window != window;
}
