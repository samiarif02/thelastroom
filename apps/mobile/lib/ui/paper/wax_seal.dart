import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// An oxblood wax seal with a number pressed into it (the dossier's total). The edge is
/// irregular, like poured wax; the ring and the figures are pressed in paper-cream.
///
/// A fixed [size]: at large text sizes its contents shrink to fit it rather than overflow.
class WaxSeal extends StatelessWidget {
  const WaxSeal({
    super.key,
    required this.value,
    this.label = 'OVERALL',
    this.size = 84,
  });

  final int value;
  final String label;
  final double size;

  static const double _ringInset = 0.1;
  static const double _valueSize = 30;
  static const double _labelSize = 7;
  static const double _labelTracking = 1.6;
  static const double _labelAlpha = 0.9;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: const _WaxPainter(),
          child: Padding(
            padding: EdgeInsets.all(size * _ringInset * 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: BrandType.score.copyWith(
                      color: BrandColors.paper,
                      fontSize: _valueSize,
                    ),
                  ),
                  Text(
                    label,
                    style: BrandType.label.copyWith(
                      color: BrandColors.paper.withValues(alpha: _labelAlpha),
                      fontSize: _labelSize,
                      letterSpacing: _labelTracking,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaxPainter extends CustomPainter {
  const _WaxPainter();

  static const int _lobes = 9;
  static const double _lobeDepth = 0.035;
  static const double _shade = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // Poured wax: a circle whose radius wobbles in a few soft lobes.
    final wax = Path();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * math.pi * 2;
      final wobble =
          1 -
          _lobeDepth * (0.5 + 0.5 * math.sin(a * _lobes + 0.6)) -
          _lobeDepth * 0.5 * math.sin(a * 3 + 1.9);
      final p = c + Offset(math.cos(a), math.sin(a)) * r * wobble;
      i == 0 ? wax.moveTo(p.dx, p.dy) : wax.lineTo(p.dx, p.dy);
    }
    wax.close();
    final deep = Color.lerp(BrandColors.redPen, BrandColors.void_, _shade)!;
    canvas
      ..drawPath(
        wax.shift(const Offset(1, 3)),
        Paint()
          ..color = BrandColors.ink.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawPath(
        wax,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [BrandColors.redPen, deep],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      )
      // The pressed ring, and a glint where the wax rose.
      ..drawCircle(
        c,
        r * (1 - WaxSeal._ringInset * 2),
        Paint()
          ..color = BrandColors.paper.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      )
      ..drawArc(
        Rect.fromCircle(center: c, radius: r * 0.9),
        math.pi * 1.1,
        math.pi * 0.35,
        false,
        Paint()
          ..color = BrandColors.paper.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_WaxPainter oldDelegate) => false;
}
