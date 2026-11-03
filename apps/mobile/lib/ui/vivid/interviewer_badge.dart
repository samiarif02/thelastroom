import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../figure/cast_figure.dart';
import '../figure/friendly_figure.dart';
import '../figure/interviewer_expression.dart';

/// An interviewer's face in a round frame (the vivid tower's cards, the hero card,
/// onboarding's cast): head and shoulders of the Daylight cast member on a disc of [ring]'s
/// colour. Smiling, idle unless motion is reduced. The vivid screens keep it until they are
/// restyled; Daylight frames faces in an `ArchFrame` instead.
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

  /// The chapter the badge sits in; the cast is lit the same on every floor.
  final ChapterGrade grade;
  final InterviewerExpression expression;
  final String? semanticLabel;

  /// Breathing and blinking. Off for small faces in long lists, where the motion barely shows
  /// but each one would repaint every frame (brief 31).
  final bool idle;

  /// How much bigger than the badge the bust is drawn: head and shoulders fill it.
  static const double _zoom = 1.3;

  /// Where the face's middle sits on the cast's grid, as a share of it (x, y).
  static const double _faceX = 0.5;
  static const double _faceY = 0.52;

  static const double _rim = 3;
  static const double _discAlpha = 0.9;

  @override
  Widget build(BuildContext context) {
    final side = size * _zoom;
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
              left: size / 2 - side * _faceX,
              top: size / 2 - side * _faceY,
              width: side,
              height: side,
              child: CastFigure(
                person: figure.person,
                expression: expression,
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
