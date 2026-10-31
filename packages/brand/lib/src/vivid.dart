import 'dart:ui' show Color, Offset;

import 'package:flutter/painting.dart' show BoxShadow;

import 'colors.dart';

/// The vivid layer (brief 17): the home screens (the tower, onboarding, progress) on rich
/// full-bleed colour with depth, instead of white with grey. Morning Office (`BrandColors`)
/// stays the room's palette (the mission scene, the dossier); this is the building around it:
/// an evening sky over the city, chapter cards in strong colour, one sunflower accent for the
/// action that matters.
///
/// Text rules, AA-tested in `test/vivid_contrast_test.dart`:
/// - On the sky and on any chapter card: [onDeep] and [onDeepSoft].
/// - A grade's [ChapterVivid.glow] and the [accent] as text: only on the sky or on a grade's
///   [ChapterVivid.deeper] (they fall short on the lighter [ChapterVivid.deep]).
/// - On the accent: [onAccent].
abstract final class BrandVivid {
  /// The top of the sky behind the tower: deep navy.
  static const Color skyTop = Color(0xFF0B1E33);

  /// The middle of the sky: evening teal-blue.
  static const Color skyMid = Color(0xFF15405A);

  /// Low in the sky, over the city: teal.
  static const Color skyLow = Color(0xFF1A5258);

  /// The sun below the horizon: a warm glow at the very bottom. Decorative, never under text.
  static const Color horizon = Color(0xFFF2994A);

  /// The darkest ground: the header band, sheets, the elevator.
  static const Color night = Color(0xFF0A1626);

  /// A locked card: slate, so a chapter's own colour reads as the reward for opening it.
  static const Color locked = Color(0xFF24364A);

  /// Primary text on the sky and on every card. 6.1:1 on the lightest card.
  static const Color onDeep = Color(0xFFFFFFFF);

  /// Secondary text on the sky and every card: never mid-grey. 5.2:1 on the lightest card.
  static const Color onDeepSoft = Color(0xFFE3EEF3);

  /// The one confident accent: the Play button, stars, the current mission's ring.
  static const Color accent = Color(0xFFFFC23D);

  /// The accent pressed.
  static const Color accentPressed = Color(0xFFF2A900);

  /// Text and the play glyph on the accent. 10.4:1.
  static const Color onAccent = Color(0xFF2B1B00);

  /// The sky, top to bottom, for a full-bleed [LinearGradient].
  static const List<Color> sky = [skyTop, skyMid, skyLow];

  /// A card lifted off the sky: a soft, deep shadow below it.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: _shadow, blurRadius: 24, offset: Offset(0, 12)),
  ];

  /// The hero card and the Play button: lifted higher, and lit by the accent.
  static List<BoxShadow> glowShadow(Color glow) => [
    const BoxShadow(color: _shadow, blurRadius: 30, offset: Offset(0, 16)),
    BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 28),
  ];

  /// Hairlines on colour: white at a low alpha, so they take the card's hue.
  static Color hairline([double alpha = 0.18]) =>
      onDeep.withValues(alpha: alpha);

  static const Color _shadow = Color(0x59000000);
}

/// Each chapter's own strong colour (brief 17): Chapter 1 a welcoming emerald, Chapter 2 a
/// pressured royal blue, Chapter 3 the final round's raspberry. [ChapterGrade.key] stays the
/// accent inside the room; these are the chapter on the building.
extension ChapterVivid on ChapterGrade {
  /// The card's lit side (top left).
  Color get deep => switch (this) {
    ChapterGrade.lobby => const Color(0xFF137049),
    ChapterGrade.pressure => const Color(0xFF2C50B0),
    ChapterGrade.finalRound => const Color(0xFFA62B55),
  };

  /// The card's shaded side (bottom right), and the ground glow text may sit on.
  Color get deeper => switch (this) {
    ChapterGrade.lobby => const Color(0xFF0B4532),
    ChapterGrade.pressure => const Color(0xFF172C6E),
    ChapterGrade.finalRound => const Color(0xFF5A1230),
  };

  /// The chapter's light: progress rings, numerals, small caps on [deeper] or the sky.
  Color get glow => switch (this) {
    ChapterGrade.lobby => const Color(0xFF9BF2C6),
    ChapterGrade.pressure => const Color(0xFFA9CEFF),
    ChapterGrade.finalRound => const Color(0xFFFFB0C8),
  };

  /// The card's fill, lit side to shaded side.
  List<Color> get cardGradient => [deep, deeper];
}
