import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../camera/camera_shot.dart';
import '../figure/interviewer_silhouette.dart';
import '../figure/silhouette_figure.dart';
import '../light/bankers_lamp.dart';
import '../light/bokeh.dart';
import '../light/spotlight.dart';

/// The Boardroom as a set for the camera: a corner office after hours, in three planes that
/// move at different rates (parallax). Feed [layers] to a `CameraRig` or `DollyCamera`.
///
/// - back: the night beyond the glass, walnut panels, the city as warm bokeh;
/// - middle: the interviewer, rim-lit, in the lamp's pool, dust in the beam;
/// - front: the desk's brass edge and the banker's lamp.
///
/// The close-ups frame the interviewer's head and shoulders in the upper half, leaving the
/// lower half for subtitles and answer cards.
abstract final class BoardroomSet {
  /// The far plane barely moves.
  static const CameraShot backClose = CameraShot(
    scale: 1.18,
    focus: Alignment(0, -0.2),
    target: Alignment(0, -0.32),
  );

  /// The interviewer's close-up.
  static const CameraShot middleClose = CameraShot(
    scale: 1.75,
    focus: Alignment(0, -0.02),
    target: Alignment(0, -0.36),
  );

  /// The desk is nearest, so it travels furthest.
  static const CameraShot frontClose = CameraShot(
    scale: 1.95,
    focus: Alignment(0, 0.02),
    target: Alignment(0, -0.3),
  );

  /// A tighter framing for the follow-up question, reached by a hard cut, not a push.
  static const CameraShot middleTight = CameraShot(
    scale: 2.3,
    focus: Alignment(0.04, -0.12),
    target: Alignment(0, -0.4),
  );

  /// Where the desk's edge sits, as a share of the set's height.
  static const double deskLine = 0.68;

  /// The three planes, back to front. [tight] swaps the middle close-up for [middleTight].
  static List<CameraLayer> layers({
    required SilhouetteFigure figure,
    ChapterGrade grade = ChapterGrade.lobby,
    String? figureLabel,
    bool tight = false,
  }) => [
    CameraLayer(
      close: backClose,
      child: _Back(grade: grade),
    ),
    CameraLayer(
      close: tight ? middleTight : middleClose,
      child: _Middle(figure: figure, grade: grade, label: figureLabel),
    ),
    CameraLayer(
      close: frontClose,
      child: _Front(grade: grade),
    ),
  ];
}

class _Back extends StatelessWidget {
  const _Back({required this.grade});

  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const CustomPaint(painter: _WindowPainter()),
      Bokeh(colors: [grade.key, BrandColors.textPrimary, grade.tint]),
    ],
  );
}

class _Middle extends StatelessWidget {
  const _Middle({required this.figure, required this.grade, this.label});

  final SilhouetteFigure figure;
  final ChapterGrade grade;
  final String? label;

  static const double _figureWidth = 0.5;

  // The figure sits behind the desk: this share of it is hidden below the desk line.
  static const double _sunk = 0.12;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth * _figureWidth;
      final h = w / SilhouetteFigure.aspectRatio;
      final deskY = box.maxHeight * BoardroomSet.deskLine;
      return Stack(
        fit: StackFit.expand,
        children: [
          Spotlight(grade: grade, center: const Alignment(-0.72, 0.15)),
          Positioned(
            left: (box.maxWidth - w) / 2,
            top: deskY - h + h * _sunk,
            width: w,
            height: h,
            child: InterviewerSilhouette(
              figure: figure,
              grade: grade,
              semanticLabel: label,
            ),
          ),
        ],
      );
    },
  );
}

class _Front extends StatelessWidget {
  const _Front({required this.grade});

  final ChapterGrade grade;

  static const double _lampWidth = 0.3;
  static const double _lampLeft = 0.02;

  // The lamp's base sits a little below the desk's edge, on the desk.
  static const double _lampSink = 0.02;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final deskY = box.maxHeight * BoardroomSet.deskLine;
      final lampW = box.maxWidth * _lampWidth;
      final lampH = lampW / BankersLamp.aspectRatio;
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DeskPainter(grade: grade)),
          Positioned(
            left: box.maxWidth * _lampLeft,
            top: deskY - lampH + box.maxHeight * _lampSink,
            width: lampW,
            height: lampH,
            child: BankersLamp(grade: grade),
          ),
        ],
      );
    },
  );
}

/// The far plane: the night beyond the glass and the walnut panels either side of it.
class _WindowPainter extends CustomPainter {
  const _WindowPainter();

  static const double _glassInset = 0.12;
  static const double _glassBottom = 0.72;
  static const double _grainPitch = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final glass = Rect.fromLTRB(
      size.width * _glassInset,
      0,
      size.width * (1 - _glassInset),
      size.height * _glassBottom,
    );
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = BrandColors.surfaceRaised)
      ..drawRect(glass, Paint()..color = BrandColors.void_);
    // Walnut grain: fine vertical lines on the panels.
    final grain = Paint()
      ..color = BrandColors.line.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < size.width; x += _grainPitch) {
      if (x > glass.left && x < glass.right) continue;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grain);
    }
    canvas.drawLine(
      glass.topCenter,
      glass.bottomCenter,
      Paint()
        ..color = BrandColors.line
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WindowPainter oldDelegate) => false;
}

/// The near plane: the desk, falling into shadow, with its brass edge.
class _DeskPainter extends CustomPainter {
  const _DeskPainter({required this.grade});

  final ChapterGrade grade;

  @override
  void paint(Canvas canvas, Size size) {
    final deskY = size.height * BoardroomSet.deskLine;
    final desk = Rect.fromLTRB(0, deskY, size.width, size.height);
    canvas
      ..drawRect(
        desk,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.surfaceRaised, BrandColors.void_],
          ).createShader(desk),
      )
      ..drawLine(
        Offset(0, deskY),
        Offset(size.width, deskY),
        Paint()
          ..color = grade.key.withValues(alpha: 0.6)
          ..strokeWidth = 1.2,
      );
  }

  @override
  bool shouldRepaint(_DeskPainter oldDelegate) => oldDelegate.grade != grade;
}
