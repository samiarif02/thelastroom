import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'face.dart';
import 'friendly_figure.dart';
import 'friendly_interviewer.dart';
import 'silhouette_figure.dart';

/// An interviewer in a scene: the friendly, illustrated person for [figure] (brief 16), with
/// a face that shows [expression] and an idle (breath, blink, a little sway) that stands still
/// under reduced motion. The name dates from the rim-lit silhouettes it replaced and stays
/// because the mission scene uses it.
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
    this.expression = InterviewerExpression.neutral,
  });

  final SilhouetteFigure figure;
  final ChapterGrade grade;

  /// Which side the light is on: -1 left, 1 right.
  final double lightFrom;
  final bool idle;

  /// What a screen reader hears ("Priya, the recruiter"). Null leaves it decorative.
  final String? semanticLabel;
  final InterviewerExpression expression;

  @override
  Widget build(BuildContext context) => FriendlyInterviewer(
    figure: FriendlyFigure.of(figure.id),
    expression: expression,
    grade: grade,
    lightFrom: lightFrom,
    idle: idle,
    semanticLabel: semanticLabel,
  );
}
