import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../camera/camera_shot.dart';
import '../figure/face.dart';
import '../figure/interviewer_silhouette.dart';
import '../figure/silhouette_figure.dart';
import '../light/spotlight.dart';
import 'office_set.dart';

/// The Morning Office as a set for the camera (brief 16), in three planes that move at
/// different rates (parallax). Feed [layers] to a `CameraRig` or `DollyCamera`. The name
/// dates from the Boardroom and stays because the mission scene uses it.
///
/// - back: the wall, tall glass full of pale sky, the far city, the plant ([OfficeBackdrop]);
/// - middle: the interviewer in a pool of sunlight;
/// - front: the pale desk and the mug ([OfficeDesk]).
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

  /// A tighter framing for the follow-up question, reached by a hard cut, not a push. The
  /// desk takes the same framing as the interviewer, so it stays below her shoulders.
  static const CameraShot middleTight = CameraShot(
    scale: 2.3,
    focus: Alignment(0.04, -0.12),
    target: Alignment(0, -0.4),
  );

  /// Where the desk's edge sits, as a share of the set's height.
  static const double deskLine = 0.68;

  /// The three planes, back to front. [tight] swaps the middle and front close-ups for
  /// [middleTight].
  static List<CameraLayer> layers({
    required SilhouetteFigure figure,
    ChapterGrade grade = ChapterGrade.lobby,
    String? figureLabel,
    bool tight = false,
    InterviewerExpression expression = InterviewerExpression.neutral,
  }) => [
    CameraLayer(
      close: backClose,
      child: OfficeBackdrop(grade: grade),
    ),
    CameraLayer(
      close: tight ? middleTight : middleClose,
      child: _Middle(
        figure: figure,
        grade: grade,
        label: figureLabel,
        expression: expression,
      ),
    ),
    CameraLayer(
      close: tight ? middleTight : frontClose,
      child: OfficeDesk(grade: grade, deskLine: deskLine),
    ),
  ];
}

class _Middle extends StatelessWidget {
  const _Middle({
    required this.figure,
    required this.grade,
    required this.expression,
    this.label,
  });

  final InterviewerExpression expression;

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
              expression: expression,
            ),
          ),
        ],
      );
    },
  );
}
