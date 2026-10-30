import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// "— ◆ CHAPTER ONE ◆ —": an eyebrow between brass rules and diamonds.
class BrassOrnament extends StatelessWidget {
  const BrassOrnament({
    super.key,
    required this.text,
    this.grade = ChapterGrade.lobby,
  });

  final String text;
  final ChapterGrade grade;

  static const double _rule = 28;
  static const double _ruleWeight = 0.8;
  static const double _diamond = 4;

  @override
  Widget build(BuildContext context) {
    final brass = grade.key;
    Widget line() => SizedBox(
      width: _rule,
      height: _ruleWeight,
      child: ColoredBox(color: brass),
    );
    Widget diamond() => Transform.rotate(
      angle: math.pi / 4,
      child: SizedBox.square(
        dimension: _diamond,
        child: ColoredBox(color: brass),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(width: BrandSpace.sm),
        diamond(),
        const SizedBox(width: BrandSpace.sm),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: BrandType.eyebrow.copyWith(color: brass),
          ),
        ),
        // The eyebrow's tracking leaves space after its last letter; this evens it out.
        const SizedBox(width: BrandSpace.xs),
        diamond(),
        const SizedBox(width: BrandSpace.sm),
        line(),
      ],
    );
  }
}

/// A double brass rule round a frame, drawing itself from the top centre outwards and down
/// both sides as [t] goes 0 → 1.
class BrassFramePainter extends CustomPainter {
  BrassFramePainter({required this.color, required this.t});

  final Color color;
  final double t;

  static const double _gap = 5;
  static const double _weight = 0.7;
  static const double _alpha = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _weight;
    for (final inset in [0.0, _gap]) {
      final r = (Offset.zero & size).deflate(inset);
      final path = Path()
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.center.dx, r.bottom)
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.center.dx, r.bottom);
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * t), paint);
      }
    }
  }

  @override
  bool shouldRepaint(BrassFramePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

/// A heavy rule over a hairline: the ledger rule on the dossier.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key, required this.color});

  final Color color;

  static const double _heavy = 0.8;
  static const double _light = 0.4;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: _heavy,
        width: double.infinity,
        child: ColoredBox(color: color),
      ),
      const SizedBox(height: _gap),
      SizedBox(
        height: _light,
        width: double.infinity,
        child: ColoredBox(color: color),
      ),
    ],
  );
}
