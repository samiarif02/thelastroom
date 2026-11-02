import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../figure/face.dart';
import '../figure/friendly_figure.dart';
import '../figure/friendly_interviewer.dart';
import '../figure/silhouette_figure.dart';

/// An interviewer's face in a round frame (brief 17: the chapter cards, the hero card,
/// onboarding's cast): head and shoulders cropped from the friendly figure, on a disc of
/// [ring]'s colour. Smiling, idle unless motion is reduced.
class InterviewerBadge extends StatelessWidget {
  const InterviewerBadge({
    super.key,
    required this.figure,
    required this.ring,
    this.size = 64,
    this.grade = ChapterGrade.lobby,
    this.expression = InterviewerExpression.smile,
    this.semanticLabel,
    this.idle = true,
  });

  final FriendlyFigure figure;

  /// The disc behind the face and its rim.
  final Color ring;
  final double size;
  final ChapterGrade grade;
  final InterviewerExpression expression;
  final String? semanticLabel;

  /// Breathing and blinking. Off for small faces in long lists, where the motion barely shows
  /// but each one would repaint every frame (brief 31).
  final bool idle;

  /// How much wider than the badge the figure is drawn: head and shoulders fill it.
  static const double _zoom = 1.9;

  /// Where the face sits in the figure, as a share of its design size (x, y).
  static const double _faceX = 0.5;
  static final double _faceY =
      FriendlyFigure.faceCenter.dy / SilhouetteFigure.designSize.height;

  static const double _rim = 3;
  static const double _discAlpha = 0.9;

  @override
  Widget build(BuildContext context) {
    final w = size * _zoom;
    final h = w / SilhouetteFigure.aspectRatio;
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring.withValues(alpha: _discAlpha),
        border: Border.all(color: BrandVivid.onDeep, width: _rim),
        boxShadow: BrandVivid.cardShadow,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Positioned(
              left: size / 2 - w * _faceX,
              top: size / 2 - h * _faceY,
              width: w,
              height: h,
              child: FriendlyInterviewer(
                figure: figure,
                expression: expression,
                grade: grade,
                idle: idle,
              ),
            ),
          ],
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: badge);
    return Semantics(image: true, label: label, child: badge);
  }
}
