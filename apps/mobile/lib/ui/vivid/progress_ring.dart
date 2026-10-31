import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Missions done out of total as a ring (brief 17's chapter cards), with [child] in the middle.
/// The arc draws itself in when it first shows, unless motion is reduced. The middle scales
/// down to fit at large text.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.stroke = 6,
    this.child,
  });

  /// 0–1.
  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? value : 0, end: value),
        duration: still ? Duration.zero : BrandMotion.cinematic,
        curve: BrandMotion.enter,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(value: v, color: color, stroke: stroke),
          // At large text the middle shrinks to fit inside the ring rather than spill out.
          child: Padding(
            padding: EdgeInsets.all(stroke * 1.5),
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
  });

  final double value;
  final Color color;
  final double stroke;

  static const double _trackAlpha = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      paint..color = BrandVivid.onDeep.withValues(alpha: _trackAlpha),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}
