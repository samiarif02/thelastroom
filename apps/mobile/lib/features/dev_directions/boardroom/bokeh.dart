import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../shared/ambient.dart';

/// The city out of focus behind the glass: soft discs that breathe very slowly. Each disc is
/// blurred on its own (a mask filter), so nothing full-screen is ever blurred.
class Bokeh extends StatelessWidget {
  const Bokeh({
    super.key,
    required this.colors,
    this.count = 34,
    this.seed = 5,
  });

  final List<Color> colors;
  final int count;
  final int seed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _BokehPainter(
          clock: AmbientClock.of(context),
          colors: colors,
          count: count,
          seed: seed,
        ),
      ),
    ),
  );
}

class _BokehPainter extends CustomPainter {
  _BokehPainter({
    required this.clock,
    required this.colors,
    required this.count,
    required this.seed,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<Color> colors;
  final int count;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final t = clock.value;
    for (var i = 0; i < count; i++) {
      final x = r.nextDouble() * size.width;
      final y = size.height * (0.05 + r.nextDouble() * 0.6);
      final radius = 6 + r.nextDouble() * 22;
      final breathe = 0.75 + 0.25 * math.sin(t * 0.4 + i);
      final color = colors[r.nextInt(colors.length)];
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = color.withValues(
            alpha: (0.12 + r.nextDouble() * 0.3) * breathe,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_BokehPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
