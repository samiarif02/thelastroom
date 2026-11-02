import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'cast_shape.dart';

/// One person's colours (direction.md, "Characters"): one shade tone per material. Decorative
/// fills, never text, so they carry no contrast pairs.
@immutable
class CastPalette {
  const CastPalette({
    required this.skin,
    required this.shade,
    required this.lip,
    required this.blush,
    required this.hair,
    required this.hairHi,
    required this.brow,
    required this.outer,
    required this.outerShade,
    required this.inner,
    required this.accent,
    this.beard,
    this.frame,
    this.freckle,
  });

  final Color skin;
  final Color shade;
  final Color lip;
  final Color blush;
  final Color hair;
  final Color hairHi;
  final Color brow;
  final Color outer;
  final Color outerShade;
  final Color inner;
  final Color accent;
  final Color? beard;
  final Color? frame;
  final Color? freckle;

  /// The colour for [ink] on this person.
  Color of(CastInk ink) => switch (ink) {
    CastInk.skin => skin,
    CastInk.shade => shade,
    CastInk.lip => lip,
    CastInk.blush => blush,
    CastInk.hair => hair,
    CastInk.hairHi => hairHi,
    CastInk.brow => brow,
    CastInk.beard => beard ?? hair,
    CastInk.outer => outer,
    CastInk.outerShade => outerShade,
    CastInk.inner => inner,
    CastInk.accent => accent,
    CastInk.frame => frame ?? CastShared.feature,
    CastInk.freckle => freckle ?? shade,
    CastInk.feature => CastShared.feature,
    CastInk.catchlight => CastShared.catchlight,
    CastInk.teeth => CastShared.teeth,
    CastInk.rimLight => CastShared.rimLight,
    CastInk.white => CastShared.white,
    CastInk.black => CastShared.black,
    CastInk.badge => CastShared.badge,
    CastInk.stud => CastShared.stud,
    CastInk.rib => CastShared.rib,
  };

  /// Every role this palette fills in, for the JSON export.
  Map<CastInk, Color> get roles => {
    for (final ink in CastInk.values.where((i) => !CastShared.isShared(i)))
      ink: of(ink),
  };
}

/// The colours every person shares.
abstract final class CastShared {
  static const Color feature = Color(0xFF231A1A);
  static const Color catchlight = Color(0xFFFFF8F0);
  static const Color teeth = Color(0xFFFFFBF5);
  static const Color rimLight = Color(0xFFFFF6E2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color badge = Color(0xFFF7F3EA);
  static const Color stud = Color(0xFFE2B04B);
  static const Color rib = Color(0xFF5E2034);

  static bool isShared(CastInk ink) => switch (ink) {
    CastInk.feature ||
    CastInk.catchlight ||
    CastInk.teeth ||
    CastInk.rimLight ||
    CastInk.white ||
    CastInk.black ||
    CastInk.badge ||
    CastInk.stud ||
    CastInk.rib => true,
    _ => false,
  };

  static Map<CastInk, Color> get all => {
    for (final ink in CastInk.values.where(isShared))
      ink: switch (ink) {
        CastInk.catchlight => catchlight,
        CastInk.teeth => teeth,
        CastInk.rimLight => rimLight,
        CastInk.white => white,
        CastInk.black => black,
        CastInk.badge => badge,
        CastInk.stud => stud,
        CastInk.rib => rib,
        _ => feature,
      },
  };
}

/// One interviewer: who, their colours, and the shapes that make them themselves. [back] sits
/// behind the head (a bob's volume, a bun) and turns with it; [clothes] sit on the torso;
/// [front] sits over the face (hair, glasses, beard, freckles, jewellery).
@immutable
class CastPerson {
  const CastPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.palette,
    required this.back,
    required this.clothes,
    required this.front,
  });

  /// The content id (`packages/content`).
  final String id;
  final String name;
  final String role;
  final CastPalette palette;
  final List<CastShape> back;
  final List<CastShape> clothes;
  final List<CastShape> front;
}

/// The four interviewers, ported shape for shape from `docs/design/mockups/shared/cast.js`
/// (the sheet: `mockups/cast/png/cast-sheet-1440.jpg`).
abstract final class CastPeople {
  /// Priya, the recruiter: a black bob with a side-swept fringe, a gold hoop, a teal blazer.
  static const CastPerson priya = CastPerson(
    id: 'priya',
    name: 'Priya',
    role: 'Recruiter',
    palette: CastPalette(
      skin: Color(0xFFB9785A),
      shade: Color(0xFF9A5D41),
      lip: Color(0xFF7E3B33),
      blush: Color(0xFFD9686A),
      hair: Color(0xFF1F1719),
      hairHi: Color(0xFF4A3A3E),
      brow: Color(0xFF1F1719),
      outer: Color(0xFF1E7A72),
      outerShade: Color(0xFF165F59),
      inner: Color(0xFFF6EDE0),
      accent: Color(0xFFE2AE45),
    ),
    back: [
      CastPath(
        'M56 84 C54 52 72 31 100 31 C130 31 147 52 145 84 C144 104 146 120 151 132 '
        'C141 140 127 140 118 134 L82 134 C73 140 59 140 49 132 C54 120 56 104 56 84Z',
        fill: CastInk.hair,
      ),
    ],
    clothes: [
      CastPath('M84 146 L100 178 L116 146Z', fill: CastInk.inner),
      CastPath(
        'M80 146 L100 184 L93 200 L70 200 L64 152Z',
        fill: CastInk.outerShade,
      ),
      CastPath(
        'M120 146 L100 184 L107 200 L130 200 L136 152Z',
        fill: CastInk.outerShade,
      ),
      CastPath('M100 184 L93 200 L107 200Z', fill: CastInk.outer),
    ],
    front: [
      CastPath(
        'M59 88 C56 58 72 39 101 39 C125 39 141 54 141.5 80 C134 64 121 54 106 51.5 '
        'C95 63 77 74 59 88Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M59.5 82 C58.5 102 61 118 66.5 128 L57 130 C54 112 55 96 59.5 82Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M74 50 C84 43.5 97 41.6 110 43.4 C98 44 86 47 76 53Z',
        fill: CastInk.hairHi,
        opacity: 0.55,
      ),
      CastCircle(140.5, 104, 4.6, stroke: CastInk.accent, strokeWidth: 2),
    ],
  );

  /// Marcus, the hiring manager: a close crop, a trimmed beard, rounded-rect glasses with
  /// near-clear lenses (so the eyes read), a navy suit, a honey tie.
  static const CastPerson marcus = CastPerson(
    id: 'marcus',
    name: 'Marcus',
    role: 'Hiring manager',
    palette: CastPalette(
      skin: Color(0xFF6F4532),
      shade: Color(0xFF573424),
      lip: Color(0xFFB9806C),
      blush: Color(0xFFB4574F),
      hair: Color(0xFF1B1412),
      hairHi: Color(0xFF3A2C27),
      brow: Color(0xFF1B1412),
      beard: Color(0xFF241A16),
      outer: Color(0xFF2B3A55),
      outerShade: Color(0xFF202C42),
      inner: Color(0xFFDCE8F6),
      accent: Color(0xFFE0A93B),
      frame: Color(0xFF14181F),
    ),
    back: [],
    clothes: [
      CastPath('M84 146 L100 174 L116 146Z', fill: CastInk.inner),
      CastPath(
        'M95.4 147.5 L104.6 147.5 L103.2 155 L96.8 155Z',
        fill: CastInk.accent,
      ),
      CastPath(
        'M96.6 155 L103.4 155 L106 184 L100 193 L94 184Z',
        fill: CastInk.accent,
      ),
      CastPath(
        'M81 146 L98 182 L91 200 L68 200 L63 152Z',
        fill: CastInk.outerShade,
      ),
      CastPath(
        'M119 146 L102 182 L109 200 L132 200 L137 152Z',
        fill: CastInk.outerShade,
      ),
    ],
    front: [
      CastPath(
        'M60.5 84 C58 54 76 38.5 100 38.5 C124 38.5 142 54 139.5 84 C137 70 131 58.5 119 53 '
        'C107 48.6 93 48.6 81 53 C69 58.5 63 70 60.5 84Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M63 97 C64.5 115 77 131.5 100 135.5 C123 131.5 135.5 115 137 97 C134 107 128.5 114 '
        '121 117.5 C115 112 107 110.5 100 111.5 C93 110.5 85 112 79 117.5 C71.5 114 66 107 '
        '63 97Z',
        fill: CastInk.beard,
      ),
      CastPath(
        'M88.5 112.6 Q100 106.4 111.5 112.6 Q100 110.2 88.5 112.6Z',
        fill: CastInk.beard,
      ),
      CastRect(
        73.5,
        78.5,
        21,
        15.5,
        radius: 5.5,
        fill: CastInk.white,
        fillOpacity: 0.06,
        stroke: CastInk.frame,
        strokeWidth: 2.3,
      ),
      CastRect(
        105.5,
        78.5,
        21,
        15.5,
        radius: 5.5,
        fill: CastInk.white,
        fillOpacity: 0.06,
        stroke: CastInk.frame,
        strokeWidth: 2.3,
      ),
      CastPath(
        'M94.5 84 Q100 81 105.5 84 M73.5 83.5 L61 82 M126.5 83.5 L139 82',
        stroke: CastInk.frame,
        strokeWidth: 2.3,
      ),
      CastPath(
        'M108.5 81.6 L112 80.6',
        stroke: CastInk.white,
        strokeWidth: 1.4,
        opacity: 0.55,
      ),
    ],
  );

  /// Lena, the senior engineer: an auburn bun, freckles, a mustard jumper, the Northstar
  /// lanyard and badge. Her skeptical "hmm" is her signature.
  static const CastPerson lena = CastPerson(
    id: 'lena',
    name: 'Lena',
    role: 'Senior engineer',
    palette: CastPalette(
      skin: Color(0xFFF1C9AA),
      shade: Color(0xFFDCA986),
      lip: Color(0xFFB5584B),
      blush: Color(0xFFEE8D86),
      hair: Color(0xFF9A4426),
      hairHi: Color(0xFFC2643E),
      brow: Color(0xFF7E3720),
      outer: Color(0xFFD9A23A),
      outerShade: Color(0xFFB9852A),
      inner: Color(0xFFC28A26),
      accent: Color(0xFF2C7D74),
      freckle: Color(0xFFC27E5E),
    ),
    back: [
      CastCircle(100, 31, 15.5, fill: CastInk.hair),
      CastPath(
        'M89 25 Q100 17 111 25 Q100 21.5 89 25Z',
        fill: CastInk.hairHi,
        opacity: 0.6,
      ),
    ],
    clothes: [
      CastPath(
        'M80 146 Q100 160 120 146',
        stroke: CastInk.inner,
        strokeWidth: 7,
      ),
      CastPath(
        'M62 156 L70 200 M138 156 L130 200',
        stroke: CastInk.outerShade,
        strokeWidth: 2.4,
        opacity: 0.7,
      ),
      CastPath('M88 152 L100 196', stroke: CastInk.accent, strokeWidth: 3),
      CastRect(
        94,
        181,
        16,
        12,
        radius: 2.5,
        rotation: -14,
        pivotX: 102,
        pivotY: 187,
        fill: CastInk.badge,
      ),
    ],
    front: [
      CastPath(
        'M60 84 C57.5 55 76 37.5 100 37.5 C124 37.5 142.5 55 140 84 C138 70 132 59 122 53.5 '
        'C112 49.5 104 51 100 55.5 C96 51 88 49.5 78 53.5 C68 59 62 70 60 84Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M100 55.5 C96 51 88 49.6 79 53.2 C88 51.8 95 53 100 55.5Z',
        fill: CastInk.hairHi,
        opacity: 0.5,
      ),
      CastPath(
        'M62.6 80 C60 94 62 106 66.6 115',
        stroke: CastInk.hair,
        strokeWidth: 2.6,
      ),
      CastCircle(79, 99, 1.1, fill: CastInk.freckle),
      CastCircle(84.5, 101.5, 1, fill: CastInk.freckle),
      CastCircle(76, 102.5, 1, fill: CastInk.freckle),
      CastCircle(121, 99, 1.1, fill: CastInk.freckle),
      CastCircle(115.5, 101.5, 1, fill: CastInk.freckle),
      CastCircle(124, 102.5, 1, fill: CastInk.freckle),
      CastCircle(59.8, 97, 1.8, fill: CastInk.stud),
      CastCircle(140.2, 97, 1.8, fill: CastInk.stud),
    ],
  );

  /// Sam, the head of product: salt-and-pepper swept hair, smile and eye lines, a plum
  /// turtleneck under a charcoal blazer. Waits on the top floor.
  static const CastPerson sam = CastPerson(
    id: 'sam',
    name: 'Sam',
    role: 'Head of product',
    palette: CastPalette(
      skin: Color(0xFFC99474),
      shade: Color(0xFFAA7353),
      lip: Color(0xFF8E4B3E),
      blush: Color(0xFFD27A6E),
      hair: Color(0xFF80858A),
      hairHi: Color(0xFFC2C6C9),
      brow: Color(0xFF5D6266),
      outer: Color(0xFF2D3437),
      outerShade: Color(0xFF22282A),
      inner: Color(0xFF7B2E45),
      accent: Color(0xFFC9A35B),
    ),
    back: [],
    clothes: [
      CastPath(
        'M82 132 L118 132 L121 154 Q100 161 79 154Z',
        fill: CastInk.inner,
      ),
      CastPath(
        'M84 140 Q100 145 116 140 M83 147 Q100 152 117 147',
        stroke: CastInk.rib,
        strokeWidth: 1.4,
        roundCap: false,
        opacity: 0.7,
      ),
      CastPath('M79 152 L94 200 L68 200 L62 154Z', fill: CastInk.outerShade),
      CastPath(
        'M121 152 L106 200 L132 200 L138 154Z',
        fill: CastInk.outerShade,
      ),
    ],
    front: [
      CastPath(
        'M60.5 86 C56 54 74 34 102 34 C128 34 145 50 139.5 84 C137 69 129 56 117 51 '
        'C106 47 94 47.5 85 51 C73 56 64 68 60.5 86Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M70 52 C80 36 104 29 126 38 C134 41 138 47 140 54 C130 44 114 40 98 42 '
        'C88 43.5 79 47 70 52Z',
        fill: CastInk.hair,
      ),
      CastPath(
        'M76 47.5 C88 39 106 36.5 122 41 M84 52 C96 46.5 110 45.5 124 48.5',
        stroke: CastInk.hairHi,
        strokeWidth: 1.7,
        opacity: 0.6,
      ),
      CastPath(
        'M126 89 L130.5 87.5 M126.2 92.4 L130.6 92.6',
        stroke: CastInk.shade,
        strokeWidth: 1.1,
      ),
      CastPath(
        'M74 89 L69.5 87.5 M73.8 92.4 L69.4 92.6',
        stroke: CastInk.shade,
        strokeWidth: 1.1,
      ),
      CastPath(
        'M88.6 108 Q86.6 113 88.4 117.6 M111.4 108 Q113.4 113 111.6 117.6',
        stroke: CastInk.shade,
        strokeWidth: 1.2,
        opacity: 0.8,
      ),
      CastCircle(140.4, 99, 1.6, fill: CastInk.accent),
    ],
  );

  /// Everyone, in the order they're met.
  static const List<CastPerson> all = [priya, marcus, lena, sam];

  /// The person with content id [id]; Priya for an unknown one.
  static CastPerson byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => priya);
}
