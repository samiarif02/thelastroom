import 'dart:typed_data';
import 'dart:ui';

/// Priya, head and shoulders, as paths drawn in code (no stock photos, no AI images yet: D2
/// decides the real portrait art). One shape, lit three different ways by the directions.
///
/// Coordinates are designed on a 100 × 120 box and scaled to fit [bounds].
abstract final class PriyaSilhouette {
  static const double _w = 100;
  static const double _h = 120;

  /// Width / height of the figure's box.
  static const double aspect = _w / _h;

  /// Body, neck and a sharp bob, as one solid silhouette.
  static Path figure(Rect bounds) => _scaled(bounds, _figure());

  /// The head and hair only, for rim light and close-up highlights.
  static Path head(Rect bounds) => _scaled(bounds, _head());

  /// The open collar of her blazer: two lapel lines.
  static Path lapels(Rect bounds) => _scaled(bounds, _lapels());

  /// The sheen on her bob: a side parting sweeping down to the jaw. Stroke it, don't fill it.
  static Path hairSweep(Rect bounds) => _scaled(bounds, _hairSweep());

  /// A small earring, where light catches first.
  static Rect earring(Rect bounds) {
    final sx = bounds.width / _w;
    final sy = bounds.height / _h;
    return Rect.fromCircle(
      center: Offset(bounds.left + 63.5 * sx, bounds.top + 61 * sy),
      radius: 1.3 * sx,
    );
  }

  /// The edge of the head light falls on from [side] (-1 left, 1 right): a thin crescent.
  static Path rim(Rect bounds, {required double side, double width = 2.4}) {
    final h = head(bounds);
    final scale = bounds.width / _w;
    final shifted = h.shift(Offset(-side * width * scale, 0));
    return Path.combine(PathOperation.difference, h, shifted);
  }

  static Path _scaled(Rect bounds, Path p) {
    final sx = bounds.width / _w;
    final sy = bounds.height / _h;
    final m = Float64List(16)
      ..[0] = sx
      ..[5] = sy
      ..[10] = 1
      ..[12] = bounds.left
      ..[13] = bounds.top
      ..[15] = 1;
    return p.transform(m);
  }

  static Path _figure() => Path()
    ..moveTo(0, 120)
    ..lineTo(0, 106)
    ..cubicTo(2, 95, 14, 89, 30, 86)
    ..cubicTo(37, 84.5, 41, 80, 42, 74)
    ..lineTo(42, 67)
    ..cubicTo(35, 66, 30.5, 58, 30.5, 47)
    ..cubicTo(30.5, 30, 38, 19.5, 50.5, 19.5)
    ..cubicTo(63, 19.5, 70.5, 29, 70, 46)
    ..cubicTo(69.6, 57, 66.5, 64, 58.5, 67)
    ..lineTo(58.5, 74)
    ..cubicTo(59.5, 80, 63.5, 84.5, 70, 86)
    ..cubicTo(86, 89, 98, 95, 100, 106)
    ..lineTo(100, 120)
    ..close();

  static Path _head() => Path()
    ..moveTo(42, 67)
    ..cubicTo(35, 66, 30.5, 58, 30.5, 47)
    ..cubicTo(30.5, 30, 38, 19.5, 50.5, 19.5)
    ..cubicTo(63, 19.5, 70.5, 29, 70, 46)
    ..cubicTo(69.6, 57, 66.5, 64, 58.5, 67)
    ..close();

  static Path _hairSweep() => Path()
    ..moveTo(45, 21)
    ..cubicTo(52, 27, 62, 32, 66.5, 44)
    ..cubicTo(68, 50, 67.5, 56, 65, 61)
    ..moveTo(44, 22)
    ..cubicTo(38, 27, 34, 36, 33.5, 47);

  static Path _lapels() => Path()
    ..moveTo(36, 85)
    ..lineTo(48, 112)
    ..lineTo(50, 98)
    ..moveTo(64, 85)
    ..lineTo(52, 112)
    ..lineTo(50, 98);
}
