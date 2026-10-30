import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// One interviewer's colours as an illustrated person (brief 16): skin and its shade, hair,
/// clothes. Decorative fills, never text, so no contrast pairs; they stay the same in every
/// look (a person doesn't change colour with the set), only the light on them does.
@immutable
class CastColors {
  const CastColors({
    required this.skin,
    required this.skinShade,
    required this.hair,
    required this.outer,
    required this.inner,
    required this.accent,
  });

  final Color skin;

  /// Under the chin, the ears, the neck.
  final Color skinShade;
  final Color hair;

  /// Jacket, cardigan or jumper.
  final Color outer;

  /// The shirt or top under it.
  final Color inner;

  /// A tie, earrings, glasses frames.
  final Color accent;
}

/// The cast, by role. Respectful, specific, no caricature: each is told apart by hair, skin
/// tone, clothes and one accessory.
abstract final class BrandCast {
  /// Priya, the recruiter: a sharp black bob, warm brown skin, a teal blazer, gold hoops.
  static const CastColors priya = CastColors(
    skin: Color(0xFFB97A56),
    skinShade: Color(0xFF9A603F),
    hair: Color(0xFF2A1C18),
    outer: Color(0xFF2F7472),
    inner: Color(0xFFF5E8D6),
    accent: Color(0xFFE0A93B),
  );

  /// Marcus, the hiring manager: close-cropped hair and a trimmed beard, deep brown skin,
  /// glasses, a charcoal jacket and a navy tie.
  static const CastColors marcus = CastColors(
    skin: Color(0xFF6E4532),
    skinShade: Color(0xFF573525),
    hair: Color(0xFF1D1614),
    outer: Color(0xFF4A5060),
    inner: Color(0xFFD3E2F2),
    accent: Color(0xFF2B3D66),
  );

  /// Lena, the senior engineer: auburn hair in a bun, fair freckled skin, a mustard jumper.
  static const CastColors lena = CastColors(
    skin: Color(0xFFF0C6A6),
    skinShade: Color(0xFFD9A585),
    hair: Color(0xFF9A4A2A),
    outer: Color(0xFFD7A13D),
    inner: Color(0xFFB98425),
    accent: Color(0xFF6B4A3A),
  );

  /// Eyes, brows, lashes: the darkest line on a face.
  static const Color feature = Color(0xFF2A1E1A);

  /// The inside of a smiling mouth.
  static const Color mouth = Color(0xFF7A2E2A);

  /// Cheeks when someone smiles.
  static const Color blush = Color(0xFFE5767A);

  /// The whites of the eyes, a glint on a lens.
  static const Color highlight = Color(0xFFFFFBF4);
}
