import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A card arriving (brief 17: staggered entrances on the tower): it rises a little and fades
/// in, [index] steps after the first. Under reduced motion it is simply there.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  /// The gap between one card and the next.
  static const Duration step = Duration(milliseconds: 70);

  /// The longest wait, so a long list doesn't keep the last card waiting.
  static const int maxSteps = 8;

  /// When the card at [index] has fully arrived.
  static Duration settledAt(int index) =>
      step * index.clamp(0, maxSteps) + BrandMotion.cinematic;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: StaggeredEntrance.settledAt(widget.index),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _in,
    curve: Interval(
      (StaggeredEntrance.step *
                  widget.index.clamp(0, StaggeredEntrance.maxSteps))
              .inMicroseconds /
          StaggeredEntrance.settledAt(widget.index).inMicroseconds,
      1,
      curve: BrandMotion.enter,
    ),
  );

  static const double _rise = 24;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else if (_in.value == 0 && !_in.isAnimating) {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, _rise * (1 - _t.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}
