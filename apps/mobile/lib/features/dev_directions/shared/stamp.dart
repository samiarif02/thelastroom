import 'package:flutter/widgets.dart';

import 'cue.dart';

/// A rubber stamp landing: it drops from above the paper (big, faint) and hits (full size, full
/// ink), with a slight over-press. [t] is 0 before the stamp, 1 once it has landed.
class StampIn extends StatelessWidget {
  const StampIn({
    super.key,
    required this.t,
    required this.child,
    this.angle = 0,
  });

  final double t;

  /// The angle it lands at, in radians. Real stamps are never straight.
  final double angle;
  final Widget child;

  static const double _dropScale = 1.9;
  static const double _hit = 0.72;
  static const double _overPress = 0.94;

  @override
  Widget build(BuildContext context) {
    if (t <= 0) return Opacity(opacity: 0, child: child);
    final fall = cue(t, 0, _hit, Curves.easeInCubic);
    final settle = cue(t, _hit, 1, Curves.easeOutCubic);
    final scale = t < _hit
        ? mix(_dropScale, _overPress, fall)
        : mix(_overPress, 1, settle);
    return Opacity(
      opacity: cue(t, 0, _hit * 0.6),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}
