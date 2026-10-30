import 'dart:ui';

import 'package:flutter/foundation.dart';

/// An interviewer, head and shoulders, as paths drawn in code (D2, owner 2026-10-30: rim-lit
/// silhouettes, no portraits in v1). Designed on a [designSize] box; the painter scales it.
///
/// The head is separate from the body so the idle can turn it; [neck] is where it pivots.
@immutable
class SilhouetteFigure {
  const SilhouetteFigure._({
    required this.id,
    required this._body,
    required this._head,
    required this._bodyLines,
    required this._headLines,
    required this.glint,
    required this.neck,
  });

  /// Every figure is drawn on this box: 100 wide, 120 tall.
  static const Size designSize = Size(100, 120);

  /// Width / height.
  static const double aspectRatio = 100 / 120;

  /// The content id of the interviewer this figure draws (`packages/content`).
  final String id;

  final Path Function() _body;
  final Path Function() _head;
  final Path Function() _bodyLines;
  final Path Function() _headLines;

  /// Where light catches first on the head (an earring, a lens), in design units.
  final Offset glint;

  /// The pivot of the head turn, in design units.
  final Offset neck;

  /// Shoulders, torso and neck: everything that breathes but doesn't turn.
  Path body() => Path.combine(PathOperation.difference, _body(), _head());

  /// The head and hair.
  Path head() => _head();

  /// Clothing lines, stroked faintly in the key light (lapels, a tie). They breathe.
  Path bodyLines() => _bodyLines();

  /// Hair and face lines (a parting, glasses). They turn with the head.
  Path headLines() => _headLines();

  /// The lit edge of [path] when light falls from [side] (-1 left, 1 right): a thin crescent.
  static Path rim(Path path, {required double side, double width = 2.4}) =>
      Path.combine(
        PathOperation.difference,
        path,
        path.shift(Offset(-side * width, 0)),
      );

  /// Priya, the recruiter: a sharp bob and an open blazer (Missions 1–3, 7).
  static final SilhouetteFigure priya = SilhouetteFigure._(
    id: 'priya',
    body: () => Path()
      ..moveTo(0, 120)
      ..lineTo(0, 106)
      ..cubicTo(2, 95, 14, 89, 30, 86)
      ..cubicTo(37, 84.5, 41, 80, 42, 74)
      ..lineTo(42, 67)
      ..lineTo(58.5, 67)
      ..lineTo(58.5, 74)
      ..cubicTo(59.5, 80, 63.5, 84.5, 70, 86)
      ..cubicTo(86, 89, 98, 95, 100, 106)
      ..lineTo(100, 120)
      ..close(),
    head: () => Path()
      ..moveTo(42, 67)
      ..cubicTo(35, 66, 30.5, 58, 30.5, 47)
      ..cubicTo(30.5, 30, 38, 19.5, 50.5, 19.5)
      ..cubicTo(63, 19.5, 70.5, 29, 70, 46)
      ..cubicTo(69.6, 57, 66.5, 64, 58.5, 67)
      ..close(),
    bodyLines: () => Path()
      // Lapels.
      ..moveTo(36, 85)
      ..lineTo(48, 112)
      ..lineTo(50, 98)
      ..moveTo(64, 85)
      ..lineTo(52, 112)
      ..lineTo(50, 98),
    headLines: () => Path()
      // The bob's side parting, sweeping to the jaw.
      ..moveTo(45, 21)
      ..cubicTo(52, 27, 62, 32, 66.5, 44)
      ..cubicTo(68, 50, 67.5, 56, 65, 61)
      ..moveTo(44, 22)
      ..cubicTo(38, 27, 34, 36, 33.5, 47),
    glint: const Offset(63.5, 61),
    neck: const Offset(50, 68),
  );

  /// Marcus, the hiring manager: broad, close-cropped, a tie and glasses (Missions 4–5, 7).
  static final SilhouetteFigure marcus = SilhouetteFigure._(
    id: 'marcus',
    body: () => Path()
      ..moveTo(0, 120)
      ..lineTo(0, 99)
      ..cubicTo(2, 89, 16, 83.5, 31, 81.5)
      ..cubicTo(37.5, 80.5, 41, 77, 42, 72)
      ..lineTo(42, 67)
      ..lineTo(59, 67)
      ..lineTo(59, 72)
      ..cubicTo(60, 77, 63.5, 80.5, 70, 81.5)
      ..cubicTo(85, 83.5, 98, 89, 100, 99)
      ..lineTo(100, 120)
      ..close(),
    head: () => Path()
      ..moveTo(42, 67)
      ..cubicTo(36.5, 65, 33, 58, 33, 48)
      ..cubicTo(33, 36, 36, 26.5, 41, 25)
      ..cubicTo(45, 23.5, 56, 23.5, 60, 25)
      ..cubicTo(65.5, 26.5, 68, 36, 68, 47)
      ..cubicTo(68, 58, 64.5, 65, 59, 67)
      ..close(),
    bodyLines: () => Path()
      // Collar and tie.
      ..moveTo(42, 75)
      ..lineTo(48.5, 83)
      ..moveTo(59, 75)
      ..lineTo(52.5, 83)
      ..moveTo(48.5, 83)
      ..lineTo(52.5, 83)
      ..lineTo(53.5, 104)
      ..lineTo(50.5, 110)
      ..lineTo(47.5, 104)
      ..close(),
    headLines: () => Path()
      // Glasses.
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(37, 44, 11, 6.5),
          const Radius.circular(2),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 44, 11, 6.5),
          const Radius.circular(2),
        ),
      )
      ..moveTo(48, 46.5)
      ..lineTo(53, 46.5),
    glint: const Offset(61.5, 45.5),
    neck: const Offset(50.5, 68),
  );

  /// Every figure, by content id.
  static final Map<String, SilhouetteFigure> byId = {
    priya.id: priya,
    marcus.id: marcus,
  };
}
