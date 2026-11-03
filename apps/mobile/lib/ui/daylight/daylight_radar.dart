import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// One shape on a [DaylightRadar]: scores out of 100, one per spoke, and how it's drawn.
@immutable
class RadarLayer {
  const RadarLayer({required this.values, this.fill, this.outline});

  /// 0–100, clockwise from the top.
  final List<int> values;

  /// The shape's flat fill (drawn translucent); null leaves it unfilled.
  final Color? fill;

  /// The edge and the dots; the floor's base colour by default.
  final Color? outline;
}

/// The four scores as a radar, in Daylight (Your file, the Chapter 1 report): a sand grid on
/// white, sentence-case labels outside each spoke with the score under them (tabular), and
/// one or more [layers] drawn back to front (the report puts the first try under the review).
/// The front shape grows from the centre over [DaylightMotion.move]; under reduced motion it's
/// just there. [empty] draws the grid with a dashed nothing-yet ring and no numbers.
class DaylightRadar extends StatelessWidget {
  const DaylightRadar({
    super.key,
    required this.labels,
    required this.layers,
    this.size = defaultSize,
    this.semanticLabel,
  }) : assert(labels.length >= 3);

  /// The radar before anything is played: the grid and the labels, no shape.
  const DaylightRadar.empty({
    super.key,
    required this.labels,
    this.size = defaultSize,
    this.semanticLabel,
  }) : layers = const [];

  final List<String> labels;
  final List<RadarLayer> layers;
  final double size;
  final String? semanticLabel;

  static const double defaultSize = 264;

  /// Room outside the grid for each label and its number.
  static const double _labelRoom = 56;
  static const double _labelWidth = 104;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final radius = size / 2 - _labelRoom;
    final front = layers.isEmpty ? null : layers.last;
    final n = labels.length;
    final label =
        semanticLabel ??
        (front == null
            ? labels.join(', ')
            : [for (var i = 0; i < n; i++) '${labels[i]} ${front.values[i]}']
                  .join(', '));
    Widget painted(double grow) => CustomPaint(
      painter: _RadarPainter(
        layers: [
          for (final l in layers)
            _Layer(
              values: l.values,
              fill: l.fill,
              outline: l.outline ?? f.base,
            ),
        ],
        grow: grow,
        radius: radius,
      ),
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: still
                  ? painted(1)
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: DaylightMotion.move,
                      curve: DaylightMotion.ease,
                      builder: (context, t, _) => painted(t),
                    ),
            ),
            for (var i = 0; i < n; i++)
              _label(i, n, radius + _labelRoom / 2, front?.values[i]),
          ],
        ),
      ),
    );
  }

  Widget _label(int i, int n, double r, int? value) {
    final a = -math.pi / 2 + 2 * math.pi * i / n;
    final c = Offset(size / 2, size / 2) + Offset.fromDirection(a, r);
    return Positioned(
      left: c.dx - _labelWidth / 2,
      top: c.dy - (value == null ? DaylightSpace.s8 : DaylightSpace.s16),
      width: _labelWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labels[i],
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
          ),
          if (value != null)
            Text(
              '$value',
              textAlign: TextAlign.center,
              style: DaylightType.tabular(DaylightType.body4),
            ),
        ],
      ),
    );
  }
}

class _Layer {
  const _Layer({
    required this.values,
    required this.fill,
    required this.outline,
  });

  final List<int> values;
  final Color? fill;
  final Color outline;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.layers,
    required this.grow,
    required this.radius,
  });

  final List<_Layer> layers;
  final double grow;
  final double radius;

  static const List<double> _rings = [0.25, 0.5, 0.75, 1];
  static const double _fillAlpha = 0.32;
  static const double _max = 100;
  static const double _edge = 2;
  static const double _dot = 3.5;
  static const int _spokes = 4;

  Offset _at(Offset c, int i, int n, double share) =>
      c +
      Offset.fromDirection(-math.pi / 2 + 2 * math.pi * i / n, radius * share);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final n = layers.isEmpty ? _spokes : layers.first.values.length;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = DaylightColors.sand2;
    // The outer ring is a flat sand well, the inner rings lines on it.
    final outer = Path();
    for (var i = 0; i < n; i++) {
      final p = _at(c, i, n, 1);
      i == 0 ? outer.moveTo(p.dx, p.dy) : outer.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(outer..close(), Paint()..color = DaylightColors.sand);
    for (final r in _rings) {
      final ring = Path();
      for (var i = 0; i < n; i++) {
        final p = _at(c, i, n, r);
        i == 0 ? ring.moveTo(p.dx, p.dy) : ring.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(ring..close(), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, _at(c, i, n, 1), grid);
    }
    for (final (index, layer) in layers.indexed) {
      // Only the front shape grows; the ones under it are already there.
      final g = index == layers.length - 1 ? grow : 1.0;
      final shape = Path();
      final points = [
        for (var i = 0; i < n; i++)
          _at(c, i, n, g * layer.values[i].clamp(0, _max) / _max),
      ];
      for (final (i, p) in points.indexed) {
        i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
      }
      shape.close();
      if (layer.fill case final fill?) {
        canvas.drawPath(
          shape,
          Paint()..color = fill.withValues(alpha: _fillAlpha),
        );
      }
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _edge
          ..strokeJoin = StrokeJoin.round
          ..color = layer.outline,
      );
      for (final p in points) {
        canvas.drawCircle(p, _dot, Paint()..color = layer.outline);
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.grow != grow || old.layers != layers || old.radius != radius;
}
