import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Who an interviewer is, and the box they're drawn in: the handle a scene passes to
/// [InterviewerSilhouette]. Each is drawn as a friendly, illustrated person
/// (`FriendlyFigure`, brief 16); the rim-lit silhouettes are gone. The name dates from them and
/// stays because the mission scene uses it (a rename is a follow-up for the lead).
///
/// Designed on a [designSize] box; the head (and its idle) pivots at [neck].
@immutable
class SilhouetteFigure {
  const SilhouetteFigure._({required this.id, required this.neck});

  /// Every figure is drawn on this box: 100 wide, 120 tall.
  static const Size designSize = Size(100, 120);

  /// Width / height.
  static const double aspectRatio = 100 / 120;

  /// The content id of the interviewer (`packages/content`).
  final String id;

  /// The pivot of the head, in design units.
  final Offset neck;

  /// The lit edge of [path] when light falls from [side] (-1 left, 1 right): a thin crescent.
  static Path rim(Path path, {required double side, double width = 2.4}) =>
      Path.combine(
        PathOperation.difference,
        path,
        path.shift(Offset(-side * width, 0)),
      );

  /// Priya, the recruiter (Missions 1–3, 7).
  static const SilhouetteFigure priya = SilhouetteFigure._(
    id: 'priya',
    neck: Offset(50, 68),
  );

  /// Marcus, the hiring manager (Missions 4–5, 7).
  static const SilhouetteFigure marcus = SilhouetteFigure._(
    id: 'marcus',
    neck: Offset(50, 68),
  );

  /// Lena, the senior engineer (Mission 6).
  static const SilhouetteFigure lena = SilhouetteFigure._(
    id: 'lena',
    neck: Offset(50, 68),
  );

  /// Every figure, by content id.
  static final Map<String, SilhouetteFigure> byId = {
    priya.id: priya,
    marcus.id: marcus,
    lena.id: lena,
  };
}
