import 'dart:ui' show Color;

/// Every colour the product uses. Widgets read these (or [ChapterGrade]); they never write a
/// raw colour value themselves (`check:standards` enforces it outside this package).
///
/// PROVISIONAL: the values follow the brief's direction (near-black and charcoal surfaces, warm
/// off-white text, one spotlight-amber accent) and are replaced in the design session
/// (DESIGN.md). Keep the names; change the values.
abstract final class BrandColors {
  /// The darkest layer: letterbox bars, the night sky behind the tower.
  static const Color void_ = Color(0xFF07070A);

  /// The default screen background.
  static const Color surface = Color(0xFF0E0E12);

  /// Raised layers: the dossier, choice cards, sheets.
  static const Color surfaceRaised = Color(0xFF17171D);

  /// Hairlines and dividers.
  static const Color line = Color(0xFF2A2A33);

  /// Primary text: warm off-white, never pure white (it glares on near-black).
  static const Color textPrimary = Color(0xFFF2EBDD);

  /// Secondary text: captions, the speaker's name in subtitles.
  static const Color textSecondary = Color(0xFFB4AC9E);

  /// The one hero accent: the spotlight.
  static const Color spotlight = Color(0xFFE9A94B);

  /// Red-pen notes on the dossier, and errors.
  static const Color redPen = Color(0xFFD9534A);

  /// Fully transparent, for gradients that fade to nothing.
  static const Color clear = Color(0x00000000);
}

/// The per-chapter colour grade (brief §9). The whole UI re-tints by swapping the grade, so
/// screens read `ChapterGrade.of(context)`-style values rather than a fixed accent.
enum ChapterGrade {
  /// Chapter 1, Get Through the Door: warm amber lobby.
  lobby(
    key: Color(0xFFE9A94B),
    shadow: Color(0xFF1A120A),
    tint: Color(0x1FE9A94B),
  ),

  /// Chapter 2, Under Pressure: cold steel blue.
  pressure(
    key: Color(0xFF7FA3C7),
    shadow: Color(0xFF0A1018),
    tint: Color(0x1F7FA3C7),
  ),

  /// Chapter 3, The Final Round: deep oxblood and gold.
  finalRound(
    key: Color(0xFFC9A44C),
    shadow: Color(0xFF1C0709),
    tint: Color(0x1F8E2A2E),
  );

  const ChapterGrade({
    required this.key,
    required this.shadow,
    required this.tint,
  });

  /// The light in the scene: spotlight, active floor, accents.
  final Color key;

  /// The colour shadows fall to, under the vignette.
  final Color shadow;

  /// A translucent wash laid over the whole scene.
  final Color tint;
}
