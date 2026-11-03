import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'cast_figure.dart';
import 'friendly_figure.dart';
import 'interviewer_expression.dart';
import 'silhouette_figure.dart';

/// An interviewer in one of the scenes that predate Daylight: the Daylight cast member for
/// [figure] in the old 100 × 120 figure box (`SilhouetteFigure.aspectRatio`), with the face
/// where the old face was. Everything else (the idle, the blend between expressions, reduced
/// motion) is `CastFigure`'s.
class FriendlyInterviewer extends StatelessWidget {
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

  /// The chapter the scene is in. The Daylight cast is lit the same on every floor; kept so
  /// the old scenes compile.
  final ChapterGrade grade;

  /// Which side the old figures' light was on. The Daylight cast is always lit from the
  /// viewer's left (its shading sits on the right); kept so the old scenes compile.
  final double lightFrom;
  final bool idle;

  /// What a screen reader hears ("Priya, the recruiter"). Null leaves it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: SilhouetteFigure.aspectRatio,
    child: LayoutBuilder(
      builder: (context, box) {
        final unit = box.maxWidth / SilhouetteFigure.designSize.width;
        final side = CastBody.grid * FriendlyFigure.gridScale * unit;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: FriendlyFigure.gridTop * unit,
              width: side,
              height: side,
              child: CastFigure(
                person: figure.person,
                expression: expression,
                idle: idle,
                semanticLabel: semanticLabel,
                extendBelow: FriendlyFigure.extendBelow,
              ),
            ),
          ],
        );
      },
    ),
  );
}
