import 'dart:ui' show Offset, lerpDouble;

import 'package:flutter/foundation.dart';

import 'cast_shape.dart';

/// The eyes' seven shapes. Small almonds, about 16% of the face's width, with a lid crease
/// above: adult, never cartoon dots.
enum CastEyes { open, wide, up, happy, closed, lidded }

/// The mouth's shapes. It rarely opens.
enum CastMouth { neutral, soft, smile, hmm, purse, talk }

/// A brow's arc: where its outer end, its peak and its inner end sit on the grid. Brows do
/// most of the acting.
@immutable
class CastBrow {
  const CastBrow(this.outerY, this.peakY, this.innerY);

  final double outerY;
  final double peakY;
  final double innerY;

  static const CastBrow neutral = CastBrow(73.6, 70.6, 72.6);
  static const CastBrow soft = CastBrow(72.8, 69.6, 71.6);
  static const CastBrow raised = CastBrow(70.2, 66.2, 69.2);
  static const CastBrow high = CastBrow(68.6, 64.2, 67.6);
  static const CastBrow low = CastBrow(75, 73.4, 74.4);
  static const CastBrow knit = CastBrow(72.6, 72.2, 75.6);

  /// Every named brow, for the JSON export.
  static const Map<String, CastBrow> named = {
    'neutral': neutral,
    'soft': soft,
    'raised': raised,
    'high': high,
    'low': low,
    'knit': knit,
  };

  /// A brow raised this high lifts the lid crease with it.
  bool get lifts => peakY <= raised.peakY;

  static CastBrow lerp(CastBrow a, CastBrow b, double t) => CastBrow(
    lerpDouble(a.outerY, b.outerY, t)!,
    lerpDouble(a.peakY, b.peakY, t)!,
    lerpDouble(a.innerY, b.innerY, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is CastBrow &&
      other.outerY == outerY &&
      other.peakY == peakY &&
      other.innerY == innerY;

  @override
  int get hashCode => Object.hash(outerY, peakY, innerY);
}

/// One expression's settings (direction.md, "Seven expressions"): eyes, brows (the viewer's
/// left, then right), mouth, and the head's lean ([rotation] degrees about the neck) and drop
/// ([dy]), plus how much the cheeks colour.
@immutable
class CastPose {
  const CastPose({
    required this.eyes,
    required this.browLeft,
    required this.browRight,
    required this.mouth,
    this.rotation = 0,
    this.dy = 0,
    this.blush = 0,
  });

  final CastEyes eyes;
  final CastBrow browLeft;
  final CastBrow browRight;
  final CastMouth mouth;
  final double rotation;
  final double dy;
  final double blush;

  /// How far the lid creases rise with the brows.
  double get creaseLift =>
      browLeft.lifts || browRight.lifts ? CastFeatures.creaseLift : 0;
}

/// The seven expressions, and when a scene uses each.
enum CastExpression {
  /// Idle.
  neutral(
    CastPose(
      eyes: CastEyes.open,
      browLeft: CastBrow.neutral,
      browRight: CastBrow.neutral,
      mouth: CastMouth.neutral,
    ),
  ),

  /// The player is choosing or speaking: leaning in.
  listening(
    CastPose(
      eyes: CastEyes.wide,
      browLeft: CastBrow.raised,
      browRight: CastBrow.soft,
      mouth: CastMouth.soft,
      rotation: 3.5,
      dy: 1.5,
    ),
  ),

  /// The "why?" step, and any wait (a delay reads as thought).
  thinking(
    CastPose(
      eyes: CastEyes.up,
      browLeft: CastBrow.soft,
      browRight: CastBrow.high,
      mouth: CastMouth.purse,
      rotation: -5,
    ),
  ),

  /// A sound pick or reason.
  nod(
    CastPose(
      eyes: CastEyes.closed,
      browLeft: CastBrow.soft,
      browRight: CastBrow.soft,
      mouth: CastMouth.soft,
      rotation: 1.5,
      dy: 4,
      blush: 0.25,
    ),
  ),

  /// A strong answer, the debrief, a celebration.
  smile(
    CastPose(
      eyes: CastEyes.happy,
      browLeft: CastBrow.soft,
      browRight: CastBrow.soft,
      mouth: CastMouth.smile,
      rotation: 2.5,
      blush: 0.45,
    ),
  ),

  /// A weak pick; Lena's follow-up. Curious, not cross.
  hmm(
    CastPose(
      eyes: CastEyes.lidded,
      browLeft: CastBrow.low,
      browRight: CastBrow.high,
      mouth: CastMouth.hmm,
      rotation: -2.5,
    ),
  ),

  /// While a line types out.
  talk(
    CastPose(
      eyes: CastEyes.open,
      browLeft: CastBrow.soft,
      browRight: CastBrow.neutral,
      mouth: CastMouth.talk,
      rotation: 1,
    ),
  );

  const CastExpression(this.pose);

  final CastPose pose;
}

/// The face's parts on the 200 grid, as functions of the expression's settings: the same
/// numbers as `cast.js`. Eyes sit at y 86 (x 84 and 116), brows near y 74, the mouth near
/// y 117.
abstract final class CastFeatures {
  /// The eyes' centres, the viewer's left then right.
  static const double eyeLeftX = 84;
  static const double eyeRightX = 116;
  static const double eyeY = 86;

  /// How far a lid crease rises when a brow goes up.
  static const double creaseLift = 1.2;

  /// The head turns and drops about this point (the neck).
  static const Offset pivot = Offset(100, 140);

  /// Where the mouth opens and closes when talking.
  static const double mouthY = 116;

  static String _n(double v) => castNumber(v);

  /// One eye of [kind] centred at x [cx].
  static List<CastShape> eye(CastEyes kind, double cx) {
    String x(double dx) => _n(cx + dx);
    return switch (kind) {
      CastEyes.open => [
        CastPath(
          'M${x(-6.6)} 86 Q${x(0)} 77.4 ${x(6.6)} 86 Q${x(0)} 92.2 ${x(-6.6)} 86Z',
          fill: CastInk.feature,
        ),
        CastCircle(cx + 1.9, 84, 1.5, fill: CastInk.catchlight),
      ],
      CastEyes.wide => [
        CastPath(
          'M${x(-6.8)} 86 Q${x(0)} 76 ${x(6.8)} 86 Q${x(0)} 93 ${x(-6.8)} 86Z',
          fill: CastInk.feature,
        ),
        CastCircle(cx + 2, 83.4, 1.6, fill: CastInk.catchlight),
      ],
      CastEyes.up => [
        CastPath(
          'M${x(-6.2)} 85 Q${x(0.8)} 76.6 ${x(6.8)} 84.4 Q${x(0.6)} 90.6 ${x(-6.2)} 85Z',
          fill: CastInk.feature,
        ),
        CastCircle(cx + 3, 82.4, 1.5, fill: CastInk.catchlight),
      ],
      CastEyes.happy => [
        CastPath(
          'M${x(-7)} 87.4 Q${x(0)} 78.6 ${x(7)} 87.4 Q${x(0)} 84.2 ${x(-7)} 87.4Z',
          fill: CastInk.feature,
        ),
      ],
      CastEyes.closed => [
        CastPath(
          'M${x(-6.5)} 86 Q${x(0)} 90.4 ${x(6.5)} 86',
          stroke: CastInk.feature,
          strokeWidth: 2.3,
        ),
      ],
      CastEyes.lidded => [
        CastPath(
          'M${x(-6.6)} 86 L${x(6.6)} 85.4 Q${x(0)} 91.4 ${x(-6.6)} 86Z',
          fill: CastInk.feature,
        ),
        CastPath(
          'M${x(-7.4)} 85.2 L${x(7.4)} 84.6',
          stroke: CastInk.feature,
          strokeWidth: 1.8,
        ),
      ],
    };
  }

  /// The lid crease above the eye at [cx], raised by [lift].
  static CastShape crease(double cx, double lift) => CastPath(
    'M${_n(cx - 6)} ${_n(79.6 - lift)} Q${_n(cx)} ${_n(76.2 - lift)} '
    '${_n(cx + 6)} ${_n(79.2 - lift)}',
    stroke: CastInk.shade,
    strokeWidth: 1.3,
    opacity: 0.9,
  );

  /// A brow of [shape]; [side] -1 is the viewer's left, 1 the right.
  static CastShape brow(CastBrow shape, int side) {
    final cx = side < 0 ? eyeLeftX : eyeRightX;
    final outerX = cx + side * 9;
    final innerX = cx - side * 7.5;
    return CastPath(
      'M${_n(innerX)} ${_n(shape.innerY)} Q${_n(cx + side * 1.5)} ${_n(shape.peakY)} '
      '${_n(outerX)} ${_n(shape.outerY)}',
      stroke: CastInk.brow,
      strokeWidth: 3.4,
    );
  }

  static List<CastShape> mouth(CastMouth kind) => switch (kind) {
    CastMouth.neutral => const [
      CastPath(
        'M93 117.4 Q100 119.6 107 117.4',
        stroke: CastInk.lip,
        strokeWidth: 2.5,
      ),
    ],
    CastMouth.soft => const [
      CastPath(
        'M91.5 116.6 Q100 121.6 108.5 116.6',
        stroke: CastInk.lip,
        strokeWidth: 2.6,
      ),
    ],
    CastMouth.smile => const [
      CastPath(
        'M89.5 115.2 Q100 116.4 110.5 115.2 Q108.6 124.6 100 125 Q91.4 124.6 89.5 115.2Z',
        fill: CastInk.lip,
      ),
      CastPath(
        'M91.6 115.6 Q100 116.6 108.4 115.6 L107.6 118.2 Q100 119.4 92.4 118.2Z',
        fill: CastInk.teeth,
      ),
    ],
    CastMouth.hmm => const [
      CastPath(
        'M93 118.6 Q99 117.2 107.6 115.8',
        stroke: CastInk.lip,
        strokeWidth: 2.5,
      ),
    ],
    CastMouth.purse => const [
      CastEllipse(103.5, 117.6, 3, 2.3, fill: CastInk.lip),
    ],
    CastMouth.talk => const [
      CastPath(
        'M94 116 Q100 115 106 116 Q105 122.6 100 122.8 Q95 122.6 94 116Z',
        fill: CastInk.lip,
      ),
    ],
  };

  /// The cheeks; their opacity is the expression's blush.
  static List<CastShape> cheeks(double blush) => [
    CastEllipse(eyeLeftX, 103, 7.5, 4.2, fill: CastInk.blush, opacity: blush),
    CastEllipse(eyeRightX, 103, 7.5, 4.2, fill: CastInk.blush, opacity: blush),
  ];
}

/// The body every person shares, on the same grid: the head, neck, ears and torso, the soft
/// shading crescent on the face's far side, the nose and the faint rim light on the hair.
abstract final class CastBody {
  static const CastPath head = CastPath(
    'M100 38 C126 38 140 56 140 82 C140 106 130 125 113 132.6 C106 135.6 94 135.6 87 132.6 '
    'C70 125 60 106 60 82 C60 56 74 38 100 38Z',
    fill: CastInk.skin,
  );

  static const CastPath torso = CastPath(
    'M14 200 C16 172 30 157 58 150.5 L84 145 L116 145 L142 150.5 C170 157 184 172 186 200Z',
    fill: CastInk.outer,
  );

  static const List<CastShape> neck = [
    CastPath('M85 118 L115 118 L117 150 L83 150Z', fill: CastInk.shade),
    CastPath(
      'M85 122 Q100 136 115 122 L115 132 Q100 142 85 132Z',
      fill: CastInk.black,
      opacity: 0.12,
    ),
  ];

  static const List<CastShape> ears = [
    CastEllipse(60.5, 90, 6, 9.5, fill: CastInk.shade),
    CastEllipse(139.5, 90, 6, 9.5, fill: CastInk.shade),
    CastEllipse(61.5, 90, 3, 5.5, fill: CastInk.skin, opacity: 0.5),
    CastEllipse(138.5, 90, 3, 5.5, fill: CastInk.skin, opacity: 0.5),
  ];

  static const CastPath shading = CastPath(
    'M128 56 C138 70 141 92 134 110 C128 124 118 131 108 134 C122 122 131 104 131 86 '
    'C131 74 130 64 128 56Z',
    fill: CastInk.shade,
    opacity: 0.55,
  );

  static const List<CastShape> nose = [
    CastPath(
      'M99.2 90 Q96.6 100 96.4 104.2',
      stroke: CastInk.shade,
      strokeWidth: 2.2,
    ),
    CastPath(
      'M95.6 105.6 Q100 108.2 104.6 105.6',
      stroke: CastInk.shade,
      strokeWidth: 2.2,
    ),
  ];

  static const CastPath rim = CastPath(
    'M64 72 C66 56 77 44.5 91 41',
    stroke: CastInk.rimLight,
    strokeWidth: 2,
    opacity: 0.35,
  );

  /// The grid every shape is drawn on.
  static const double grid = 200;
}
