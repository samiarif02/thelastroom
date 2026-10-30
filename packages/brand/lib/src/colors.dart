import 'dart:ui' show Color;

/// Every colour the product uses: Morning Office (DESIGN.md "Chosen direction", owner's pick
/// 2026-10-30, brief 16). A sunny office at 9 a.m.: warm cream, white glass, plants, soft
/// colour. Widgets read these (or [ChapterGrade]); they never write a raw colour value
/// themselves (`check:standards` enforces it outside this package). Every text pair is
/// AA-tested in `test/contrast_test.dart`, text over colour included.
///
/// The ramp is a light one: [void_] is the lightest colour (the frame's far end: letterbox
/// bars, the hard-cut frame, what scrims fade to) and [textPrimary] the darkest, so a scrim
/// fading to [void_] always lies under legible text.
abstract final class BrandColors {
  /// The frame's far end: letterbox bars, the hard-cut frame, what scrims fade to.
  static const Color void_ = Color(0xFFFFFCF6);

  /// The default screen background: the cream wall.
  static const Color surface = Color(0xFFF8F1E4);

  /// Raised layers: answer cards, the desk, panels.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Hairlines, window frames, the far city.
  static const Color line = Color(0xFFE2D5BF);

  /// Primary text: warm charcoal, never pure black. 13.6:1 on the lowest surface.
  static const Color textPrimary = Color(0xFF2A2420);

  /// Secondary text: captions, places, recaps. 5.9:1 on the lowest surface.
  static const Color textSecondary = Color(0xFF665A50);

  /// The dossier and the candidate file: a crisp white sheet.
  static const Color paper = Color(0xFFFFFFFF);

  /// Typed text on the sheet. 15.3:1 on paper.
  static const Color ink = Color(0xFF2A2420);

  /// Field labels and rules on the sheet. 6.7:1 on paper.
  static const Color inkSoft = Color(0xFF665A50);

  /// The interviewer's pen: notes, stamps, the seal. 5.7:1 on paper.
  static const Color redPen = Color(0xFFB83A2A);

  /// The plant by the window, in shade. Decorative, never text.
  static const Color leaf = Color(0xFF5E9E73);

  /// The plant where the sun catches it. Decorative, never text.
  static const Color leafLit = Color(0xFF9CCB8F);

  /// Fully transparent, for gradients that fade to nothing.
  static const Color clear = Color(0x00000000);
}

/// The per-chapter colour grade (brief §9). The whole UI re-tints by swapping the grade, so
/// screens read the current grade rather than a fixed accent. The campaign climbs through
/// saturation and warmth, never darkness: leaf green for the welcome, sky blue for the
/// pressure, raspberry for the final round.
enum ChapterGrade {
  /// Chapter 1, Get Through the Door: leaf green in butter sunlight. Key 5.1:1.
  lobby(label: 'Lobby', key: lobbyKey, shadow: lobbyShadow, tint: lobbyTint),

  /// Chapter 2, Under Pressure: sky blue. Key 6.0:1.
  pressure(
    label: 'Pressure',
    key: pressureKey,
    shadow: pressureShadow,
    tint: pressureTint,
  ),

  /// Chapter 3, The Final Round: raspberry. Key 5.7:1.
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

  // The raw values, public so const tables (and the type ramp's default accent) can use them.
  static const Color lobbyKey = Color(0xFF2C7356);
  static const Color lobbyShadow = Color(0xFFE9F2EA);
  static const Color lobbyTint = Color(0xFFFFE7AE);
  static const Color pressureKey = Color(0xFF2D5C9E);
  static const Color pressureShadow = Color(0xFFE6EDF7);
  static const Color pressureTint = Color(0xFFD4E3F8);
  static const Color finalRoundKey = Color(0xFFA8344A);
  static const Color finalRoundShadow = Color(0xFFF9E7E8);
  static const Color finalRoundTint = Color(0xFFFAD3C8);

  /// The grade's name, for the catalog and debug overlays.
  final String label;

  /// The accent: the speaker's name, rules, numerals, the mug. Legible as small text on every
  /// surface.
  final Color key;

  /// The colour the vignette falls to, and the sky in the glass.
  final Color shadow;

  /// A second colour laid into the light: the sun, a card's warmth.
  final Color tint;
}
