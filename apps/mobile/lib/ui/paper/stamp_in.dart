import 'package:flutter/widgets.dart';

import '../film/cue.dart';

/// A rubber stamp landing: it drops from above the paper (big, faint) and hits (full size, full
/// ink) with a slight over-press. [t] is 0 before the stamp, 1 once it has landed; it hits at
/// [hitAt].
class StampIn extends StatelessWidget {
  const StampIn({
    super.key,
    required this.t,
    required this.child,
    this.angle = 0,
  });

  /// The share of [t] at which the stamp touches the paper (when to thud).
  static const double hitAt = 0.72;

  final double t;

  /// The angle it lands at, in radians. Real stamps are never straight.
  final double angle;
  final Widget child;

  static const double _dropScale = 1.9;
  static const double _overPress = 0.94;
  static const double _inkedBy = hitAt * 0.6;

  @override
  Widget build(BuildContext context) {
    if (t <= 0) return Opacity(opacity: 0, child: child);
    final fall = cue(t, 0, hitAt, Curves.easeInCubic);
    final settle = cue(t, hitAt, 1, Curves.easeOutCubic);
    final scale = t < hitAt
        ? mix(_dropScale, _overPress, fall)
        : mix(_overPress, 1, settle);
    return Opacity(
      opacity: cue(t, 0, _inkedBy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}
