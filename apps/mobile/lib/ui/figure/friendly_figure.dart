import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// An interviewer as a warm, illustrated person (brief 16), drawn in code on the same
/// 100 × 120 box as the silhouettes, with the head inside the same face box, so the subtitle
/// layout that keeps lines clear of the face still holds (`MissionSet.faceInDesign`).
///
/// Everyone shares one face (eyes, brows, nose, mouth, drawn by the painter from a
/// `FaceShape`); people differ in [colors], hair, clothes and one accessory.
@immutable
class FriendlyFigure {
  const FriendlyFigure._({
    required this.id,
    required this.colors,
    required this.body,
    required this.hairBack,
    required this.hairFront,
    required this.clothes,
    required this.accessories,
  });

  /// The content id of the interviewer (`packages/content`).
  final String id;
  final CastColors colors;

  /// Shoulders and torso (the outer layer: blazer, jacket, jumper).
  final Path Function() body;

  /// Hair behind the head (a bob's volume, a bun).
  final Path Function() hairBack;

  /// Hair over the forehead.
  final Path Function() hairFront;

  /// Draws the inner layer and clothing details over [body].
  final void Function(Canvas canvas, CastColors c) clothes;

  /// Draws what sits on the face (glasses, a beard, earrings, freckles) over the face. [lit]
  /// is the side the light is on (-1 left, 1 right): a sparkle is only drawn there.
  final void Function(Canvas canvas, CastColors c, double lit) accessories;

  // Shared anatomy, in design units.
  static const Offset faceCenter = Offset(50, 45);
  static const double faceRx = 13.5;
  static const double faceRy = 16;
  static const Offset eyeLeft = Offset(44.5, 46);
  static const Offset eyeRight = Offset(55.5, 46);
  static const Offset mouth = Offset(50, 55.5);
  static const Offset neck = Offset(50, 68);
  static const double earY = 47;
  static const double earRadius = 3;

  static Rect get faceRect => Rect.fromCenter(
    center: faceCenter,
    width: faceRx * 2,
    height: faceRy * 2,
  );

  /// The neck, from under the chin into the collar.
  static Path neckPath() => Path()
    ..addRRect(RRect.fromLTRBR(44.5, 54, 55.5, 80, const Radius.circular(4)));

  /// Priya, the recruiter: a sharp side-parted bob, a teal blazer, gold hoops.
  static final FriendlyFigure priya = FriendlyFigure._(
    id: 'priya',
    colors: BrandCast.priya,
    body: () => Path()
      ..moveTo(2, 120)
      ..lineTo(2, 106)
      ..cubicTo(4, 94, 16, 88, 31, 85)
      ..cubicTo(37, 83.5, 41, 79.5, 42.5, 76)
      ..lineTo(57.5, 76)
      ..cubicTo(59, 79.5, 63, 83.5, 69, 85)
      ..cubicTo(84, 88, 96, 94, 98, 106)
      ..lineTo(98, 120)
      ..close(),
    hairBack: () => Path()
      ..moveTo(33.5, 62)
      ..cubicTo(30.5, 50, 31, 33, 38, 26)
      ..cubicTo(43, 21, 57, 20.5, 63, 25.5)
      ..cubicTo(70, 31.5, 70.5, 50, 67.5, 62)
      ..quadraticBezierTo(50, 64.5, 33.5, 62)
      ..close(),
    hairFront: () => Path()
      ..moveTo(36, 48)
      ..cubicTo(35, 33, 41.5, 25.5, 50.5, 25.5)
      ..cubicTo(59.5, 25.5, 65.5, 31.5, 65, 44)
      ..lineTo(64.5, 52)
      ..cubicTo(62.5, 42, 57, 34.5, 45.5, 33.5)
      ..cubicTo(41, 35.5, 38.5, 40.5, 37.8, 48)
      ..close(),
    clothes: (canvas, c) {
      // The top under the blazer, and the lapels either side of it.
      canvas
        ..drawPath(
          Path()
            ..moveTo(42.5, 77)
            ..lineTo(57.5, 77)
            ..lineTo(50, 100)
            ..close(),
          Paint()..color = c.inner,
        )
        ..drawPath(
          Path()
            ..moveTo(42, 78)
            ..lineTo(36, 86)
            ..lineTo(48.5, 110)
            ..lineTo(50, 100)
            ..close()
            ..moveTo(58, 78)
            ..lineTo(64, 86)
            ..lineTo(51.5, 110)
            ..lineTo(50, 100)
            ..close(),
          Paint()..color = Color.lerp(c.outer, BrandCast.feature, 0.22)!,
        );
    },
    accessories: (canvas, c, lit) {
      final hoop = Paint()
        ..color = c.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      for (final x in [36.2, 63.8]) {
        canvas.drawCircle(Offset(x, 52.5), 1.7, hoop);
      }
      // The gold catches the light on the lit side only.
      canvas.drawCircle(
        Offset(lit < 0 ? 35.4 : 64.6, 51.6),
        0.55,
        Paint()..color = BrandCast.highlight,
      );
    },
  );

  /// Marcus, the hiring manager: close-cropped hair, a trimmed beard, glasses, jacket and tie.
  static final FriendlyFigure marcus = FriendlyFigure._(
    id: 'marcus',
    colors: BrandCast.marcus,
    body: () => Path()
      ..moveTo(0, 120)
      ..lineTo(0, 100)
      ..cubicTo(2, 89, 16, 83.5, 31, 81.5)
      ..cubicTo(37.5, 80.5, 41.5, 77.5, 43, 74)
      ..lineTo(57, 74)
      ..cubicTo(58.5, 77.5, 62.5, 80.5, 69, 81.5)
      ..cubicTo(84, 83.5, 98, 89, 100, 100)
      ..lineTo(100, 120)
      ..close(),
    hairBack: Path.new,
    hairFront: () => Path()
      ..moveTo(36.3, 43)
      ..cubicTo(35.5, 31, 41.5, 26, 50, 26)
      ..cubicTo(58.5, 26, 64.5, 31, 63.7, 43)
      ..cubicTo(61.5, 36, 57, 33, 50, 33)
      ..cubicTo(43, 33, 38.5, 36, 36.3, 43)
      ..close(),
    clothes: (canvas, c) {
      canvas
        // Shirt collar, open into a V.
        ..drawPath(
          Path()
            ..moveTo(43, 75)
            ..lineTo(57, 75)
            ..lineTo(50, 96)
            ..close(),
          Paint()..color = c.inner,
        )
        // The tie.
        ..drawPath(
          Path()
            ..moveTo(48.4, 79)
            ..lineTo(51.6, 79)
            ..lineTo(53, 104)
            ..lineTo(50, 110)
            ..lineTo(47, 104)
            ..close(),
          Paint()..color = c.accent,
        )
        // Lapels.
        ..drawPath(
          Path()
            ..moveTo(43, 76)
            ..lineTo(35, 84)
            ..lineTo(46.5, 112)
            ..lineTo(48, 96)
            ..close()
            ..moveTo(57, 76)
            ..lineTo(65, 84)
            ..lineTo(53.5, 112)
            ..lineTo(52, 96)
            ..close(),
          Paint()..color = Color.lerp(c.outer, BrandCast.feature, 0.25)!,
        );
    },
    accessories: (canvas, c, lit) {
      // A short beard along the jaw, leaving the mouth clear.
      canvas.drawPath(
        Path()
          ..moveTo(36.8, 48)
          ..cubicTo(37.5, 59, 43.5, 63.5, 50, 63.5)
          ..cubicTo(56.5, 63.5, 62.5, 59, 63.2, 48)
          ..lineTo(62.4, 49)
          ..cubicTo(61.5, 57.5, 57, 60.6, 50, 60.6)
          ..cubicTo(43, 60.6, 38.5, 57.5, 37.6, 49)
          ..close(),
        Paint()..color = c.hair.withValues(alpha: 0.75),
      );
      final frame = Paint()
        ..color = BrandCast.feature
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas
        ..drawRRect(
          RRect.fromLTRBR(39.8, 42.6, 49, 49.4, const Radius.circular(2)),
          frame,
        )
        ..drawRRect(
          RRect.fromLTRBR(51, 42.6, 60.2, 49.4, const Radius.circular(2)),
          frame,
        )
        ..drawLine(const Offset(49, 45), const Offset(51, 45), frame)
        // A glint on the lens nearest the light.
        ..drawLine(
          Offset(lit < 0 ? 41.2 : 56.2, 44.2),
          Offset(lit < 0 ? 42.8 : 57.8, 43.4),
          Paint()
            ..color = BrandCast.highlight.withValues(alpha: 0.8)
            ..strokeWidth = 0.7
            ..strokeCap = StrokeCap.round,
        );
    },
  );

  /// Lena, the senior engineer: auburn hair up in a bun, freckles, a mustard jumper.
  static final FriendlyFigure lena = FriendlyFigure._(
    id: 'lena',
    colors: BrandCast.lena,
    body: () => Path()
      ..moveTo(3, 120)
      ..lineTo(3, 105)
      ..cubicTo(5, 93, 18, 87.5, 32, 85)
      ..cubicTo(38, 84, 41.5, 80, 43, 76)
      ..lineTo(57, 76)
      ..cubicTo(58.5, 80, 62, 84, 68, 85)
      ..cubicTo(82, 87.5, 95, 93, 97, 105)
      ..lineTo(97, 120)
      ..close(),
    hairBack: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 24.5), radius: 5.8))
      ..addOval(const Rect.fromLTRB(35.5, 27, 64.5, 50)),
    hairFront: () => Path()
      ..moveTo(36.4, 45)
      ..cubicTo(35.5, 32, 42, 27, 50, 27)
      ..cubicTo(58, 27, 64.5, 32, 63.6, 45)
      ..cubicTo(62, 37.5, 57.5, 33.5, 52, 33)
      ..cubicTo(47, 34.5, 43.5, 33.5, 41.5, 34.5)
      ..cubicTo(38.5, 36.5, 37, 40, 36.4, 45)
      ..close(),
    clothes: (canvas, c) {
      // A rolled collar.
      canvas.drawRRect(
        RRect.fromLTRBR(41, 73, 59, 81, const Radius.circular(4)),
        Paint()..color = c.inner,
      );
      // Knit ribs, faint.
      final rib = Paint()
        ..color = c.inner.withValues(alpha: 0.45)
        ..strokeWidth = 0.6;
      for (var x = 44.0; x <= 56; x += 3) {
        canvas.drawLine(Offset(x, 74), Offset(x, 80), rib);
      }
    },
    accessories: (canvas, c, lit) {
      final freckle = Paint()..color = c.skinShade;
      for (final p in const [
        Offset(41, 51),
        Offset(43, 52.5),
        Offset(40.5, 53.2),
        Offset(59, 51),
        Offset(57, 52.5),
        Offset(59.5, 53.2),
      ]) {
        canvas.drawCircle(p, 0.45, freckle);
      }
      for (final x in [36.4, 63.6]) {
        canvas.drawCircle(Offset(x, 50.6), 0.9, Paint()..color = c.accent);
      }
    },
  );

  /// Every figure, by content id.
  static final Map<String, FriendlyFigure> byId = {
    priya.id: priya,
    marcus.id: marcus,
    lena.id: lena,
  };

  /// The figure for [id], or Priya.
  static FriendlyFigure of(String id) => byId[id] ?? priya;
}
