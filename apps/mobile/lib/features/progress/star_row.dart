import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../tower/tower_rooms.dart';

/// Up to three stars and the best score: a done mission's grade, in "Your file" (vivid).
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    required this.best,
    this.size = 18,
  });

  final int stars;
  final int best;
  final double size;

  static const double _emptyAlpha = 0.28;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of $maxStars stars, best $best',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxStars; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: CustomPaint(
              size: Size.square(size),
              painter: StarPainter(
                color: i < stars
                    ? BrandVivid.accent
                    : BrandVivid.onDeep.withValues(alpha: _emptyAlpha),
              ),
            ),
          ),
        const SizedBox(width: BrandSpace.xs),
        Text(
          '$best',
          style: BrandVividType.row.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

/// A five-pointed star, filled.
class StarPainter extends CustomPainter {
  const StarPainter({required this.color});

  final Color color;

  static const int _points = 5;
  static const double _inner = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < _points * 2; i++) {
      final radius = i.isEven ? r : r * _inner;
      final a = -math.pi / 2 + i * math.pi / _points;
      final p = c + Offset.fromDirection(a, radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(StarPainter old) => old.color != color;
}
