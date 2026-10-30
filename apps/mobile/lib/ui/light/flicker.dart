import 'dart:math' as math;

/// A tungsten lamp's flicker at [seconds]: 1 is full light, dipping to about 0.9. Three
/// unrelated sines, so it never visibly repeats. The lamp, its pool and the rim light on a
/// silhouette all read this, so they flicker together.
double lampFlicker(double seconds) {
  final wobble =
      math.sin(seconds * 2.1) * 0.5 +
      math.sin(seconds * 5.3 + 1.7) * 0.3 +
      math.sin(seconds * 13.7 + 0.4) * 0.2;
  // The rare dip: a brownout lasting a fraction of a second every few seconds.
  final dip = math.max(0, math.sin(seconds * 0.9 + 2.2) - _dipThreshold) * 4;
  return (1 - _depth * (0.5 + 0.5 * wobble) - dip * _depth).clamp(0.82, 1);
}

const double _depth = 0.05;
const double _dipThreshold = 0.97;
