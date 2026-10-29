import 'package:flutter/animation.dart';

/// The progress of one cue inside a 0–1 timeline: 0 before [begin], 1 after [end], eased in
/// between. Frames are choreographed as overlapping cues on one clock, like a cue sheet.
double cue(double t, double begin, double end, [Curve curve = Curves.linear]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

/// Linear interpolation between two doubles.
double mix(double a, double b, double t) => a + (b - a) * t;
