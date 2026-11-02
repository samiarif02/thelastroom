import 'dart:math' as math;

/// The cast's idle and gestures as pure functions of time (direction.md, "Idle"), so a test can
/// check any instant and a still frame (reduced motion stops the clock at 0) is never caught
/// mid-blink.
abstract final class CastIdle {
  /// A breath: the figure scales 1.0 → 1.01 and back over this many seconds.
  static const double breathPeriod = 4;
  static const double breathDepth = 0.01;

  /// A sway of ±[swayDegrees] over this many seconds.
  static const double swayPeriod = 9;
  static const double swayDegrees = 1;

  /// Blinks land once per [blinkCycle] seconds, somewhere in a [blinkWindow]-wide slot that
  /// starts [blinkFrom] into it, so consecutive blinks are 4–6 s apart and never metronomic.
  static const double blinkCycle = 5;
  static const double blinkFrom = 1.5;
  static const double blinkWindow = 1;

  /// A blink lasts 120 ms.
  static const double blinkLength = 0.12;

  /// How far the head dips in a nod, in grid units (4 px at the sheet's size).
  static const double nodDepth = 4;

  /// Syllables per second while a line types out.
  static const double syllables = 4;

  /// How far the mouth closes between syllables (its height's share at the closed point).
  static const double flapClosed = 0.35;

  /// The figure's scale at [seconds]: 1 at rest, 1 + [breathDepth] at the top of the breath.
  static double breath(double seconds) =>
      1 +
      breathDepth / 2 * (1 - math.cos(seconds * 2 * math.pi / breathPeriod));

  /// The sway in degrees at [seconds].
  static double sway(double seconds) =>
      swayDegrees * math.sin(seconds * 2 * math.pi / swayPeriod);

  /// How open the eyes are at [seconds]: 1 open, 0 shut. Open at 0.
  static double blink(double seconds) {
    final cycle = (seconds / blinkCycle).floor();
    final at = cycle * blinkCycle + blinkFrom + blinkWindow * jitter(cycle);
    final into = seconds - at;
    if (into < 0 || into > blinkLength) return 1;
    return 1 - math.sin(into / blinkLength * math.pi);
  }

  /// How far the head has dipped at [progress] (0…1) through a nod: down and back.
  static double nodDip(double progress) {
    if (progress <= 0 || progress >= 1) return 0;
    return nodDepth * math.sin(progress * math.pi);
  }

  /// How open the talking mouth is at [seconds]: between [flapClosed] and 1, a syllable at a
  /// time.
  static double flap(double seconds) =>
      flapClosed +
      (1 - flapClosed) * math.sin(seconds * syllables * math.pi).abs();

  /// A repeatable 0…1 for each blink cycle.
  static double jitter(int cycle) {
    final x = math.sin(cycle * 12.9898 + 4.1414) * 43758.5453;
    return x - x.floorToDouble();
  }
}
