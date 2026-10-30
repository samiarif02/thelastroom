import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';
import '../light/flicker.dart';
import 'silhouette_figure.dart';

/// An interviewer as a rim-lit silhouette with a code-driven idle (D2): they breathe, turn
/// their head slowly, and the rim light flickers with the lamp. The idle runs on the
/// [AmbientClock], so it stands still under reduced motion; [idle] false stills it too.
///
/// Sized by its parent at [SilhouetteFigure.aspectRatio].
class InterviewerSilhouette extends StatelessWidget {
  const InterviewerSilhouette({
    super.key,
    required this.figure,
    this.grade = ChapterGrade.lobby,
    this.lightFrom = -1,
    this.idle = true,
    this.semanticLabel,
  });

  final SilhouetteFigure figure;
  final ChapterGrade grade;

  /// Which side the lamp is on: -1 left, 1 right. The rim falls on that edge.
  final double lightFrom;
  final bool idle;

  /// What a screen reader hears ("Priya, the recruiter"). Null leaves it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final painted = AspectRatio(
      aspectRatio: SilhouetteFigure.aspectRatio,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: SilhouettePainter(
            figure: figure,
            grade: grade,
            lightFrom: lightFrom,
            clock: idle ? AmbientClock.of(context) : null,
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: painted);
    return Semantics(image: true, label: label, child: painted);
  }
}

/// Paints a [SilhouetteFigure], lit, at the idle pose for [clock]'s time. Public so a scene can
/// paint the figure into its own layer (brief 10's set).
class SilhouettePainter extends CustomPainter {
  SilhouettePainter({
    required this.figure,
    required this.grade,
    this.lightFrom = -1,
    this.clock,
  }) : super(repaint: clock);

  final SilhouetteFigure figure;
  final ChapterGrade grade;
  final double lightFrom;
  final ValueListenable<double>? clock;

  // Idle: a breath every ~4.6 s, the head drifting round every ~13 s.
  static const double _breathPeriod = 4.6;
  static const double _breathLift = 0.9;
  static const double _breathSwell = 0.008;
  static const double _turnPeriod = 13;
  static const double _turnShift = 1.4;
  static const double _turnTilt = 0.03;
  static const double _rimWidth = 2.2;

  /// The idle pose at [seconds]: (breath -1…1, turn -1…1).
  static ({double breath, double turn}) pose(double seconds) {
    final breath = math.sin(seconds * 2 * math.pi / _breathPeriod);
    // Cubing the sine holds the head near each end of the turn, then glides across: a
    // person looking, not a pendulum.
    final s = math.sin(seconds * 2 * math.pi / _turnPeriod);
    return (breath: breath, turn: s * s * s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock?.value ?? 0;
    final (:breath, :turn) = pose(t);
    final light = lampFlicker(t);
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

    final dark = Paint()..color = BrandColors.void_;
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          grade.key.withValues(alpha: light),
          grade.key.withValues(alpha: 0.15 * light),
        ],
      ).createShader(Offset.zero & design);
    final detailPaint = Paint()
      ..color = grade.key.withValues(alpha: 0.22 * light)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // The body swells on the in-breath, from the bottom edge.
    final body = figure.body();
    canvas
      ..save()
      ..translate(0, design.height)
      ..scale(1, 1 + _breathSwell * breath)
      ..translate(0, -design.height)
      ..drawPath(body, dark)
      ..drawPath(
        SilhouetteFigure.rim(body, side: lightFrom, width: _rimWidth),
        rimPaint,
      )
      ..drawPath(figure.bodyLines(), detailPaint)
      ..restore();

    // The head rides the breath and turns about the neck.
    final head = figure.head();
    final neck = figure.neck;
    canvas
      ..save()
      ..translate(neck.dx + _turnShift * turn, neck.dy - _breathLift * breath)
      ..rotate(_turnTilt * turn)
      ..translate(-neck.dx, -neck.dy)
      ..drawPath(head, dark)
      ..drawPath(
        SilhouetteFigure.rim(head, side: lightFrom, width: _rimWidth),
        rimPaint,
      )
      ..drawPath(figure.headLines(), detailPaint);
    if (catchesLight(figure, lightFrom)) {
      canvas.drawCircle(
        figure.glint,
        _glintRadius,
        Paint()..color = grade.key.withValues(alpha: light),
      );
    }
    canvas
      ..restore()
      ..restore();
  }

  static const double _glintRadius = 1.3;

  /// Whether [figure]'s glint (an earring, a lens) is on the side the lamp is on. On the far
  /// side it would float in the dark beside the head: after the push-in it read as a lone
  /// bright dot next to the subtitle (owner's phone review, 2026-10-30). A catch-light can only
  /// be where the light falls.
  static bool catchesLight(SilhouetteFigure figure, double lightFrom) =>
      (figure.glint.dx - figure.neck.dx) * lightFrom > 0;

  @override
  bool shouldRepaint(SilhouettePainter oldDelegate) =>
      oldDelegate.figure != figure ||
      oldDelegate.grade != grade ||
      oldDelegate.lightFrom != lightFrom;
}
