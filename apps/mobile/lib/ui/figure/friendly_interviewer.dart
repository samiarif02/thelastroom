import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';
import 'face.dart';
import 'friendly_figure.dart';
import 'silhouette_figure.dart';

/// A friendly interviewer (brief 16): an illustrated person with a face that changes
/// [expression], and an idle (breathing, blinking, a little sway) on the [AmbientClock], so it
/// stands still under reduced motion. A change of expression eases over
/// [BrandMotion.quick]; [InterviewerExpression.nod] also nods the head once (not under reduced
/// motion).
///
/// Sized by its parent at [SilhouetteFigure.aspectRatio], like the silhouette it replaces.
class FriendlyInterviewer extends StatefulWidget {
  const FriendlyInterviewer({
    super.key,
    required this.figure,
    this.expression = InterviewerExpression.neutral,
    this.grade = ChapterGrade.lobby,
    this.lightFrom = -1,
    this.idle = true,
    this.semanticLabel,
  });

  final FriendlyFigure figure;
  final InterviewerExpression expression;
  final ChapterGrade grade;

  /// Which side the light is on: -1 left, 1 right.
  final double lightFrom;
  final bool idle;

  /// What a screen reader hears ("Priya, the recruiter"). Null leaves it decorative.
  final String? semanticLabel;

  static const Duration nodLength = Duration(milliseconds: 900);

  @override
  State<FriendlyInterviewer> createState() => _FriendlyInterviewerState();
}

class _FriendlyInterviewerState extends State<FriendlyInterviewer>
    with TickerProviderStateMixin {
  late final AnimationController _ease = AnimationController(
    vsync: this,
    duration: BrandMotion.quick,
    value: 1,
  );
  late final AnimationController _nod = AnimationController(
    vsync: this,
    duration: FriendlyInterviewer.nodLength,
  );
  late FaceShape _from = FaceShape.of(widget.expression);

  @override
  void didUpdateWidget(FriendlyInterviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression == widget.expression) return;
    final still = MediaQuery.disableAnimationsOf(context);
    _from = FaceShape.lerp(
      _from,
      FaceShape.of(oldWidget.expression),
      _ease.value,
    );
    if (still) {
      _ease.value = 1;
    } else {
      _ease.forward(from: 0);
      if (widget.expression == InterviewerExpression.nod) {
        _nod.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _ease.dispose();
    _nod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget.idle ? AmbientClock.of(context) : null;
    final painted = AspectRatio(
      aspectRatio: SilhouetteFigure.aspectRatio,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FriendlyPainter(
            figure: widget.figure,
            from: _from,
            to: FaceShape.of(widget.expression),
            ease: _ease,
            nod: _nod,
            grade: widget.grade,
            lightFrom: widget.lightFrom,
            clock: clock,
          ),
        ),
      ),
    );
    final label = widget.semanticLabel;
    if (label == null) return ExcludeSemantics(child: painted);
    return Semantics(image: true, label: label, child: painted);
  }
}

/// Paints a [FriendlyFigure] with its face between [from] and [to] at [ease]'s value.
class FriendlyPainter extends CustomPainter {
  FriendlyPainter({
    required this.figure,
    required this.from,
    required this.to,
    required this.ease,
    required this.nod,
    required this.grade,
    required this.lightFrom,
    this.clock,
  }) : super(repaint: Listenable.merge([ease, nod, ?clock]));

  final FriendlyFigure figure;
  final FaceShape from;
  final FaceShape to;
  final Animation<double> ease;
  final Animation<double> nod;
  final ChapterGrade grade;
  final double lightFrom;
  final ValueListenable<double>? clock;

  static const double _breathSwell = 0.008;
  static const double _breathLift = 0.7;
  static const double _sway = 0.02;
  static const double _rimWidth = 1.6;

  // The shoulders sit this much higher than the silhouettes' (a shorter neck).
  static const double _shoulderRise = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock?.value ?? 0;
    final (:breath, :turn) = FaceGesture.pose(t);
    final face = FaceShape.lerp(from, to, Curves.easeOut.transform(ease.value));
    final c = figure.colors;
    const design = SilhouetteFigure.designSize;
    final scale = math.min(
      size.width / design.width,
      size.height / design.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - design.width * scale) / 2,
        size.height - design.height * scale,
      )
      ..scale(scale);

    final rim = Paint()..color = _rimColor.withValues(alpha: _rimAlpha);

    // The body breathes from the bottom edge.
    final body = figure.body();
    final bounds = body.getBounds();
    canvas
      ..save()
      ..translate(0, design.height)
      ..scale(1, 1 + _breathSwell * breath)
      ..translate(0, -design.height - _shoulderRise)
      // What the rise uncovers at the bottom edge.
      ..drawRect(
        Rect.fromLTRB(
          bounds.left,
          design.height - 2,
          bounds.right,
          design.height + _shoulderRise,
        ),
        Paint()..color = c.outer,
      )
      ..drawPath(FriendlyFigure.neckPath(), Paint()..color = c.skinShade)
      ..drawPath(body, Paint()..color = c.outer);
    figure.clothes(canvas, c);
    canvas
      ..drawPath(
        SilhouetteFigure.rim(body, side: lightFrom, width: _rimWidth),
        rim,
      )
      ..restore();

    // The head rides the breath, sways, leans with the expression and nods.
    const neck = FriendlyFigure.neck;
    canvas
      ..save()
      ..translate(
        neck.dx + turn * 0.6,
        neck.dy - _breathLift * breath + FaceGesture.nodDip(nod.value),
      )
      ..rotate(_sway * turn + face.headTilt)
      ..translate(-neck.dx, -neck.dy);
    _paintHead(canvas, face, FaceGesture.blink(t));
    canvas
      ..restore()
      ..restore();
  }

  // In daylight the rim is a soft sheen on the lit edge.
  static const double _rimAlpha = 0.4;
  static const Color _rimColor = BrandCast.highlight;

  void _paintHead(Canvas canvas, FaceShape face, double blink) {
    final c = figure.colors;
    final skin = Paint()..color = c.skin;
    final hair = Paint()..color = c.hair;
    final faceOval = Path()..addOval(FriendlyFigure.faceRect);

    canvas.drawPath(figure.hairBack(), hair);
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(
          FriendlyFigure.faceCenter.dx + side * FriendlyFigure.faceRx,
          FriendlyFigure.earY,
        ),
        FriendlyFigure.earRadius,
        skin,
      );
    }
    canvas
      ..drawPath(faceOval, skin)
      // Shade on the side away from the light, light on the near edge.
      ..drawPath(
        SilhouetteFigure.rim(faceOval, side: -lightFrom, width: 2.6),
        Paint()..color = c.skinShade.withValues(alpha: 0.55),
      );

    // Cheeks.
    if (face.blush > 0) {
      final blush = Paint()
        ..color = BrandCast.blush.withValues(alpha: face.blush)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
      canvas
        ..drawCircle(const Offset(41, 52), 2.8, blush)
        ..drawCircle(const Offset(59, 52), 2.8, blush);
    }

    _paintEyes(canvas, face, blink);
    _paintBrows(canvas, face);
    // Nose: a soft hook.
    canvas.drawPath(
      Path()
        ..moveTo(50.3, 47.5)
        ..quadraticBezierTo(48.6, 50.6, 49.4, 51.6)
        ..quadraticBezierTo(50.4, 52.2, 51.3, 51.5),
      Paint()
        ..color = c.skinShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round,
    );
    _paintMouth(canvas, face);

    final front = figure.hairFront();
    canvas.drawPath(front, hair);
    figure.accessories(canvas, c, lightFrom);
    // One rim round the whole head's outline, so it only ever falls on an outer edge.
    var outline = Path.combine(PathOperation.union, figure.hairBack(), front);
    outline = Path.combine(PathOperation.union, outline, faceOval);
    canvas.drawPath(
      SilhouetteFigure.rim(outline, side: lightFrom, width: _rimWidth),
      Paint()..color = _rimColor.withValues(alpha: _rimAlpha),
    );
  }

  void _paintEyes(Canvas canvas, FaceShape face, double blink) {
    final open = (face.eyeOpen * blink).clamp(0.08, 1.0);
    final look = Offset(face.lookX * 0.8, face.lookY * 0.7);
    for (final eye in [FriendlyFigure.eyeLeft, FriendlyFigure.eyeRight]) {
      final centre = eye + look;
      canvas.drawOval(
        Rect.fromCenter(center: centre, width: 3.4, height: 4.2 * open),
        Paint()..color = BrandCast.feature,
      );
      if (open > 0.5) {
        canvas.drawCircle(
          centre + const Offset(0.6, -0.7),
          0.55,
          Paint()..color = BrandCast.highlight,
        );
      }
    }
  }

  void _paintBrows(Canvas canvas, FaceShape face) {
    final brow = Paint()
      ..color = Color.lerp(figure.colors.hair, BrandCast.feature, 0.4)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (final (eye, lift, inward) in [
      (FriendlyFigure.eyeLeft, face.browLeft, 1.0),
      (FriendlyFigure.eyeRight, face.browRight, -1.0),
    ]) {
      final y = eye.dy - 5.6 + lift;
      final inner = Offset(eye.dx + inward * 3, y - face.browTilt);
      final outer = Offset(
        eye.dx - inward * 3.2,
        y + 0.4 + face.browTilt * 0.3,
      );
      canvas.drawPath(
        Path()
          ..moveTo(outer.dx, outer.dy)
          ..quadraticBezierTo(eye.dx, y - 1.1, inner.dx, inner.dy),
        brow,
      );
    }
  }

  void _paintMouth(Canvas canvas, FaceShape face) {
    final m = FriendlyFigure.mouth + Offset(face.mouthShift, 0);
    final half = face.mouthWidth / 2;
    final left = m - Offset(half, 0);
    final right = m + Offset(half, 0);
    final upper = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(m.dx, m.dy + face.mouthCurve, right.dx, right.dy);
    if (face.mouthOpen > 0.05) {
      // An open smile: the upper line, and a deeper lower lip.
      final open = Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(
          m.dx,
          m.dy + face.mouthCurve * 0.35,
          right.dx,
          right.dy,
        )
        ..quadraticBezierTo(
          m.dx,
          m.dy + face.mouthCurve + 3 * face.mouthOpen,
          left.dx,
          left.dy,
        )
        ..close();
      canvas.drawPath(open, Paint()..color = BrandCast.mouth);
    } else {
      canvas.drawPath(
        upper,
        Paint()
          ..color = BrandCast.mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(FriendlyPainter oldDelegate) =>
      oldDelegate.figure != figure ||
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.grade != grade ||
      oldDelegate.lightFrom != lightFrom;
}
