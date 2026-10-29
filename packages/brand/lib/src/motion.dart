import 'package:flutter/animation.dart';

/// Motion tokens. Every animation picks one of these, so timing stays consistent and reduced
/// motion has one place to act. Curves are eased and weighty (brief §9): no bouncy springs.
abstract final class BrandMotion {
  /// Taps, toggles, small state changes.
  static const Duration quick = Duration(milliseconds: 180);

  /// Cross-fades and most transitions.
  static const Duration standard = Duration(milliseconds: 420);

  /// Camera cuts and letterbox bars.
  static const Duration cinematic = Duration(milliseconds: 900);

  /// The elevator between missions (brief §9: about 1.2 s, skippable).
  static const Duration elevator = Duration(milliseconds: 1200);

  /// Chapter title cards: slow fade and tracking-in.
  static const Duration titleCard = Duration(milliseconds: 2400);

  /// Entering elements decelerate into place.
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);

  /// Leaving elements accelerate away.
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);

  /// Camera moves: slow in, slow out, with weight.
  static const Curve camera = Cubic(0.65, 0, 0.35, 1);

  /// Under reduced motion every camera move becomes a cross-fade of this length.
  static const Duration reducedMotionFade = Duration(milliseconds: 200);
}
