import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show BoxShadow;

import 'colors.dart';

/// One chapter's colours on the building: the card's lit side, its shaded side, and its light.
@immutable
class ChapterColours {
  const ChapterColours({
    required this.deep,
    required this.deeper,
    required this.glow,
  });

  final Color deep;
  final Color deeper;
  final Color glow;
}

/// A complete vivid look (brief 28): the sky, the grounds, the text, the one accent, and the
/// three chapters' colours. Every theme keeps the same text rules (below), AA-tested for every
/// theme in `test/vivid_contrast_test.dart`.
@immutable
class VividPalette {
  const VividPalette({
    required this.id,
    required this.name,
    required this.mood,
    required this.skyTop,
    required this.skyMid,
    required this.skyLow,
    required this.horizon,
    required this.night,
    required this.locked,
    required this.onDeep,
    required this.onDeepSoft,
    required this.accent,
    required this.accentPressed,
    required this.onAccent,
    required this.lobby,
    required this.pressure,
    required this.finalRound,
  });

  /// Stable, for saving the player's pick.
  final String id;
  final String name;

  /// One line for the picker.
  final String mood;

  final Color skyTop;
  final Color skyMid;
  final Color skyLow;
  final Color horizon;
  final Color night;
  final Color locked;
  final Color onDeep;
  final Color onDeepSoft;
  final Color accent;
  final Color accentPressed;
  final Color onAccent;
  final ChapterColours lobby;
  final ChapterColours pressure;
  final ChapterColours finalRound;

  ChapterColours chapter(ChapterGrade grade) => switch (grade) {
    ChapterGrade.lobby => lobby,
    ChapterGrade.pressure => pressure,
    ChapterGrade.finalRound => finalRound,
  };
}

/// The themes the player can pick (brief 28). Each climbs in tension chapter by chapter.
abstract final class VividThemes {
  /// The default (brief 17): an evening sky over the city; emerald, royal blue, raspberry;
  /// sunflower.
  static const VividPalette eveningForest = VividPalette(
    id: 'evening-forest',
    name: 'Evening Forest',
    mood: 'An evening sky over the city, emerald to raspberry.',
    skyTop: Color(0xFF0B1E33),
    skyMid: Color(0xFF15405A),
    skyLow: Color(0xFF1A5258),
    horizon: Color(0xFFF2994A),
    night: Color(0xFF0A1626),
    locked: Color(0xFF24364A),
    onDeep: Color(0xFFFFFFFF),
    onDeepSoft: Color(0xFFE3EEF3),
    accent: Color(0xFFFFC23D),
    accentPressed: Color(0xFFF2A900),
    onAccent: Color(0xFF2B1B00),
    lobby: ChapterColours(
      deep: Color(0xFF137049),
      deeper: Color(0xFF0B4532),
      glow: Color(0xFF9BF2C6),
    ),
    pressure: ChapterColours(
      deep: Color(0xFF2C50B0),
      deeper: Color(0xFF172C6E),
      glow: Color(0xFFA9CEFF),
    ),
    finalRound: ChapterColours(
      deep: Color(0xFFA62B55),
      deeper: Color(0xFF5A1230),
      glow: Color(0xFFFFB0C8),
    ),
  );

  /// Golden hour on a high floor: plum to dusky rose; coral, violet, bronze; gold.
  static const VividPalette sunsetCity = VividPalette(
    id: 'sunset-city',
    name: 'Sunset City',
    mood: 'Golden hour on a high floor, coral to bronze.',
    skyTop: Color(0xFF24102F),
    skyMid: Color(0xFF45204F),
    skyLow: Color(0xFF6A2848),
    horizon: Color(0xFFFF8A5B),
    night: Color(0xFF1A0A24),
    locked: Color(0xFF3A2446),
    onDeep: Color(0xFFFFFFFF),
    onDeepSoft: Color(0xFFF6E6EE),
    accent: Color(0xFFFFC857),
    accentPressed: Color(0xFFF0A92E),
    onAccent: Color(0xFF2B1600),
    lobby: ChapterColours(
      deep: Color(0xFFB2384A),
      deeper: Color(0xFF5E1626),
      glow: Color(0xFFFFB8AA),
    ),
    pressure: ChapterColours(
      deep: Color(0xFF6A35B0),
      deeper: Color(0xFF331460),
      glow: Color(0xFFD7BEFF),
    ),
    finalRound: ChapterColours(
      deep: Color(0xFF9A5410),
      deeper: Color(0xFF4A2706),
      glow: Color(0xFFFFD98A),
    ),
  );

  /// Deep water at night: navy to sea; teal, cobalt, magenta; aqua.
  static const VividPalette oceanNight = VividPalette(
    id: 'ocean-night',
    name: 'Ocean Night',
    mood: 'Deep water at night, teal to magenta.',
    skyTop: Color(0xFF04172A),
    skyMid: Color(0xFF0A3150),
    skyLow: Color(0xFF0C4559),
    horizon: Color(0xFF2EC4B6),
    night: Color(0xFF03101E),
    locked: Color(0xFF15304A),
    onDeep: Color(0xFFFFFFFF),
    onDeepSoft: Color(0xFFDDF3F6),
    accent: Color(0xFF4FE3D3),
    accentPressed: Color(0xFF2CC7B6),
    onAccent: Color(0xFF00262A),
    lobby: ChapterColours(
      deep: Color(0xFF0E7066),
      deeper: Color(0xFF063B37),
      glow: Color(0xFF7FF5E8),
    ),
    pressure: ChapterColours(
      deep: Color(0xFF1E4FC9),
      deeper: Color(0xFF0B2470),
      glow: Color(0xFFA6C8FF),
    ),
    finalRound: ChapterColours(
      deep: Color(0xFFA0174F),
      deeper: Color(0xFF4C0624),
      glow: Color(0xFFFFA6C9),
    ),
  );

  /// A bright morning: cobalt sky; green, orange, crimson; sunshine. Bright, never white.
  static const VividPalette morningLight = VividPalette(
    id: 'morning-light',
    name: 'Morning Light',
    mood: 'A bright cobalt morning, green to crimson.',
    skyTop: Color(0xFF1A45A8),
    skyMid: Color(0xFF1E50B6),
    skyLow: Color(0xFF2155B5),
    horizon: Color(0xFFFFB547),
    night: Color(0xFF10307A),
    locked: Color(0xFF35548F),
    onDeep: Color(0xFFFFFFFF),
    onDeepSoft: Color(0xFFEEF4FF),
    accent: Color(0xFFFFD24A),
    accentPressed: Color(0xFFF5B90F),
    onAccent: Color(0xFF2B1B00),
    lobby: ChapterColours(
      deep: Color(0xFF15803D),
      deeper: Color(0xFF0B4D24),
      glow: Color(0xFFB2F5C8),
    ),
    pressure: ChapterColours(
      deep: Color(0xFFC2410C),
      deeper: Color(0xFF6B2206),
      glow: Color(0xFFFFD0AD),
    ),
    finalRound: ChapterColours(
      deep: Color(0xFFB91C4A),
      deeper: Color(0xFF5E0B24),
      glow: Color(0xFFFFCCD9),
    ),
  );

  static const List<VividPalette> all = [
    eveningForest,
    sunsetCity,
    oceanNight,
    morningLight,
  ];

  /// The theme with [id]; the default for an unknown or missing one.
  static VividPalette byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => eveningForest);
}

/// The vivid layer (brief 17; themes in brief 28): the home screens on rich full-bleed colour
/// with depth. Morning Office (`BrandColors`) stays the room's palette (the mission scene, the
/// dossier); this is the building around it. Every token reads the [current] theme, so a pick
/// in Settings re-colours every screen on its next build (the app rebuilds on a change).
///
/// Text rules, AA-tested for every theme in `test/vivid_contrast_test.dart`:
/// - On the sky and on any chapter card: [onDeep] and [onDeepSoft].
/// - A grade's [ChapterVivid.glow] and the [accent] as text: only on the sky or on a grade's
///   [ChapterVivid.deeper] (they fall short on the lighter [ChapterVivid.deep]).
/// - On the accent: [onAccent].
abstract final class BrandVivid {
  /// The theme every token reads. Set by the app from the player's pick (never mid-frame).
  static VividPalette current = VividThemes.eveningForest;

  /// The top of the sky behind the tower.
  static Color get skyTop => current.skyTop;

  /// The middle of the sky.
  static Color get skyMid => current.skyMid;

  /// Low in the sky, over the city.
  static Color get skyLow => current.skyLow;

  /// The sun below the horizon: a warm glow at the very bottom. Decorative, never under text.
  static Color get horizon => current.horizon;

  /// The darkest ground: the header band, sheets, the elevator.
  static Color get night => current.night;

  /// A locked card: a quiet slate, so a chapter's own colour reads as the reward for opening it.
  static Color get locked => current.locked;

  /// Primary text on the sky and on every card.
  static Color get onDeep => current.onDeep;

  /// Secondary text on the sky and every card: never mid-grey.
  static Color get onDeepSoft => current.onDeepSoft;

  /// The one confident accent: the Play button, stars, the current mission's ring.
  static Color get accent => current.accent;

  /// The accent pressed.
  static Color get accentPressed => current.accentPressed;

  /// Text and the play glyph on the accent.
  static Color get onAccent => current.onAccent;

  /// The sky, top to bottom, for a full-bleed `LinearGradient`.
  static List<Color> get sky => [skyTop, skyMid, skyLow];

  /// A card lifted off the sky: a soft, deep shadow below it.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: _shadow, blurRadius: 24, offset: Offset(0, 12)),
  ];

  /// The hero card and the Play button: lifted higher, and lit by [glow].
  static List<BoxShadow> glowShadow(Color glow) => [
    const BoxShadow(color: _shadow, blurRadius: 30, offset: Offset(0, 16)),
    BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 28),
  ];

  /// Hairlines on colour: the text colour at a low alpha, so they take the card's hue.
  static Color hairline([double alpha = 0.18]) =>
      onDeep.withValues(alpha: alpha);

  static const Color _shadow = Color(0x59000000);
}

/// Each chapter's own strong colour in the current theme (brief 17/28). [ChapterGrade.key] stays
/// the accent inside the room; these are the chapter on the building.
extension ChapterVivid on ChapterGrade {
  /// The card's lit side (top left).
  Color get deep => BrandVivid.current.chapter(this).deep;

  /// The card's shaded side (bottom right), and the ground glow text may sit on.
  Color get deeper => BrandVivid.current.chapter(this).deeper;

  /// The chapter's light: progress rings, numerals, small caps on [deeper] or the sky.
  Color get glow => BrandVivid.current.chapter(this).glow;

  /// The card's fill, lit side to shaded side.
  List<Color> get cardGradient => [deep, deeper];
}
