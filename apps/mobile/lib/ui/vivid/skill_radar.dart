import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Scores out of 100 on a radar (brief 17's "Your file"): one spoke per skill, the shape filled
/// in [color] and outlined in [outline], grows from the centre when it first shows (unless
/// motion is reduced). Labels sit outside each spoke's tip.
class SkillRadar extends StatelessWidget {
  const SkillRadar({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.outline = BrandVivid.accent,
    this.size = 240,
  }) : assert(values.length == labels.length && values.length >= 3);

  /// 0–100, one per spoke, clockwise from the top.
  final List<int> values;
  final List<String> labels;
  final Color color;
  final Color outline;
  final double size;

  static const double _labelRoom = 46;
  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final n = values.length;
    final radius = size / 2 - _labelRoom;
    return Semantics(
      label: [for (var i = 0; i < n; i++) '${labels[i]} ${values[i]}']
          .join(', '),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        // Side labels reach past the square into the card's margin.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: still ? Duration.zero : BrandMotion.cinematic,
                curve: BrandMotion.enter,
                builder: (context, t, _) => CustomPaint(
                  painter: _RadarPainter(
                    values: values,
                    grow: t,
                    radius: radius,
                    fill: color,
                    outline: outline,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < n; i++) _label(i, n, radius + _labelRoom / 2),
          ],
        ),
      ),
    );
  }

  Widget _label(int i, int n, double r) {
    final a = -math.pi / 2 + 2 * math.pi * i / n;
    final c = Offset(size / 2, size / 2) + Offset.fromDirection(a, r);
    return Positioned(
      left: c.dx - _labelWidth / 2,
      top: c.dy - BrandSpace.md,
      width: _labelWidth,
      child: Column(
        children: [
          Text(
            labels[i].toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: BrandVividType.kicker.copyWith(
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '${values[i]}',
            style: BrandVividType.row.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.values,
    required this.grow,
    required this.radius,
    required this.fill,
    required this.outline,
  });

  final List<int> values;
  final double grow;
  final double radius;
  final Color fill;
  final Color outline;

  static const List<double> _rings = [0.25, 0.5, 0.75, 1];
  static const double _fillAlpha = 0.45;
  static const double _gridAlpha = 0.2;
  static const double _max = 100;

  Offset _at(Offset c, int i, double share) =>
      c +
      Offset.fromDirection(
        -math.pi / 2 + 2 * math.pi * i / values.length,
        radius * share,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final n = values.length;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = BrandVivid.onDeep.withValues(alpha: _gridAlpha);
    for (final r in _rings) {
      final ring = Path();
      for (var i = 0; i < n; i++) {
        final p = _at(c, i, r);
        i == 0 ? ring.moveTo(p.dx, p.dy) : ring.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(ring..close(), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, _at(c, i, 1), grid);
    }
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final p = _at(c, i, grow * values[i].clamp(0, _max) / _max);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas
      ..drawPath(shape, Paint()..color = fill.withValues(alpha: _fillAlpha))
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = outline,
      );
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
        _at(c, i, grow * values[i].clamp(0, _max) / _max),
        4,
        Paint()..color = outline,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.grow != grow || old.values != values || old.fill != fill;
}
