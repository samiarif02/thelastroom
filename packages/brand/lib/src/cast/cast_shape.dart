import 'package:flutter/foundation.dart';

/// What a cast shape is painted with: one of a person's colour roles, or one of the few colours
/// every person shares (the features' ink, a catchlight, the teeth, the rim light).
enum CastInk {
  skin,

  /// The skin's one shade tone: ears, neck, the shading crescent, lid creases, the nose.
  shade,
  lip,
  blush,
  hair,

  /// The hair's rim light.
  hairHi,
  brow,
  beard,

  /// Jacket, blazer, jumper.
  outer,
  outerShade,

  /// The shirt or top under it.
  inner,

  /// A tie, an earring, a lanyard.
  accent,

  /// Glasses frames.
  frame,
  freckle,

  /// Eyes and lashes: the darkest line on a face.
  feature,

  /// The glint in an eye.
  catchlight,
  teeth,

  /// The sunlit rim on the hair.
  rimLight,

  /// A glint on a lens, the glass itself.
  white,

  /// The soft shadow under the chin.
  black,

  /// Lena's Northstar badge.
  badge,

  /// Lena's ear studs.
  stud,

  /// The ribs on Sam's turtleneck.
  rib,
}

/// One shape on the cast's 200 × 200 grid: a path, an ellipse, a circle or a rect, filled
/// and/or stroked. Plain shapes only (no filters, no gradients), so a `CustomPainter` and an
/// SVG draw exactly the same thing.
@immutable
sealed class CastShape {
  const CastShape({
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.roundCap = true,
    this.opacity = 1,
    this.fillOpacity = 1,
  });

  final CastInk? fill;
  final CastInk? stroke;
  final double strokeWidth;

  /// Round line caps (most strokes); butt caps otherwise.
  final bool roundCap;

  /// The whole shape's opacity.
  final double opacity;

  /// The fill's own opacity (the near-clear lenses).
  final double fillOpacity;

  /// The shape's kind, as the JSON names it.
  String get kind;
}

/// An SVG path: absolute `M`, `L`, `Q`, `C` and `Z` only.
final class CastPath extends CastShape {
  const CastPath(
    this.d, {
    super.fill,
    super.stroke,
    super.strokeWidth,
    super.roundCap,
    super.opacity,
    super.fillOpacity,
  });

  final String d;

  @override
  String get kind => 'path';
}

final class CastEllipse extends CastShape {
  const CastEllipse(
    this.cx,
    this.cy,
    this.rx,
    this.ry, {
    super.fill,
    super.stroke,
    super.strokeWidth,
    super.opacity,
  });

  final double cx;
  final double cy;
  final double rx;
  final double ry;

  @override
  String get kind => 'ellipse';
}

final class CastCircle extends CastShape {
  const CastCircle(
    this.cx,
    this.cy,
    this.r, {
    super.fill,
    super.stroke,
    super.strokeWidth,
    super.opacity,
  });

  final double cx;
  final double cy;
  final double r;

  @override
  String get kind => 'circle';
}

/// A rounded rect, optionally turned [rotation] degrees about ([pivotX], [pivotY]).
final class CastRect extends CastShape {
  const CastRect(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.radius = 0,
    this.rotation = 0,
    this.pivotX = 0,
    this.pivotY = 0,
    super.fill,
    super.stroke,
    super.strokeWidth,
    super.opacity,
    super.fillOpacity,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double radius;
  final double rotation;
  final double pivotX;
  final double pivotY;

  @override
  String get kind => 'rect';
}

/// A number in a path string: at most two decimals, no trailing zeros ("77.4", "84").
String castNumber(double v) {
  final fixed = v.toStringAsFixed(2);
  final trimmed = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
  return trimmed == '-0' ? '0' : trimmed;
}
