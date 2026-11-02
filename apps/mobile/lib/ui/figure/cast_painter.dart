import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'cast_idle.dart';
import 'cast_path.dart';

/// Paints one of the cast (`packages/brand` `CastPeople`) on the 200 × 200 grid, scaled to fit
/// the canvas and standing on its bottom edge (SVG's `xMidYMax meet`). The face is a blend from
/// [from] to [to] at [blend]'s value: matching shapes morph point by point (the brows, the open
/// eyes, the closed mouths), the rest cross-fade. The head turns and drops as one group about
/// the neck. [clock] drives the idle (breath, sway, blink, the talking mouth); null holds still.
class CastPainter extends CustomPainter {
  CastPainter({
    required this.person,
    required this.from,
    required this.to,
    required this.blend,
    required this.nod,
    this.clock,
    this.nodMoves = false,
    this.extendBelow = 0,
  }) : super(repaint: Listenable.merge([blend, nod, ?clock]));

  final CastPerson person;
  final CastPose from;
  final CastPose to;

  /// 0 at [from], 1 at [to]; eased here on the base curve.
  final Animation<double> blend;

  /// Progress through a nod (0…1): the head dips and comes back.
  final Animation<double> nod;

  /// The idle's seconds; null stands still (reduced motion, long lists).
  final ValueListenable<double>? clock;

  /// Whether the nod is the gesture (down and back) rather than the still frame (the head held
  /// down, as on the cast sheet).
  final bool nodMoves;

  /// How far (grid units) the torso continues below the grid, for a box taller than the bust.
  final double extendBelow;

  static const double _grid = CastBody.grid;

  /// Where the torso meets the grid's bottom edge (`CastBody.torso` runs x 14…186 there).
  static const double _torsoLeft = 14;
  static const Set<CastEyes> _openEyes = {
    CastEyes.open,
    CastEyes.wide,
    CastEyes.up,
    CastEyes.lidded,
  };

  /// Never squash the eyes flatter than this in a blink: a dark lash line, not nothing.
  static const double _blinkFloor = 0.1;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    final seconds = clock?.value;
    final b = DaylightMotion.ease.transform(blend.value.clamp(0, 1));
    final palette = person.palette;

    canvas
      ..save()
      ..translate((size.width - _grid * scale) / 2, size.height - _grid * scale)
      ..scale(scale);
    if (seconds != null) {
      final breath = CastIdle.breath(seconds);
      canvas
        ..translate(_grid / 2, _grid)
        ..scale(breath)
        ..translate(-_grid / 2, -_grid);
    }

    final rotation =
        CastPathData.mix(from.rotation, to.rotation, b) +
        (seconds == null ? 0 : CastIdle.sway(seconds));
    final dy =
        CastPathData.mix(_dyOf(from), _dyOf(to), b) +
        CastIdle.nodDip(nod.value);
    void head(void Function() draw) {
      const pivot = CastFeatures.pivot;
      canvas
        ..save()
        ..translate(0, dy)
        ..translate(pivot.dx, pivot.dy)
        ..rotate(rotation * math.pi / 180)
        ..translate(-pivot.dx, -pivot.dy);
      draw();
      canvas.restore();
    }

    head(() => _all(canvas, person.back, palette));
    if (extendBelow > 0) {
      canvas.drawRect(
        Rect.fromLTRB(
          _torsoLeft,
          _grid - 1,
          _grid - _torsoLeft,
          _grid + extendBelow,
        ),
        Paint()..color = palette.outer,
      );
    }
    _all(canvas, CastBody.neck, palette);
    _one(canvas, CastBody.torso, palette);
    _all(canvas, person.clothes, palette);

    head(() {
      _all(canvas, CastBody.ears, palette);
      _one(canvas, CastBody.head, palette);
      _one(canvas, CastBody.shading, palette);
      _all(
        canvas,
        CastFeatures.cheeks(CastPathData.mix(from.blush, to.blush, b)),
        palette,
      );
      final lift = CastPathData.mix(from.creaseLift, to.creaseLift, b);
      for (final x in [CastFeatures.eyeLeftX, CastFeatures.eyeRightX]) {
        _one(canvas, CastFeatures.crease(x, lift), palette);
      }
      _eyes(canvas, b, seconds, palette);
      _one(
        canvas,
        CastFeatures.brow(CastBrow.lerp(from.browLeft, to.browLeft, b), -1),
        palette,
      );
      _one(
        canvas,
        CastFeatures.brow(CastBrow.lerp(from.browRight, to.browRight, b), 1),
        palette,
      );
      _all(canvas, CastBody.nose, palette);
      _mouth(canvas, b, seconds, palette);
      _all(canvas, person.front, palette);
      _one(canvas, CastBody.rim, palette);
    });
    canvas.restore();
  }

  double _dyOf(CastPose pose) =>
      nodMoves && pose.eyes == CastEyes.closed ? 0 : pose.dy;

  void _eyes(Canvas canvas, double b, double? seconds, CastPalette palette) {
    final open = seconds != null && _openEyes.contains(to.eyes)
        ? math.max(CastIdle.blink(seconds), _blinkFloor)
        : 1.0;
    canvas.save();
    if (open < 1) {
      canvas
        ..translate(0, CastFeatures.eyeY)
        ..scale(1, open)
        ..translate(0, -CastFeatures.eyeY);
    }
    for (final x in [CastFeatures.eyeLeftX, CastFeatures.eyeRightX]) {
      _blend(
        canvas,
        CastFeatures.eye(from.eyes, x),
        CastFeatures.eye(to.eyes, x),
        b,
        palette,
      );
    }
    canvas.restore();
  }

  void _mouth(Canvas canvas, double b, double? seconds, CastPalette palette) {
    final flap = seconds != null && to.mouth == CastMouth.talk
        ? CastIdle.flap(seconds)
        : 1.0;
    canvas.save();
    if (flap < 1) {
      canvas
        ..translate(0, CastFeatures.mouthY)
        ..scale(1, flap)
        ..translate(0, -CastFeatures.mouthY);
    }
    _blend(
      canvas,
      CastFeatures.mouth(from.mouth),
      CastFeatures.mouth(to.mouth),
      b,
      palette,
    );
    canvas.restore();
  }

  /// [a] blended into [b] at [t]: morphed shape by shape when they match, else cross-faded.
  static void _blend(
    Canvas canvas,
    List<CastShape> a,
    List<CastShape> b,
    double t,
    CastPalette palette,
  ) {
    if (t <= 0) return _all(canvas, a, palette);
    if (t >= 1) return _all(canvas, b, palette);
    final morph =
        a.length == b.length &&
        [for (var i = 0; i < a.length; i++) _matches(a[i], b[i])]
            .every((m) => m);
    if (morph) {
      for (var i = 0; i < a.length; i++) {
        _morph(canvas, a[i], b[i], t, palette);
      }
      return;
    }
    _all(canvas, a, palette, alpha: 1 - t);
    _all(canvas, b, palette, alpha: t);
  }

  static bool _matches(CastShape a, CastShape b) {
    if (a.runtimeType != b.runtimeType) return false;
    if ((a.fill == null) != (b.fill == null)) return false;
    if ((a.stroke == null) != (b.stroke == null)) return false;
    return switch ((a, b)) {
      (CastPath(d: final da), CastPath(d: final db)) => CastPathData.parse(
        da,
      ).matches(CastPathData.parse(db)),
      _ => true,
    };
  }

  static void _morph(
    Canvas canvas,
    CastShape a,
    CastShape b,
    double t,
    CastPalette palette,
  ) {
    double m(double x, double y) => CastPathData.mix(x, y, t);
    final opacity = m(a.opacity, b.opacity);
    final strokeWidth = m(a.strokeWidth, b.strokeWidth);
    switch ((a, b)) {
      case (CastPath(d: final da), CastPath(d: final db)):
        final path = CastPathData.lerp(
          CastPathData.parse(da),
          CastPathData.parse(db),
          t,
        ).toPath();
        _paint(canvas, b, palette, opacity, strokeWidth, (p) {
          canvas.drawPath(path, p);
        });
      case (final CastEllipse ea, final CastEllipse eb):
        final rect = Rect.fromCenter(
          center: Offset(m(ea.cx, eb.cx), m(ea.cy, eb.cy)),
          width: m(ea.rx, eb.rx) * 2,
          height: m(ea.ry, eb.ry) * 2,
        );
        _paint(canvas, b, palette, opacity, strokeWidth, (p) {
          canvas.drawOval(rect, p);
        });
      case (final CastCircle ca, final CastCircle cb):
        _paint(canvas, b, palette, opacity, strokeWidth, (p) {
          canvas.drawCircle(
            Offset(m(ca.cx, cb.cx), m(ca.cy, cb.cy)),
            m(ca.r, cb.r),
            p,
          );
        });
      default:
        _one(canvas, b, palette, alpha: t);
        _one(canvas, a, palette, alpha: 1 - t);
    }
  }

  static void _all(
    Canvas canvas,
    List<CastShape> shapes,
    CastPalette palette, {
    double alpha = 1,
  }) {
    for (final s in shapes) {
      _one(canvas, s, palette, alpha: alpha);
    }
  }

  static void _one(
    Canvas canvas,
    CastShape shape,
    CastPalette palette, {
    double alpha = 1,
  }) {
    final opacity = shape.opacity * alpha;
    if (opacity <= 0) return;
    switch (shape) {
      case CastPath(:final d):
        final path = CastPathData.pathOf(d);
        _paint(canvas, shape, palette, opacity, shape.strokeWidth, (p) {
          canvas.drawPath(path, p);
        });
      case CastEllipse(:final cx, :final cy, :final rx, :final ry):
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2,
          height: ry * 2,
        );
        _paint(canvas, shape, palette, opacity, shape.strokeWidth, (p) {
          canvas.drawOval(rect, p);
        });
      case CastCircle(:final cx, :final cy, :final r):
        _paint(canvas, shape, palette, opacity, shape.strokeWidth, (p) {
          canvas.drawCircle(Offset(cx, cy), r, p);
        });
      case CastRect():
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(shape.x, shape.y, shape.width, shape.height),
          Radius.circular(shape.radius),
        );
        canvas.save();
        if (shape.rotation != 0) {
          canvas
            ..translate(shape.pivotX, shape.pivotY)
            ..rotate(shape.rotation * math.pi / 180)
            ..translate(-shape.pivotX, -shape.pivotY);
        }
        _paint(canvas, shape, palette, opacity, shape.strokeWidth, (p) {
          canvas.drawRRect(rect, p);
        });
        canvas.restore();
    }
  }

  /// Fills, then strokes, [shape] with [draw].
  static void _paint(
    Canvas canvas,
    CastShape shape,
    CastPalette palette,
    double opacity,
    double strokeWidth,
    void Function(Paint paint) draw,
  ) {
    final fill = shape.fill;
    if (fill != null) {
      draw(
        Paint()
          ..isAntiAlias = true
          ..color = palette
              .of(fill)
              .withValues(alpha: opacity * shape.fillOpacity),
      );
    }
    final stroke = shape.stroke;
    if (stroke != null) {
      draw(
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = shape.roundCap ? StrokeCap.round : StrokeCap.butt
          ..strokeJoin = StrokeJoin.round
          ..color = palette.of(stroke).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(CastPainter oldDelegate) =>
      oldDelegate.person != person ||
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.nodMoves != nodMoves ||
      oldDelegate.extendBelow != extendBelow ||
      oldDelegate.blend != blend ||
      oldDelegate.nod != nod ||
      oldDelegate.clock != clock;
}
