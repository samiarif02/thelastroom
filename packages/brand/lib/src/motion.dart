import 'package:flutter/animation.dart';

/// Motion tokens. Every animation picks one of these, so timing stays consistent and reduced
/// motion has one place to act. The Boardroom moves like money: slow, weighty glides that ease
/// out with no overshoot, nothing bouncy (DESIGN.md "Motion principles").
abstract final class BrandMotion {
  /// Taps, toggles, small state changes.
  static const Duration quick = Duration(milliseconds: 180);

  /// Cross-fades and most transitions.
  static const Duration standard = Duration(milliseconds: 420);

  /// Short cinematic moves: a card arriving, a plaque lighting up.
  static const Duration cinematic = Duration(milliseconds: 900);

  /// Letterbox bars sliding in or out.
  static const Duration letterbox = Duration(milliseconds: 1100);

  /// The default camera cut: the dolly push with parallax, wide to close-up.
  static const Duration dolly = Duration(milliseconds: 2200);

  /// The follow-up's hard cut: one black frame at film rate (1/24 s), so pressure reads as an
  /// edit, not a fade.
  static const Duration hardCut = Duration(microseconds: 41667);

  /// Typewriter speed, per character.
  static const Duration perCharacter = Duration(milliseconds: 30);

  /// The elevator between missions (brief §9: about 1.2 s, skippable).
  static const Duration elevator = Duration(milliseconds: 1200);

  /// The whole chapter title card: lamp, brass frame, title tracking in, subtitle.
  static const Duration titleCard = Duration(milliseconds: 4600);

  /// The dossier sliding across the desk into the lamp's pool.
  static const Duration dossierSlide = Duration(milliseconds: 1300);

  /// The whole dossier sequence: slide, four stamps, the seal, the pen.
  static const Duration dossier = Duration(milliseconds: 4600);

  /// A stamp or seal dropping onto the paper.
  static const Duration stamp = Duration(milliseconds: 320);

  /// The fountain pen writing its note.
  static const Duration pen = Duration(milliseconds: 1100);

  /// Entering elements decelerate into place.
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);

  /// Leaving elements accelerate away.
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);

  /// Short camera moves: slow in, slow out, with weight.
  static const Curve camera = Cubic(0.65, 0, 0.35, 1);

  /// The dolly push and the title's tracking-in: a long, weighted glide.
  static const Curve dollyCurve = Cubic(0.55, 0, 0.25, 1);

  /// Letterbox bars.
  static const Curve letterboxCurve = Cubic(0.6, 0, 0.2, 1);

  /// Paper sliding on walnut: fast off the hand, a long settle.
  static const Curve paperSlide = Cubic(0.3, 0.8, 0.2, 1);

  /// Under reduced motion every camera move becomes a cross-fade of this length.
  static const Duration reducedMotionFade = Duration(milliseconds: 200);
}

/// Film stock: how much grain and vignette lie over every frame (brief §9: very subtle).
abstract final class BrandFilm {
  /// Grain opacity, 0–1. Medium grain for the Boardroom.
  static const double grain = 0.09;

  /// How far the vignette reaches in, 0–1.
  static const double vignette = 0.65;

  /// Grain changes at film rate; faster reads as video noise.
  static const double frameRate = 24;
}
