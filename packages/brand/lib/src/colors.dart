import 'dart:ui' show Color;

/// Every colour the product uses: The Boardroom (DESIGN.md "Chosen direction"). Old money after
/// hours: walnut, brass, tungsten lamps and a city out of focus. Widgets read these (or
/// [ChapterGrade]); they never write a raw colour value themselves (`check:standards` enforces
/// it outside this package). Every text pair is AA-tested in `test/contrast_test.dart`.
abstract final class BrandColors {
  /// The darkest layer: letterbox bars, the night beyond the glass, the hard-cut frame.
  static const Color void_ = Color(0xFF0C0806);

  /// The default screen background: the room with the lamp off.
  static const Color surface = Color(0xFF140E0B);

  /// Raised layers: walnut panels, the desk, answer plaques.
  static const Color surfaceRaised = Color(0xFF1F1712);

  /// Hairlines, walnut grain and window mullions.
  static const Color line = Color(0xFF3A2D24);

  /// Primary text: warm cream, never pure white (it glares on near-black). 14.4:1 on surface.
  static const Color textPrimary = Color(0xFFF3E7D3);

  /// Secondary text: captions, places, the unlit numerals. 7.7:1 on surface.
  static const Color textSecondary = Color(0xFFBBA990);

  /// The dossier's heavy cream letterhead.
  static const Color paper = Color(0xFFF1E7D3);

  /// Typed text on the letterhead. 13.2:1 on paper.
  static const Color ink = Color(0xFF2A1E16);

  /// Field labels and rules on the letterhead. 6.1:1 on paper.
  static const Color inkSoft = Color(0xFF65513F);

  /// Fountain-pen red: the interviewer's note, stamps, the wax seal. 6.2:1 on paper. On the dark
  /// surfaces it is a fill (the seal), never text.
  static const Color redPen = Color(0xFFA3201B);

  /// The banker's lamp's green glass shade, unlit side. Decorative, never text.
  static const Color lampGlass = Color(0xFF1E3A2B);

  /// The same glass where the bulb shines through it. Decorative, never text.
  static const Color lampGlassLit = Color(0xFF5E8F6A);

  /// Fully transparent, for gradients that fade to nothing.
  static const Color clear = Color(0x00000000);
}

/// The per-chapter colour grade (brief §9). The whole UI re-tints by swapping the grade, so
/// screens read the current grade rather than a fixed accent. The campaign climbs: amber lobby,
/// steel pressure, then brass on oxblood, which *is* the last room.
enum ChapterGrade {
  /// Chapter 1, Get Through the Door: warm amber lobby. Key 8.8:1 on surface.
  lobby(label: 'Lobby', key: lobbyKey, shadow: lobbyShadow, tint: lobbyTint),

  /// Chapter 2, Under Pressure: cold steel blue. Key 8.2:1 on surface.
  pressure(
    label: 'Pressure',
    key: pressureKey,
    shadow: pressureShadow,
    tint: pressureTint,
  ),

  /// Chapter 3, The Final Round: brass on oxblood. Key 8.3:1 on surface.
  finalRound(
    label: 'Final round',
    key: finalRoundKey,
    shadow: finalRoundShadow,
    tint: finalRoundTint,
  );

  const ChapterGrade({
    required this.label,
    required this.key,
    required this.shadow,
    required this.tint,
  });

  // The raw values, public so const tables (and the type ramp's default brass) can use them.
  static const Color lobbyKey = Color(0xFFE2AE62);
  static const Color lobbyShadow = Color(0xFF1B1009);
  static const Color lobbyTint = Color(0xFF5A3518);
  static const Color pressureKey = Color(0xFF9DB4C8);
  static const Color pressureShadow = Color(0xFF0D1218);
  static const Color pressureTint = Color(0xFF2A3644);
  static const Color finalRoundKey = Color(0xFFCFAE5E);
  static const Color finalRoundShadow = Color(0xFF22080B);
  static const Color finalRoundTint = Color(0xFF6E1A20);

  /// The grade's name, for the catalog and debug overlays.
  final String label;

  /// The light in the scene: brass, the lamp, the speaker's name, accents. Legible as small
  /// text on every dark surface.
  final Color key;

  /// The colour shadows fall to, under the vignette.
  final Color shadow;

  /// A second colour laid into the light: lamp haze, bokeh, the oxblood in Chapter 3.
  final Color tint;
}
